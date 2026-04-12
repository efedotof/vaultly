import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/features/home/cubit/home_cubit.dart';

class ErrorWidgets extends StatefulWidget {
  const ErrorWidgets({super.key, required this.message});
  final String message;

  @override
  State<ErrorWidgets> createState() => _ErrorWidgetsState();
}

class _ErrorWidgetsState extends State<ErrorWidgets> {
  Future<void> _refresh() async {
    await context.read<HomeCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка: ${widget.message}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
