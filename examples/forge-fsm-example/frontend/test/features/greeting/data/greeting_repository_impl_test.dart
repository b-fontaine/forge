import 'package:flutter_test/flutter_test.dart';
import 'package:forge_fsm_example_frontend/features/greeting/data/repository/greeting_repository_impl.dart';

void main() {
  group('GreetingRepositoryImpl', () {
    final repo = GreetingRepositoryImpl();

    test('greet("Alice") returns "Hello, Alice!"', () async {
      final message = await repo.greet('Alice');
      expect(message, 'Hello, Alice!');
    });

    test('greet("") falls back to "Hello, world!"', () async {
      final message = await repo.greet('');
      expect(message, 'Hello, world!');
    });
  });
}
