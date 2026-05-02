//! GreetUseCase — orchestrates the [`Greeting`] domain entity
//! for demo-001-greeting-service.

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
