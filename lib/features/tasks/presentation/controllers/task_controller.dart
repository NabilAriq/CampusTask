import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/task_repository.dart';
import '../../domain/entities/task_entity.dart';
import '../../../courses/presentation/controllers/course_controller.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return DriftTaskRepository(ref.watch(appDatabaseProvider));
});

// ── Filter state ──────────────────────────────────────────────────────────────

class TaskFilterState {
  const TaskFilterState({
    this.priority,
    this.status,
  });

  final TaskPriority? priority;
  final TaskStatus? status;

  TaskFilterState copyWith({
    TaskPriority? Function()? priority,
    TaskStatus? Function()? status,
  }) {
    return TaskFilterState(
      priority: priority != null ? priority() : this.priority,
      status: status != null ? status() : this.status,
    );
  }
}

// ── Filter notifier ───────────────────────────────────────────────────────────

class TaskFilterNotifier extends Notifier<TaskFilterState> {
  @override
  TaskFilterState build() => const TaskFilterState();

  void setPriority(TaskPriority? priority) {
    state = state.copyWith(priority: () => priority);
  }

  void setStatus(TaskStatus? status) {
    state = state.copyWith(status: () => status);
  }

  void clearFilters() {
    state = const TaskFilterState();
  }
}

final taskFilterProvider =
    NotifierProvider<TaskFilterNotifier, TaskFilterState>(
  TaskFilterNotifier.new,
);

// ── Stream providers ──────────────────────────────────────────────────────────

/// Watches tasks filtered by the current [TaskFilterState].
final filteredTasksProvider = StreamProvider<List<TaskEntity>>((ref) {
  final filter = ref.watch(taskFilterProvider);
  return ref.watch(taskRepositoryProvider).watchFilteredTasks(
        priority: filter.priority,
        status: filter.status,
      );
});

/// Watches all tasks (unfiltered).
final allTasksProvider = StreamProvider<List<TaskEntity>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAllTasks();
});

/// Watches active tasks that are pending or in progress, ordered by deadline.
final activeTasksProvider = Provider<AsyncValue<List<TaskEntity>>>((ref) {
  final allTasksAsync = ref.watch(allTasksProvider);
  return allTasksAsync.whenData(
    (tasks) => tasks
        .where((t) =>
            t.status == TaskStatus.pending ||
            t.status == TaskStatus.inProgress)
        .toList(),
  );
});

/// Watches tasks for a specific course.
final tasksByCourseProvider =
    StreamProvider.family<List<TaskEntity>, String>((ref, courseId) {
  return ref.watch(taskRepositoryProvider).watchTasksByCourse(courseId);
});

// ── Controller ────────────────────────────────────────────────────────────────

/// State notifier for task mutations (add, update, delete, status change).
class TaskController extends AsyncNotifier<List<TaskEntity>> {
  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  @override
  Future<List<TaskEntity>> build() async {
    final repo = ref.watch(taskRepositoryProvider);
    return repo.watchAllTasks().first;
  }

  Future<void> addTask({
    required String courseId,
    required String title,
    String? description,
    required TaskPriority priority,
    required TaskStatus status,
    required DateTime deadline,
  }) async {
    await AsyncValue.guard(() => _repo.addTask(
          courseId: courseId,
          title: title,
          description: description,
          priority: priority,
          status: status,
          deadline: deadline,
        ));
  }

  Future<void> updateTask(TaskEntity task) async {
    await AsyncValue.guard(() => _repo.updateTask(task));
  }

  Future<void> updateTaskStatus(String id, TaskStatus status) async {
    await AsyncValue.guard(() => _repo.updateTaskStatus(id, status));
  }

  Future<void> deleteTask(String id) async {
    await AsyncValue.guard(() => _repo.deleteTask(id));
  }
}

final taskControllerProvider =
    AsyncNotifierProvider<TaskController, List<TaskEntity>>(
  TaskController.new,
);

