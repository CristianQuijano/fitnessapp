import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/local_db.dart';
import '../../services/providers.dart';

class WorkoutsListScreen extends ConsumerWidget {
  const WorkoutsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Workouts")),
      body: StreamBuilder(
        stream: db.watchAllWorkouts(), // auto-updates on db changes
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final workouts = snapshot.data!;
          if (workouts.isEmpty) {
            return const Center(child: Text("No workouts yet. Add one!"));
          }

          return ListView.builder(
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return Dismissible(
                key: Key(workout.id),
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
                      content: Text("${workout.name} deleted"),
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () async {
                          await db.insertWorkout(
                            WorkoutsCompanion.insert(name: workout.name),
                          );
                        },
                      ),
                    ),
                  );

                  await db.deleteWorkout(workout.id);
                },
                child: ListTile(
                  title: Text(workout.name),
                  subtitle: Text(workout.createdAt.toString()),
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
                title: const Text("Add workout"),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Enter workout name:",
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
            await db.insertWorkout(
              WorkoutsCompanion.insert(name: result.trim()),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
