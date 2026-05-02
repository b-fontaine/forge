import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/greeting_cubit.dart';
import '../cubit/greeting_state.dart';

class GreetingScreen extends StatefulWidget {
  const GreetingScreen({super.key});

  @override
  State<GreetingScreen> createState() => _GreetingScreenState();
}

class _GreetingScreenState extends State<GreetingScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Greeter')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocBuilder<GreetingCubit, GreetingState>(
          builder: (context, state) {
            final isLoading = state is GreetingLoading;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  label: 'Audience name',
                  textField: true,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Audience name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Submit greeting',
                  button: true,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => context.read<GreetingCubit>().sayHello(
                            _nameController.text,
                          ),
                    child: const Text('Say hello'),
                  ),
                ),
                const SizedBox(height: 24),
                if (isLoading) const Center(child: CircularProgressIndicator()),
                if (state is GreetingSuccess)
                  Center(
                    child: Text(
                      state.message,
                      key: const Key('greeting-message'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
