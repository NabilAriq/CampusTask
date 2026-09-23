import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/task_entity.dart';
import '../models/task_model.dart';

/// Abstract contract for task persistence operations.
abstract class TaskRepository {
  Stream<List<TaskEntity>> watchAllTasks();
  Stream<List<TaskEntity>> watchFilteredTasks({
    TaskPriority? priority,
    TaskStatus? status,
  });
  Stream<List<TaskEntity>> watchTasksByCourse(String courseId);
  Future<TaskEntity?> getTaskById(String id);
  Future<void> addTask({
    required String courseId,
    required String title,
    String? description,
    required TaskPriority priority,
    required TaskStatus status,
    required DateTime deadline,
  });
  Future<void> updateTask(TaskEntity task);
  Future<void> updateTaskStatus(String id, TaskStatus status);
  Future<void> deleteTask(String id);
}

/// Drift-backed implementation of [TaskRepository].
class DriftTaskRepository implements TaskRepository {
  const DriftTaskRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  @override
  Stream<List<TaskEntity>> watchAllTasks() =>
      _db.watchAllTasks().map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Stream<List<TaskEntity>> watchFilteredTasks({
    TaskPriority? priority,
    TaskStatus? status,
  }) =>
      _db
          .watchFilteredTasks(
            priority: priority?.key,
            status: status?.key,
          )
          .map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Stream<List<TaskEntity>> watchTasksByCourse(String courseId) =>
      _db
          .watchTasksByCourse(courseId)
          .map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Future<TaskEntity?> getTaskById(String id) async {
    final row = await _db.getTaskById(id);
    return row?.toEntity();
  }

  @override
  Future<void> addTask({
    required String courseId,
    required String title,
    String? description,
    required TaskPriority priority,
    required TaskStatus status,
    required DateTime deadline,
  }) async {
    final entity = TaskEntity(
      id: _uuid.v4(),
      courseId: courseId,
      title: title,
      description: description,
      priority: priority,
      status: status,
      deadline: deadline,
      createdAt: DateTime.now(),
    );
    await _db.insertTask(entity.toCompanion());
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    await _db.updateTask(task.toCompanion());
  }

  @override
  Future<void> updateTaskStatus(String id, TaskStatus status) async {
    final task = await getTaskById(id);
    if (task != null) {
      await _db.updateTask(task.copyWith(status: status).toCompanion());
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    await _db.deleteTask(id);
  }
}

