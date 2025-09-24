import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SupabaseService {
  // --- Meals ---
  Future<void> insertMeal(String name, int? calories) async {
    await supabase.from('meals').insert({'name': name, 'calories': calories});
  }

  Future<List<Map<String, dynamic>>> getAllMeals() async {
    return await supabase
        .from('meals')
        .select()
        .order('created_at', ascending: false);
  }

  Future<void> deleteMeal(String id) async {
    await supabase.from('meals').delete().eq('id', id);
  }

  // --- Workouts ---
  Future<void> insertWorkout(String name) async {
    await supabase.from('workouts').insert({'name': name});
  }

  Future<List<Map<String, dynamic>>> getAllWorkouts() async {
    return await supabase
        .from('workouts')
        .select()
        .order('created_at', ascending: false);
  }

  Future<void> deleteWorkout(String id) async {
    await supabase.from('workouts').delete().eq('id', id);
  }

  Future<int> countMealsBetween(DateTime start, DateTime end) async {
    final response = await supabase
        .from('meals')
        .select()
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String());

    return response.length;
  }

  Future<int> countWorkoutsBetween(DateTime start, DateTime end) async {
    final response = await supabase
        .from('workouts')
        .select()
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String());

    return response.length;
  }

  Future<int> sumCaloriesBetween(DateTime start, DateTime end) async {
    final response = await supabase
        .from('meals')
        .select('calories')
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String());

    //Sum safely
    final total = response.fold<int>(
      0,
      (sum, row) => sum + ((row['calories'] ?? 0) as int),
    );
    return total;
  }
}
