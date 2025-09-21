import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../services/supabase_providers.dart';

class MealsListScreen extends ConsumerWidget {
  const MealsListScreen({super.key});

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat.yMMMd().add_jm().format(dt);
    } catch (e) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(mealsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Meals")),
      body: mealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (meals) {
          if (meals.isEmpty) {
            return const Center(child: Text("No meals yet, Add one!"));
          }
          return ListView.builder(
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
              final id = meal['id'] as String;
              final name = (meal['name'] ?? '') as String;
              final calories = (meal['calories'] as num?)?.toInt();
              final createdAt = _formatDate(meal['created_at'] as String?);

              return Dismissible(
                key: Key(id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  // Optimistically remove the item from UI
                  final removedMeal = meal;
                  ref.read(mealsProvider.notifier).removeAtIndex(index);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$name deleted"),
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () async {
                          await ref
                              .read(supabaseServiceProvider)
                              .insertMeal(
                                removedMeal['name'] as String,
                                removedMeal['calories'] as int?,
                              );
                          // ignore: unused_result
                          ref.refresh(mealsProvider);
                        },
                      ),
                    ),
                  );
                  // Perform delete in Supabase
                  ref.read(supabaseServiceProvider).deleteMeal(id);

                  // Refresh provider to sync with Supabaase
                  // ignore: unused_result
                  ref.refresh(workoutsProvider);
                },
                child: ListTile(
                  title: Text(name),
                  subtitle: Text("${calories ?? 0} kcal • $createdAt"),
                ),
              );
            },
          );
        },
      ),
      // FAB (Floating Action Button)
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nameController = TextEditingController();
          final caloriesController = TextEditingController();

          final result = await showDialog<Map<String, String>>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Add meal"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: "Enter meal name:",
                      ),
                    ),
                    TextField(
                      controller: caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: "Enter calories",
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        "name": nameController.text,
                        "calories": caloriesController.text,
                      });
                    },
                    child: const Text("Add"),
                  ),
                ],
              );
            },
          );

          if (result != null && result["name"]!.trim().isNotEmpty) {
            final name = result["name"]!.trim();
            final calories = int.tryParse(result["calories"] ?? "");
            await ref.read(supabaseServiceProvider).insertMeal(name, calories);
            // ignore: unused_result
            ref.refresh(mealsProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
