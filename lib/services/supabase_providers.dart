import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';

// A single shared instance of SupabaseService
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

// Meals Provider
final mealsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getAllMeals();
});

// Workouts Provider
final workoutsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final service = ref.watch(supabaseServiceProvider);
    return service.getAllWorkouts();
  },
);

final summaryProvider = FutureProvider.autoDispose<Map<String, int>>((
  ref,
) async {
  final service = ref.watch(supabaseServiceProvider);

  final now = DateTime.now();
  final start = now.subtract(Duration(days: now.weekday - 1)); // Monday
  final end = start.add(const Duration(days: 7));

  final mealsCount = await service.countMealsBetween(start, end);
  final workoutsCount = await service.countWorkoutsBetween(start, end);

  return {"meals": mealsCount, "workouts": workoutsCount};
});
