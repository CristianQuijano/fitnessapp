import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:uuid/uuid.dart';

part 'local_db.g.dart';

// == Meals Table ==

class Meals extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text()();
  IntColumn get calories =>
      integer().nullable()(); // nullable() so old rows don’t break.
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

// == Workouts Table

class Workouts extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

// == Database Class ==

@DriftDatabase(tables: [Meals, Workouts])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        await m.createTable(workouts);
      }
      if (from <= 2) {
        await m.addColumn(meals, meals.calories);
      }
    },
  );

  // === Meals CRUD helpers ===
  Future<List<Meal>> getAllMeals() => select(meals).get();
  Future<int> insertMeal(MealsCompanion meal) => into(meals).insert(meal);
  Stream<List<Meal>> watchAllMeals() => select(meals).watch();
  Future<int> deleteMeal(String id) =>
      (delete(meals)..where((tbl) => tbl.id.equals(id))).go();

  // === Workouts CRUD helpers ===
  Future<List<Workout>> getAllWorkouts() => select(workouts).get();
  Future<int> insertWorkout(WorkoutsCompanion workout) =>
      into(workouts).insert(workout);
  Stream<List<Workout>> watchAllWorkouts() => select(workouts).watch();
  Future<int> deleteWorkout(String id) =>
      (delete(workouts)..where((tbl) => tbl.id.equals(id))).go();

  // --- Date helpers (Monday to Sunday) ---
  DateTime _atMidnight(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // Start of the week (Mon 00:00) for a given date.
  DateTime _startOfWeek(DateTime dt) {
    final day = _atMidnight(dt);
    final mondayDelta = day.weekday - DateTime.monday; // 0 if Monday
    return day.subtract(Duration(days: mondayDelta));
  }

  // End of week **exclusive** (next Mon 00:00) - handy for range queries
  DateTime _endOfWeekExclusive(DateTime dt) =>
      _startOfWeek(dt).add(const Duration(days: 7));

  // -- Count helpers for arbitrary ranges ---
  Future<int> countMealsBetween(DateTime start, DateTime endExclusive) async {
    final countExp = meals.id.count();
    final query = selectOnly(meals)
      ..addColumns([countExp])
      ..where(meals.createdAt.isBetweenValues(start, endExclusive));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<int> countWorkoutsBetween(
    DateTime start,
    DateTime endExclusive,
  ) async {
    final countExp = workouts.id.count();
    final query = selectOnly(workouts)
      ..addColumns([countExp])
      ..where(workouts.createdAt.isBetweenValues(start, endExclusive));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  // --- Convenience: counts for the current week ---
  Future<int> getMealsCountThisWeek() {
    final now = DateTime.now();
    final start = _startOfWeek(now);
    final end = _endOfWeekExclusive(now);
    return countMealsBetween(start, end);
  }

  Future<int> getWorkoutsCountThisWeek() {
    final now = DateTime.now();
    final start = _startOfWeek(now);
    final end = _endOfWeekExclusive(now);
    return countWorkoutsBetween(start, end);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'simplefit.sqlite'));
    return NativeDatabase(file);
  });
}
