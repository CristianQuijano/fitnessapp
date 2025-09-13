import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

final supabase = Supabase.instance.client;

class SupabaseService {
  // --- Meals ---
  Future<void> insertMeal(String name, int? calories) async {
    final response = await supabase.from('meals').insert({
      'name': name,
      'calories': calories,
    }).select();

    if (response.isEmpty) {
      debugPrint("Insert meal failed: $response");
    } else {
      debugPrint("Meal inserted: $response");
    }
  }

  Future<List<Map<String, dynamic>>> getAllMeals() async {
    return await supabase.from('meals').select();
  }

  Future<void> deleteMeal(String id) async {
    await supabase.from('meals').delete().eq('id', id);
  }

  // --- Workouts ---
  Future<void> insertWorkout(String name) async {
    await supabase.from('workouts').insert({'name': name});
  }

  Future<List<Map<String, dynamic>>> getAllWorkouts() async {
    return await supabase.from('workouts').select();
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
}
