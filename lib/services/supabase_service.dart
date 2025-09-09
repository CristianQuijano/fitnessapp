import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SupabaseService {
  // --- Meals ---
  Future<void> insertMeal(String name, int? calories) async {
    await supabase.from('meals').insert({'name': name, 'calories': calories});
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
}
