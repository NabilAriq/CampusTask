import 'package:drift/drift.dart';

import 'connection/connection.dart' as impl;

part 'app_database.g.dart';

// ── Table Definitions ───────────────────────────────────────────────────────

/// Represents the `courses` table.
class Courses extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get code => text()();
  TextColumn get lecturerName => text()();
  IntColumn get accentColorValue => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Represents the `tasks` table.
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get courseId =>
      text().references(Courses, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  // Stored as string: 'low' | 'medium' | 'high'
  TextColumn get priority => text()();
  // Stored as string: 'pending' | 'inProgress' | 'completed'
  TextColumn get status => text()();
  IntColumn get deadline => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database ────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Courses, Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? impl.openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
      );

  // ── Course DAOs ──────────────────────────────────────────────────────────

  /// Watch all courses, ordered by creation date descending.
  Stream<List<Course>> watchAllCourses() =>
      (select(courses)..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
          .watch();

  Future<List<Course>> getAllCourses() =>
      (select(courses)..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
          .get();

  Future<Course?> getCourseById(String id) =>
      (select(courses)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<void> insertCourse(CoursesCompanion entry) =>
      into(courses).insert(entry);

  Future<bool> updateCourse(CoursesCompanion entry) =>
      update(courses).replace(entry);

  Future<int> deleteCourse(String id) =>
      (delete(courses)..where((c) => c.id.equals(id))).go();

  // ── Task DAOs ────────────────────────────────────────────────────────────

  /// Watch all tasks for a given course, ordered by deadline ascending.
  Stream<List<Task>> watchTasksByCourse(String courseId) => (select(tasks)
        ..where((t) => t.courseId.equals(courseId))
        ..orderBy([(t) => OrderingTerm.asc(t.deadline)]))
      .watch();

  /// Watch ALL tasks ordered by deadline ascending.
  Stream<List<Task>> watchAllTasks() =>
      (select(tasks)..orderBy([(t) => OrderingTerm.asc(t.deadline)])).watch();

  Future<List<Task>> getAllTasks() =>
      (select(tasks)..orderBy([(t) => OrderingTerm.asc(t.deadline)])).get();

  Future<Task?> getTaskById(String id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertTask(TasksCompanion entry) => into(tasks).insert(entry);

  Future<bool> updateTask(TasksCompanion entry) =>
      update(tasks).replace(entry);

  Future<int> deleteTask(String id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  /// Watch tasks with optional priority and status filters.
  Stream<List<Task>> watchFilteredTasks({
    String? priority,
    String? status,
  }) {
    return (select(tasks)
          ..where((t) {
            Expression<bool> expr = const Constant(true);
            if (priority != null) {
              expr = expr & t.priority.equals(priority);
            }
            if (status != null) {
              expr = expr & t.status.equals(status);
            }
            return expr;
          })
          ..orderBy([(t) => OrderingTerm.asc(t.deadline)]))
        .watch();
  }
}

