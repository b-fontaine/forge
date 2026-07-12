# Rust gRPC Standard (tonic)

## Technology Stack

| Crate | Role |
|---|---|
| `tonic` | gRPC server and client |
| `prost` | Protobuf code generation |
| `tonic-build` | Build script integration |
| `tonic-health` | gRPC health check protocol |
| `tonic-reflection` | gRPC server reflection |

---

## Proto Organization

```
proto/
├── api/
│   └── v1/
│       ├── auth.proto
│       ├── users.proto
│       └── orders.proto
└── common/
    ├── pagination.proto
    └── errors.proto
```

```protobuf
// proto/api/v1/auth.proto
syntax = "proto3";
package api.v1;

import "google/api/annotations.proto";  // for REST transcoding via Kong
import "common/errors.proto";

option go_package = "github.com/yourorg/proto/api/v1;apiv1";
option java_package = "com.yourorg.api.v1";

service AuthService {
  rpc SignIn(SignInRequest) returns (SignInResponse) {
    option (google.api.http) = {
      post: "/v1/auth/sign-in"
      body: "*"
    };
  }

  rpc SignOut(SignOutRequest) returns (SignOutResponse) {
    option (google.api.http) = {
      post: "/v1/auth/sign-out"
      body: "*"
    };
  }

  rpc RefreshToken(RefreshTokenRequest) returns (RefreshTokenResponse) {
    option (google.api.http) = {
      post: "/v1/auth/refresh"
      body: "*"
    };
  }
}

message SignInRequest {
  string email = 1;
  string password = 2;
}

message SignInResponse {
  string access_token = 1;
  string refresh_token = 2;
  int64 expires_in = 3;
  User user = 4;
}
```

---

## Build Script

```rust
// build.rs
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let proto_files = &[
        "proto/api/v1/auth.proto",
        "proto/api/v1/users.proto",
        "proto/api/v1/orders.proto",
    ];

    let include_dirs = &["proto", "third_party/googleapis"];

    tonic_build::configure()
        .build_server(true)
        .build_client(true)
        .out_dir("src/generated")
        .compile(proto_files, include_dirs)?;

    // Re-run build if any proto changes
    for file in proto_files {
        println!("cargo:rerun-if-changed={file}");
    }
    println!("cargo:rerun-if-changed=proto/common/");

    Ok(())
}
```

---

## Service Implementation

```rust
// src/adapters/inbound/grpc/auth_handler.rs
use crate::domain::errors::DomainError;
use crate::domain::ports::inbound::SignInPort;
use crate::generated::api::v1::{
    auth_service_server::AuthService,
    SignInRequest, SignInResponse,
    SignOutRequest, SignOutResponse,
};
use std::sync::Arc;
use tonic::{Request, Response, Status};
use tracing::instrument;

pub struct AuthGrpcHandler {
    sign_in_port: Arc<dyn SignInPort>,
    token_service: Arc<dyn TokenService>,
}

impl AuthGrpcHandler {
    pub fn new(
        sign_in_port: Arc<dyn SignInPort>,
        token_service: Arc<dyn TokenService>,
    ) -> Self {
        Self { sign_in_port, token_service }
    }
}

#[tonic::async_trait]
impl AuthService for AuthGrpcHandler {
    #[instrument(skip(self, request), fields(email = %request.get_ref().email))]
    async fn sign_in(
        &self,
        request: Request<SignInRequest>,
    ) -> Result<Response<SignInResponse>, Status> {
        let req = request.into_inner();

        // Validate at boundary before calling domain
        validate_sign_in_request(&req)?;

        let user = self
            .sign_in_port
            .sign_in(&req.email, &req.password)
            .await
            .map_err(|err| {
                tracing::error!(error = %err, "Sign-in failed");
                map_domain_error(err)
            })?;

        let (access_token, refresh_token) = self
            .token_service
            .generate(&user)
            .await
            .map_err(|err| {
                tracing::error!(error = %err, "Token generation failed");
                Status::internal("Failed to generate token")
            })?;

        Ok(Response::new(SignInResponse {
            access_token,
            refresh_token,
            expires_in: 3600,
            user: Some(user.into()),
        }))
    }

    async fn sign_out(
        &self,
        request: Request<SignOutRequest>,
    ) -> Result<Response<SignOutResponse>, Status> {
        // Extract user from metadata (injected by auth interceptor)
        let user_id = extract_user_id(&request)?;

        self.token_service
            .revoke(user_id)
            .await
            .map_err(|_| Status::internal("Failed to revoke token"))?;

        Ok(Response::new(SignOutResponse { success: true }))
    }
}

fn validate_sign_in_request(req: &SignInRequest) -> Result<(), Status> {
    if req.email.is_empty() {
        return Err(Status::invalid_argument("email is required"));
    }
    if req.password.is_empty() {
        return Err(Status::invalid_argument("password is required"));
    }
    if req.password.len() < 8 {
        return Err(Status::invalid_argument("password must be at least 8 characters"));
    }
    Ok(())
}

fn map_domain_error(err: anyhow::Error) -> Status {
    if let Some(domain_err) = err.downcast_ref::<DomainError>() {
        return match domain_err {
            DomainError::UserNotFound | DomainError::InvalidCredentials => {
                Status::unauthenticated("Invalid credentials")
            }
            DomainError::InvalidEmail { .. } => {
                Status::invalid_argument(domain_err.to_string())
            }
            DomainError::InsufficientPermissions { .. } => {
                Status::permission_denied(domain_err.to_string())
            }
            _ => Status::internal("Internal server error"),
        };
    }
    Status::internal("Internal server error")
}
```

