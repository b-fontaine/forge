import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_fsm_example_frontend/features/greeting/data/repository/greeting_repository_impl.dart';
import 'package:forge_fsm_example_frontend/features/greeting/presentation/cubit/greeting_cubit.dart';
import 'package:forge_fsm_example_frontend/features/greeting/presentation/screen/greeting_screen.dart';

Widget _wrap() {
  return MaterialApp(
    home: BlocProvider(
      create: (_) => GreetingCubit(GreetingRepositoryImpl()),
      child: const GreetingScreen(),
    ),
  );
}

void main() {
  group('GreetingScreen', () {
    testWidgets(
      'renders the audience field and submit button on initial state',
      (tester) async {
        await tester.pumpWidget(_wrap());
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Say hello'), findsOneWidget);
        expect(find.byKey(const Key('greeting-message')), findsNothing);
      },
    );

    testWidgets('tapping Say hello with a name displays the greeting', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.tap(find.text('Say hello'));
      await tester.pumpAndSettle();
      expect(find.text('Hello, Alice!'), findsOneWidget);
    });

    testWidgets('tapping Say hello with empty name falls back to world', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.text('Say hello'));
      await tester.pumpAndSettle();
      expect(find.text('Hello, world!'), findsOneWidget);
    });
  });
}
