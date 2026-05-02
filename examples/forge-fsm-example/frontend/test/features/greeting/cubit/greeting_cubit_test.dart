import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_fsm_example_frontend/features/greeting/data/repository/greeting_repository_impl.dart';
import 'package:forge_fsm_example_frontend/features/greeting/presentation/cubit/greeting_cubit.dart';
import 'package:forge_fsm_example_frontend/features/greeting/presentation/cubit/greeting_state.dart';

void main() {
  group('GreetingCubit', () {
    blocTest<GreetingCubit, GreetingState>(
      'sayHello("Alice") emits Loading then Success("Hello, Alice!")',
      build: () => GreetingCubit(GreetingRepositoryImpl()),
      act: (cubit) => cubit.sayHello('Alice'),
      expect: () => [
        isA<GreetingLoading>(),
        const GreetingSuccess('Hello, Alice!'),
      ],
    );

    blocTest<GreetingCubit, GreetingState>(
      'sayHello("") emits Loading then Success("Hello, world!")',
      build: () => GreetingCubit(GreetingRepositoryImpl()),
      act: (cubit) => cubit.sayHello(''),
      expect: () => [
        isA<GreetingLoading>(),
        const GreetingSuccess('Hello, world!'),
      ],
    );
  });
}
