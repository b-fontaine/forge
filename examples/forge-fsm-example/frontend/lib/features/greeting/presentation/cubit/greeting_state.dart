// State sealed-class for GreetingCubit.

sealed class GreetingState {
  const GreetingState();
}

class GreetingInitial extends GreetingState {
  const GreetingInitial();
}

class GreetingLoading extends GreetingState {
  const GreetingLoading();
}

class GreetingSuccess extends GreetingState {
  final String message;
  const GreetingSuccess(this.message);

  @override
  bool operator ==(Object other) =>
      other is GreetingSuccess && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
