import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/providers.dart';
import 'package:intl/intl.dart';

/// Local data helpers (UI-side) just for displaying the week range.
/// We keep these here so we don't depend on the DB's private helpers.
DateTime _atMidnight(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

DateTime _startOfWeek(DateTime dt) {
  final day = _atMidnight(dt);
  final mondayDelta = day.weekday - DateTime.monday;
  return day.subtract(Duration(days: mondayDelta));
}

DateTime _endOfWeekExclusive(DateTime dt) =>
    _startOfWeek(dt).add(const Duration(days: 7));

String _formatWeekRange(DateTime start, DateTime endExclusive) {
  final end = endExclusive.subtract(const Duration(days: 1));
  final formatter = DateFormat.MMMd(); // e.g. "Sep 1"
  return "${formatter.format(start)} – ${formatter.format(end)}";
}

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    // Ask for both counts at once
    final future = Future.wait<int>([
      db.getMealsCountThisWeek(),
      db.getWorkoutsCountThisWeek(),
    ]);

    final now = DateTime.now();
    final weekStart = _startOfWeek(now);
    final weekEndEx = _endOfWeekExclusive(now);

    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: FutureBuilder<List<int>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data ?? const [0, 0];
          final mealsCount = data[0];
          final workoutsCount = data[0];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "This week (${_formatWeekRange(weekStart, weekEndEx)})",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                // Simple cards - east to read at a glance
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.restaurant),
                    title: const Text('Meals logged'),
                    trailing: Text(
                      '$mealsCount',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: const Text('Workouts logged'),
                    trailing: Text(
                      '$workoutsCount',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),

                const Spacer(),

                // Optional: small hints for empty weeks
                if (mealsCount == 0 && workoutsCount == 0)
                  const Text(
                    'Tip: add a meal or a workout from the tabs below to see your weekly totals here.',
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
