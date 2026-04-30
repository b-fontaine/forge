//! Application crate — orchestration layer between adapters
//! (`grpc-api`, future REST/CLI) and the pure domain (`domain`).
//! Per Article VII.1, depends only on the domain crate.

pub mod greet;

pub use greet::GreetUseCase;
