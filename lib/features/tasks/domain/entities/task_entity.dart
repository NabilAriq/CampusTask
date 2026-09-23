/// Priority levels for a task.
enum TaskPriority {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Rendah';
      case TaskPriority.medium:
        return 'Sedang';
      case TaskPriority.high:
        return 'Tinggi';
    }
  }

  /// Serialization key stored in the database.
  String get key {
    switch (this) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
    }
  }

  static TaskPriority fromKey(String key) {
    switch (key) {
      case 'medium':
        return TaskPriority.medium;
      case 'high':
        return TaskPriority.high;
      default:
        return TaskPriority.low;
    }
  }
}

/// Workflow status of a task.
enum TaskStatus {
  pending,
  inProgress,
  completed;

  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Belum Dimulai';
      case TaskStatus.inProgress:
        return 'Sedang Dikerjakan';
      case TaskStatus.completed:
        return 'Selesai';
    }
  }

  /// Serialization key stored in the database.
  String get key {
    switch (this) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'inProgress';
      case TaskStatus.completed:
        return 'completed';
    }
  }

  static TaskStatus fromKey(String key) {
    switch (key) {
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.pending;
    }
  }
}

/// Pure domain entity for a Task.
class TaskEntity {
  const TaskEntity({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    required this.deadline,
    required this.createdAt,
  });

  final String id;
  final String courseId;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime deadline;
  final DateTime createdAt;

  /// Returns true if the deadline is within 24 hours from now.
  bool get isUrgent =>
      deadline.difference(DateTime.now()).inHours <= 24 &&
      status != TaskStatus.completed;

  /// Returns true if the deadline has passed and task is not completed.
  bool get isOverdue =>
      deadline.isBefore(DateTime.now()) && status != TaskStatus.completed;

  TaskEntity copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? deadline,
    DateTime? createdAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TaskEntity(id: $id, title: $title, priority: $priority, status: $status)';
}

