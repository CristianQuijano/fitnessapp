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
