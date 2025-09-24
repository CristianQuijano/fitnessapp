import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/supabase_providers.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(summaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text("Error: $err")),
        data: (summary) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Meals this week: ${summary['meals']}"),
                const SizedBox(height: 16),
                Text("Workouts this week: ${summary['workouts']}"),
                const SizedBox(height: 16),
                Text("Calories consumed: ${summary['calories']} kcal"),
              ],
            ),
          );
        },
      ),
    );
  }
}