---

## Server Setup with Health Check

```rust
// src/infrastructure/server/grpc_server.rs
use tonic::transport::Server;
use tonic_health::server::HealthReporter;
use tonic_reflection::server::Builder as ReflectionBuilder;
use crate::generated::api::v1::{
    auth_service_server::AuthServiceServer,
    FILE_DESCRIPTOR_SET,
};

pub async fn run(config: &AppConfig, token: CancellationToken) -> anyhow::Result<()> {
    let (mut health_reporter, health_service) = tonic_health::server::health_reporter();

    // Register services as healthy
    health_reporter.set_serving::<AuthServiceServer<AuthGrpcHandler>>().await;

    let reflection_service = ReflectionBuilder::configure()
        .register_encoded_file_descriptor_set(FILE_DESCRIPTOR_SET)
        .build()?;

    let auth_handler = build_auth_handler(&config).await?;

    let server = Server::builder()
        .layer(AuthInterceptorLayer::new(config.jwt_secret.clone()))
        .layer(TracingLayer::new())
        .add_service(health_service)
        .add_service(reflection_service)
        .add_service(AuthServiceServer::new(auth_handler));

    tracing::info!(address = %config.grpc_address, "Starting gRPC server");

    server
        .serve_with_shutdown(config.grpc_address.parse()?, token.cancelled())
        .await
        .context("gRPC server failed")?;

    Ok(())
}
```

---

## Streaming Patterns

```rust
// Server-side streaming
async fn watch_order_status(
    &self,
    request: Request<WatchOrderRequest>,
) -> Result<Response<Self::WatchOrderStatusStream>, Status> {
    let order_id = request.into_inner().order_id;
    let mut rx = self.order_events.subscribe();

    let stream = async_stream::try_stream! {
        loop {
            match rx.recv().await {
                Ok(event) if event.order_id == order_id => {
                    yield OrderStatusUpdate {
                        status: event.status.into(),
                        updated_at: event.timestamp.to_rfc3339(),
                    };

                    if event.is_terminal() {
                        break;
                    }
                }
                Ok(_) => continue,
                Err(broadcast::error::RecvError::Closed) => break,
                Err(broadcast::error::RecvError::Lagged(n)) => {
                    tracing::warn!(n, "Event stream lagged");
                }
            }
        }
    };

    Ok(Response::new(Box::pin(stream)))
}

// Bidirectional streaming
async fn chat(
    &self,
    request: Request<Streaming<ChatMessage>>,
) -> Result<Response<Self::ChatStream>, Status> {
    let mut in_stream = request.into_inner();
    let (tx, rx) = mpsc::channel(32);

    tokio::spawn(async move {
        while let Some(result) = in_stream.next().await {
            match result {
                Ok(msg) => {
                    let reply = process_message(msg).await;
                    if tx.send(Ok(reply)).await.is_err() {
                        break;
                    }
                }
                Err(e) => {
                    tracing::error!(error = %e, "Stream error");
                    break;
                }
            }
        }
    });

    Ok(Response::new(Box::pin(ReceiverStream::new(rx))))
}
```

---

## Rules

- **Proto files are versioned**: all services live under `api/v1/`, `api/v2/`; never modify an existing stable version
- **Validate all inputs at the gRPC boundary**: before calling any domain code, validate required fields and formats
- **Map domain errors to `Status` codes, not to `Status::internal` blindly**: expose meaningful gRPC status codes
- **Health check is mandatory**: every service registers with `tonic-health` and sets status to `SERVING` / `NOT_SERVING`
- **Server reflection is enabled in non-production**: allows `grpcurl` and `grpc-gateway` introspection
- **Streaming handlers check for cancellation**: monitor `cx.is_cancelled()` or use `select!` with `token.cancelled()`
- **Proto HTTP annotations are always added**: enables Kong gRPC→REST transcoding without code changes
- **Never expose internal errors in `Status` messages**: log internally, return generic message externally
- **Request/response DTOs never leak into the domain layer**: always convert proto types → domain types at handler boundary
