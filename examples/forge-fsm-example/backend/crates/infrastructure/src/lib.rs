//! Infrastructure adapters — outbound ports + cross-cutting wiring.
//!
//! Per Article VII.1, this crate hosts the *adapter* implementations of the
//! port traits declared in `crates/application/`. The `telemetry` module is a
//! cross-cutting infrastructure concern (OTel SDK init, propagation carriers,
//! Tower middleware glue) consumed by `bin-server` at startup.

pub mod telemetry;

pub fn add(left: u64, right: u64) -> u64 {
    left + right
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let result = add(2, 2);
        assert_eq!(result, 4);
    }
}
