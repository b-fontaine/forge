// Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation
//
// fsm-frontend bootstrap. Per ADR-T5-OTA-005 init order :
//
//   1. WidgetsFlutterBinding.ensureInitialized() — bind the framework.
//   2. AppConfig.fromEnv() — read OTEL_* + DEPLOYMENT_ENV via
//      `--dart-define`.
//   3. await setupTelemetry(config: ...) — global tracer provider up.
//   4. Bloc.observer = TracingBlocObserver() — registered BEFORE the first
//      BlocProvider builds so events are captured from the start.
//   5. FlutterError.onError + PlatformDispatcher.instance.onError → ErrorReporter.
//   6. runApp(MaterialApp(navigatorObservers: [TracingNavigationObserver()])).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/app_config.dart';
import 'core/telemetry/error_reporter.dart';
import 'core/telemetry/observers/tracing_bloc_observer.dart';
import 'core/telemetry/observers/tracing_navigation_observer.dart';
import 'core/telemetry/telemetry_setup.dart';
import 'features/greeting/data/repository/greeting_repository_impl.dart';
import 'features/greeting/presentation/cubit/greeting_cubit.dart';
import 'features/greeting/presentation/screen/greeting_screen.dart';

Future<void> main() async {
  // 1. Bind the framework before any async work.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load env-driven config.
  final config = AppConfig.fromEnv();

  // 3. Set up the OTel SDK ; sets globalTracerProvider.
  await setupTelemetry(config: config);

  // 4. BLoC observer must be set before any BlocProvider builds.
  Bloc.observer = TracingBlocObserver();

  // 5. Wire global error handlers — uses globalTracerProvider, SDK already up.
  final errorReporter = ErrorReporter();
  FlutterError.onError = (FlutterErrorDetails details) {
    errorReporter.report(details.exception, details.stack ?? StackTrace.empty);
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    errorReporter.report(error, stack);
    return true;
  };

  // 6. Mount the app.
  runApp(MyApp(config: config));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'forge-fsm-example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      navigatorObservers: [TracingNavigationObserver()],
      home: BlocProvider<GreetingCubit>(
        create: (_) => GreetingCubit(GreetingRepositoryImpl()),
        child: const GreetingScreen(),
      ),
    );
  }
}
