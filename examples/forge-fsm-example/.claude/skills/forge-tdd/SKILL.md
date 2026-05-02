---
name: forge-tdd
description: TDD enforcement skill for Forge framework - applies RED-GREEN-REFACTOR cycle and anti-rationalization to all code
globs: ["**/*.dart", "**/*.rs", "**/*.ts", "**/*.py", "**/*.go"]
alwaysApply: true
---

# Forge TDD Skill

<EXTREMELY_IMPORTANT>
## The 1% Rule
If there is even a 1% chance this skill applies to your current task, you MUST apply it.
If you are writing ANY code that will run in production, this skill applies.
There are NO exceptions. There are NO edge cases where TDD does not apply.
</EXTREMELY_IMPORTANT>

## The Immutable TDD Cycle

```
RED   → Write a failing test that describes the behavior
↓       Run it. Confirm it FAILS. If it doesn't fail, the test is wrong.
GREEN → Write the MINIMAL code to make the test pass
↓       Run it. Confirm it PASSES. If it doesn't pass, fix the code.
REFACTOR → Improve design without changing behavior
↓          Run it. Confirm it STILL PASSES.
REPEAT → Move to next behavior
```

**RED must be verified.** Writing a test and immediately writing code = testing after. Not TDD.
**GREEN means minimal.** Do not write more code than needed. That's the refactor step's job.
**REFACTOR means structure.** Rename, extract, simplify. Not add features.

## Anti-Rationalization Table (Memorize This)

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. The test takes 30 seconds. Write it. |
| "I'll test after" | Tests written after pass immediately and prove nothing. Refused. |
| "The framework handles it" | The framework has bugs. Your integration has bugs. Test your code. |
| "It's just a refactor" | Refactors that break things aren't refactors. Tests catch this. |
| "Mocking is too complex" | Complex mocking = bad design. Simplify the dependency graph. |
| "It's a prototype" | Prototypes become production. Start right. |
| "TDD is too slow" | Debugging is slower. Manual testing is slower. TDD is fastest. |
| "I'll keep the test as reference" | You'll adapt it. That's testing after. Delete the code. Write test first. |
| "The deadline is tight" | Bugs blow deadlines. TDD prevents bugs. TDD saves time. |
| "It's a one-liner" | One-liners have edge cases. Test the edge cases. |
| "The compiler catches it" | Compilers check types, not business logic. Test the logic. |
| "TDD is dogmatic" | TDD IS pragmatic. "Pragmatic shortcuts" = debug in production = slower. |

## Flutter TDD Protocol

```dart
// 1. RED — Write failing test first
testWidgets('UserCard displays user name', (tester) async {
  // Arrange
  final user = User(id: '1', name: 'Alice', email: 'alice@example.com');
  
  // Act
  await tester.pumpWidget(MaterialApp(home: UserCard(user: user)));
  
  // Assert
  expect(find.text('Alice'), findsOneWidget);
  expect(find.text('alice@example.com'), findsOneWidget);
});

// Run: flutter test → MUST SEE RED (compilation error or test failure)

// 2. GREEN — Write minimal widget
class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user});
  final User user;
  
  @override
  Widget build(BuildContext context) => Column(
    children: [Text(user.name), Text(user.email)],
  );
}

// Run: flutter test → MUST SEE GREEN

// 3. REFACTOR — Improve structure, run tests again
```

BLoC Testing:
```dart
blocTest<UserBloc, UserState>(
  'emits [loading, loaded] when LoadUser is added',
  build: () {
    when(() => mockRepo.getUser('1')).thenAnswer((_) async => user);
    return UserBloc(repository: mockRepo);
  },
  act: (bloc) => bloc.add(const LoadUser(id: '1')),
  expect: () => [UserLoading(), UserLoaded(user: user)],
);
```

## Rust TDD Protocol

```rust
// 1. RED — Write failing test first
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn calculate_discount_applies_10_percent_for_premium_users() {
        let user = User::premium("user-1");
        let price = Money::new(100, Currency::USD);
        
        let discounted = calculate_discount(&user, price);
        
        assert_eq!(discounted, Money::new(90, Currency::USD));
    }
}

// Run: cargo test → MUST SEE RED

// 2. GREEN — Write minimal implementation
pub fn calculate_discount(user: &User, price: Money) -> Money {
    if user.is_premium() {
        price.multiply(0.9)
    } else {
        price
    }
}

// Run: cargo test → MUST SEE GREEN
// 3. REFACTOR as needed
```

## Coverage Requirements
- Minimum: 80% overall
- Domain layer: 100% (no exceptions)
- Measure with: `flutter test --coverage` + `genhtml` or `cargo tarpaulin`

## Superpowers Compatibility
If Superpowers is installed, TDD-related tasks delegate to Superpowers TDD skill.
Forge TDD skill takes precedence for constitution compliance checking.
