Feature: Rate-limited Greeter
  As an operator
  I want the Greeter service to be rate-limited at the gateway
  So that misbehaving clients cannot overwhelm the backend

  Scenario: Within-threshold calls succeed
    Given the Greeter service is fronted by Kong with a 10/minute rate limit
    When I call Greet 5 times in 1 minute as consumer "alice"
    Then all 5 calls receive a successful response

  Scenario: Above-threshold calls receive 429
    Given the Greeter service is fronted by Kong with a 10/minute rate limit
    When I call Greet 12 times in 1 minute as consumer "alice"
    Then 10 calls receive a successful response
    And the remaining 2 calls receive a 429 ResourceExhausted

  Scenario: Backend tracing event records the rate-limit hit
    Given the Greeter handler is observing the upstream stream
    When a 429 ResourceExhausted is observed for consumer "alice"
    Then a tracing event "greeter.rate_limit" is emitted
    And the event's consumer attribute equals "alice"
