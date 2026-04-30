import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repository/greeting_repository.dart';
import 'greeting_state.dart';

class GreetingCubit extends Cubit<GreetingState> {
  final GreetingRepository _repository;

  GreetingCubit(this._repository) : super(const GreetingInitial());

  Future<void> sayHello(String name) async {
    emit(const GreetingLoading());
    final message = await _repository.greet(name);
    emit(GreetingSuccess(message));
  }
}
