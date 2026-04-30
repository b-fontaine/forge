// Domain port for the Greeter feature.
// Pure Dart — zero Flutter imports (Article VI.2).

abstract class GreetingRepository {
  Future<String> greet(String name);
}
