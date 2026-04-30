import '../../domain/repository/greeting_repository.dart';

// Fake adapter for demo-002-greeting-screen. Mirrors demo-001's
// contract : empty name falls back to "world".
//
// TODO(c1-followup): swap this for a real grpc-dart client once
// `task proto` is wired into the build pipeline. The fake is
// sufficient for the demo's didactic purpose (Article VI.2 port +
// adapter pattern).
class GreetingRepositoryImpl implements GreetingRepository {
  @override
  Future<String> greet(String name) async {
    final audience = name.isEmpty ? 'world' : name;
    return 'Hello, $audience!';
  }
}
