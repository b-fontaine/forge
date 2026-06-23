# Docker Standard

## Principles

- Multi-stage builds: separate build environment from runtime image
- Minimal final images: distroless or alpine runtimes
- Non-root users: never run processes as root
- Pinned versions: no `latest` tags in production
- Health checks: every service container has a `HEALTHCHECK`

---

## Multi-Stage Rust Dockerfile

```dockerfile
# syntax=docker/dockerfile:1

# ============================================================
# Stage 1: Dependency cache
# Cache Cargo registry and build dependencies separately
# so that changes to src/ don't invalidate this layer.
# ============================================================
FROM rust:1.82-slim AS deps

WORKDIR /app

# Install system build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy manifests only — cache this layer
COPY Cargo.toml Cargo.lock ./
COPY crates/domain/Cargo.toml crates/domain/
COPY crates/application/Cargo.toml crates/application/
COPY crates/adapter-grpc/Cargo.toml crates/adapter-grpc/
COPY crates/infrastructure/Cargo.toml crates/infrastructure/

# Build only dependencies (trick: create empty lib.rs)
RUN mkdir -p crates/domain/src crates/application/src crates/adapter-grpc/src crates/infrastructure/src && \
    for crate in domain application adapter-grpc infrastructure; do \
        echo "// placeholder" > crates/$crate/src/lib.rs; \
    done && \
    cargo build --release && \
    rm -rf crates/*/src

# ============================================================
# Stage 2: Builder
# ============================================================
FROM deps AS builder

# Copy actual source code
COPY crates/ crates/
COPY proto/ proto/
COPY build.rs .

# Touch to force rebuild of changed crates
RUN touch crates/*/src/*.rs

RUN cargo build --release --bin server

# ============================================================
# Stage 3: Runtime (distroless)
# ============================================================
FROM gcr.io/distroless/cc-debian12:nonroot AS runtime

# Copy binary from builder
COPY --from=builder /app/target/release/server /server

# Copy TLS certificates if needed
# COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

EXPOSE 50051

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD ["/server", "healthcheck"]

USER nonroot:nonroot

ENTRYPOINT ["/server"]
```

---

## Multi-Stage Flutter Web Dockerfile

```dockerfile
# syntax=docker/dockerfile:1

FROM dart:3.5-sdk AS flutter-builder

WORKDIR /app

RUN dart pub global activate flutter_installer && flutter --version

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --dart-define-from-file=.env.prod

# ────────────────────────────────────────────────────────────

FROM nginx:1.27-alpine AS runtime

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

COPY infra/nginx.conf /etc/nginx/conf.d/app.conf
COPY --from=flutter-builder /app/build/web /usr/share/nginx/html

RUN addgroup -S appgroup && adduser -S appuser -G appgroup && \
    chown -R appuser:appgroup /usr/share/nginx/html /var/cache/nginx /var/log/nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost:8080/healthz || exit 1

USER appuser

CMD ["nginx", "-g", "daemon off;"]
```

---

## .dockerignore

Every repository must have a `.dockerignore` that excludes build artifacts, secrets, and tooling:

```
# Version control
.git
.gitignore

# Rust build artifacts
target/

# Flutter build artifacts
build/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies

# Environment files (never in image)
.env
.env.*
*.env
secrets/
credentials/

# Development tooling
.vscode/
.idea/
*.swp
*.swo

# Documentation
docs/
*.md
!README.md

# CI/CD
.github/
.gitlab-ci.yml

# Test files (optional — depends on if tests run in container)
tests/
test/
```

---

## Docker Compose for Development

```yaml
# docker-compose.yml
services:
  server:
    build:
      context: .
      target: builder  # use builder stage in dev for faster iteration
      cache_from:
        - type=local,src=/tmp/docker-cache
    environment:
      - DATABASE_URL=postgres://postgres:postgres@db:5432/app
      - OTLP_ENDPOINT=http://otel-collector:4317
      - RUST_LOG=info,server=debug
    ports:
      - "50051:50051"
    depends_on:
      db:
        condition: service_healthy
      otel-collector:
        condition: service_started
    volumes:
      - ./src:/app/src:ro  # mount source for rebuild watching
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: app
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./migrations:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.111.0
    command: ["--config=/etc/otel-collector-config.yaml"]
    volumes:
      - ./infra/otel-collector-config.yaml:/etc/otel-collector-config.yaml:ro
    ports:
      - "4317:4317"   # OTLP gRPC
      - "4318:4318"   # OTLP HTTP
      - "55679:55679" # zPages

  signoz:
    image: signoz/signoz:latest
    ports:
      - "3301:3301"
    depends_on:
      - otel-collector

volumes:
  postgres_data:
```

---

## Image Version Pinning Policy

```dockerfile
# Bad — tags can change, builds are not reproducible
FROM rust:latest
FROM postgres:latest
FROM nginx:alpine

# Good — pinned to a specific digest or version
FROM rust:1.82.0-slim-bookworm@sha256:abc123...
FROM postgres:16.3-alpine3.20
FROM nginx:1.27.2-alpine3.20

# Acceptable for non-critical dev tools
FROM rust:1.82-slim
```

In CI, use digest pinning for all base images. Update monthly with Dependabot.

---

## Rules

- **`.dockerignore` is mandatory**: every Dockerfile must have a corresponding `.dockerignore`
- **Pin all base image versions**: no `latest` in `Dockerfile`; use digests or explicit version tags in production
- **Non-root user in final stage**: use `USER nonroot:nonroot` (distroless) or create a dedicated user
- **`HEALTHCHECK` is mandatory**: every service container defines a health check
- **Multi-stage build separates build and runtime**: no compiler or build tools in the final image
- **Distroless for production Rust binaries**: use `gcr.io/distroless/cc-debian12:nonroot`
- **Docker Compose for local development**: no manual `docker run` commands; all services defined in `docker-compose.yml`
- **Never `COPY . .` as first layer**: always copy lock files and manifests first to maximize cache hits
- **No secrets in Dockerfile or image layers**: use `--secret` mount during build or inject at runtime via env
- **`EXPOSE` documents the port but does not publish it**: use `ports:` in Compose for local, Kubernetes for production
