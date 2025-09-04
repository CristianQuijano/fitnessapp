import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/local_db.dart';
import '../../services/providers.dart';

class MealsListScreen extends ConsumerWidget {
  const MealsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Meals")),
      body: StreamBuilder(
        stream: db.watchAllMeals(), // auto-updates on DB changes
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final meals = snapshot.data!;
          if (meals.isEmpty) {
            return const Center(child: Text("No meals yet. Add one!"));
          }

          return ListView.builder(
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
              return Dismissible(
                key: Key(meal.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${meal.name} deleted"),
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () async {
                          await db.insertMeal(
                            MealsCompanion.insert(name: meal.name),
                          );
                        },
                      ),
                    ),
                  );

                  await db.deleteMeal(meal.id);
                },
                child: ListTile(
                  title: Text(meal.name),
                  subtitle: Text(meal.createdAt.toString()),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final controller = TextEditingController();

          final result = await showDialog<String>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Add meal"),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Enter meal name:",
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(controller.text);
                    },
                    child: const Text("Add"),
                  ),
                ],
              );
            },
          );

          if (result != null && result.trim().isNotEmpty) {
            final db = ref.read(dbProvider);
            await db.insertMeal(MealsCompanion.insert(name: result.trim()));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
