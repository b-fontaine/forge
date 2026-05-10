//! GreetUseCase — orchestrates the [`Greeting`] domain entity
//! for demo-001-greeting-service / demo-005-connect-greeting.
//!
//! <!-- Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation -->
//!
//! Per FR-T5-OTA-009 / FR-T5-OTA-030 / FR-T5-OTA-031 :
//!
//! - The use case carries a `#[tracing::instrument]` macro creating a span
//!   named `greeter.greet` with `otel.kind = "internal"` and `rpc.*`
//!   attributes following `rust/opentelemetry.md` § Standard Field Names.
//! - Parent linkage (the connectrpc handler's server span via the
//!   `tower-http::TraceLayer` `make_span_with` closure) happens automatically
//!   via the `tracing` span scope — `tracing-opentelemetry` wires parent /
//!   child links from the surrounding `tracing::Span`.
//! - No PII : `name` is recorded only as the formatted greeting, not as a
//!   span attribute. `skip(self)` keeps the receiver out of the span fields.

use domain::Greeting;

/// Use case for the Greeter service. Owns no state ; the
/// orchestration is a one-liner today, but the indirection
/// is the right hexagonal shape : adapters (gRPC, future CLI,
/// future HTTP REST) MUST go through this use case rather than
/// constructing [`Greeting`] directly.
pub struct GreetUseCase;

impl GreetUseCase {
    pub fn new() -> Self {
        GreetUseCase
    }

    #[tracing::instrument(
        name = "greeter.greet",
        skip(self, name),
        fields(
            otel.kind = "internal",
            rpc.system = "connect",
            rpc.service = "greeting.v1.GreeterService",
            rpc.method = "Greet",
        )
    )]
    pub fn execute(&self, name: String) -> Greeting {
        Greeting::for_name(&name)
    }
}

impl Default for GreetUseCase {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn execute_with_name_returns_personalized_greeting() {
        let uc = GreetUseCase::new();
        let g = uc.execute("Alice".to_string());
        assert_eq!(g.message(), "Hello, Alice!");
    }

    #[test]
    fn execute_with_empty_name_returns_default_audience() {
        let uc = GreetUseCase::new();
        let g = uc.execute(String::new());
        assert_eq!(g.message(), "Hello, world!");
    }
}
