import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';

// A single shared instance of SupabaseService
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

// Meals Provider
class MealsNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  MealsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadMeals();
  }

  final Ref ref;

  Future<void> _loadMeals() async {
    final service = ref.read(supabaseServiceProvider);
    try {
      final data = await service.getAllMeals();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMeal(String id) async {
    // optimistically update state
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((w) => w['id'] != id).toList());

    final service = ref.read(supabaseServiceProvider);
    await service.deleteMeal(id);
    await _loadMeals();
  }

  Future<void> addWorkout(String name, int? calories) async {
    final service = ref.read(supabaseServiceProvider);
    await service.insertMeal(name, calories);
    await _loadMeals();
  }
}

final mealsProvider =
    StateNotifierProvider<
      MealsNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) => MealsNotifier(ref));

// Workouts Provider
class WorkoutsNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  WorkoutsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadWorkouts();
  }

  final Ref ref;

  Future<void> _loadWorkouts() async {
    final service = ref.read(supabaseServiceProvider);
    try {
      final data = await service.getAllWorkouts();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteWorkout(String id) async {
    // Optimistically update state
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((w) => w['id'] != id).toList());

    final service = ref.read(supabaseServiceProvider);
    await service.deleteWorkout(id);
    await _loadWorkouts();
  }

  Future<void> addWorkout(String name) async {
    final service = ref.read(supabaseServiceProvider);
    await service.insertWorkout(name);
    await _loadWorkouts();
  }
}

final workoutsProvider =
    StateNotifierProvider<
      WorkoutsNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) => WorkoutsNotifier(ref));

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
