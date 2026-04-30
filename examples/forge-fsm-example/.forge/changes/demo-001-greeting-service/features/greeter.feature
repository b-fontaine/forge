Feature: Greeter service
  As a backend gRPC client
  I want to call the Greet RPC
  So that I receive a polite hello message

  Background:
    Given the Greeter service is running on an in-process tonic server

  Scenario: Greeter responds with hello message
    When I call Greet with name "world"
    Then I receive a response with message "Hello, world!"

  Scenario: Greeter handles empty name with the default audience
    When I call Greet with name ""
    Then I receive a response with message "Hello, world!"

  Scenario: Greeter handles a personalized name
    When I call Greet with name "Alice"
    Then I receive a response with message "Hello, Alice!"
