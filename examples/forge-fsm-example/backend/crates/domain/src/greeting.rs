//! Greeting — pure domain entity for demo-001-greeting-service.
//!
//! Builds a polite greeting message for a given audience. Empty
//! `name` falls back to "world". Pure, no external dependencies.

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Greeting {
    message: String,
}

impl Greeting {
    /// Build a [`Greeting`] for the given audience. Empty `name`
    /// falls back to `"world"`.
    pub fn for_name(name: &str) -> Greeting {
        let audience = if name.is_empty() { "world" } else { name };
        Greeting {
            message: format!("Hello, {}!", audience),
        }
    }

    /// Borrow the rendered message as a string slice.
    pub fn message(&self) -> &str {
        &self.message
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn for_name_with_named_audience_renders_personalized_message() {
        let g = Greeting::for_name("Alice");
        assert_eq!(g.message(), "Hello, Alice!");
    }

    #[test]
    fn for_name_with_empty_audience_falls_back_to_world() {
        let g = Greeting::for_name("");
        assert_eq!(g.message(), "Hello, world!");
    }

    #[test]
    fn for_name_with_world_audience_renders_hello_world() {
        let g = Greeting::for_name("world");
        assert_eq!(g.message(), "Hello, world!");
    }
}
