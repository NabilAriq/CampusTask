import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/task_entity.dart';

/// Maps between [Task] (Drift data class) and [TaskEntity] (domain).
extension TaskMapper on Task {
  TaskEntity toEntity() {
    return TaskEntity(
      id: id,
      courseId: courseId,
      title: title,
      description: description,
      priority: TaskPriority.fromKey(priority),
      status: TaskStatus.fromKey(status),
      deadline: DateTime.fromMillisecondsSinceEpoch(deadline),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    );
  }
}

extension TaskEntityMapper on TaskEntity {
  TasksCompanion toCompanion() {
    return TasksCompanion.insert(
      id: id,
      courseId: courseId,
      title: title,
      description: Value(description),
      priority: priority.key,
      status: status.key,
      deadline: deadline.millisecondsSinceEpoch,
      createdAt: createdAt.millisecondsSinceEpoch,
    );
  }
}
