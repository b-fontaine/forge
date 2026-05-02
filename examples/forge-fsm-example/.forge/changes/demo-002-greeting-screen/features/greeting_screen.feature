Feature: Greeting screen
  As a Flutter app user
  I want to enter a name and tap a button
  So that I see a polite greeting

  Scenario: User enters a name and gets a personalized greeting
    Given the GreetingScreen is displayed
    When I enter "Alice" in the audience field
    And I tap "Say hello"
    Then I see "Hello, Alice!" in the greeting region

  Scenario: User submits without a name and sees the default greeting
    Given the GreetingScreen is displayed
    When I leave the audience field empty
    And I tap "Say hello"
    Then I see "Hello, world!" in the greeting region

  Scenario: Tapping the button shows a brief loading state
    Given the GreetingScreen is displayed
    When I enter "Bob" in the audience field
    And I tap "Say hello"
    Then I briefly see a loading indicator
    And then I see "Hello, Bob!" in the greeting region
