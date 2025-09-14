import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:simplefit_log/services/supabase_providers.dart';

class WorkoutsListScreen extends ConsumerWidget {
  const WorkoutsListScreen({super.key});

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
    final workoutsAsync = ref.watch(workoutsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Workouts")),
      body: workoutsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (workouts) {
          if (workouts.isEmpty) {
            return const Center(child: Text("No workouts yet, add one!"));
          }
          return ListView.builder(
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              final id = workout['id'] as String;
              final name = (workout['name'] ?? '') as String;
              final createdAt = _formatDate(workout['created_at'] as String?);

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
                  final removedWorkout = workout;
                  final updatedList = List<Map<String, dynamic>>.from(workouts)
                    ..removeAt(index);

                  //
                  //Update the provider with the shorter list immediately
                  ref.read(workoutsProvider.notifier).state = AsyncValue.data(
                    updatedList,
                  );

                  // Show snackbar with undo option
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$name deleted"),
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () async {
                          await ref
                              .read(supabaseServiceProvider)
                              .insertWorkout(removedWorkout['name'] as String);
                          // ignore: unused_result
                          ref.refresh(workoutsProvider);
                        },
                      ),
                    ),
                  );

                  // Perform delete in Supabase
                  await ref.read(supabaseServiceProvider).deleteWorkout(id);

                  // Refresh provider to sync with Supabase
                  // ignore: unused_result
                  ref.refresh(workoutsProvider);
                },
                child: ListTile(title: Text(name), subtitle: Text(createdAt)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final controller = TextEditingController();

          final result = await showDialog<Map<String, String>>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Add workout"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: "Enter workout name:",
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
                      Navigator.of(context).pop({"name": controller.text});
                    },
                    child: const Text("Add"),
                  ),
                ],
              );
            },
          );

          if (result != null && result["name"]!.trim().isNotEmpty) {
            final name = result["name"]!.trim();
            await ref.read(supabaseServiceProvider).insertWorkout(name);
            // ignore: unused_result
            ref.refresh(workoutsProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
