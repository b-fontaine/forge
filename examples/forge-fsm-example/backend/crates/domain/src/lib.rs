//! Domain crate — pure business logic for forge-fsm-example.
//!
//! Per Article VII.1 (Hexagonal Rust), this crate has zero
//! dependencies outside the standard library. Adapters
//! (gRPC, HTTP, DB) live in the dedicated `grpc-api` and
//! `infrastructure` crates ; orchestration lives in
//! `application`.

pub mod greeting;

pub use greeting::Greeting;
