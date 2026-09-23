import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/task_entity.dart';
import '../controllers/task_controller.dart';
import '../../../courses/presentation/controllers/course_controller.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key, this.courseId});

  /// If provided, shows tasks only for this course.
  final String? courseId;

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(taskFilterProvider);
    final coursesAsync = ref.watch(coursesProvider);

    // Choose stream: filtered all tasks OR by course
    final tasksAsync = widget.courseId != null
        ? ref.watch(tasksByCourseProvider(widget.courseId!))
        : ref.watch(filteredTasksProvider);

    final courseMap = coursesAsync.asData?.value != null
        ? {for (final c in coursesAsync.asData!.value) c.id: c}
        : <String, CourseEntity>{};

    // Title from course name if filtered by course
    final title = widget.courseId != null && coursesAsync.asData?.value != null
        ? coursesAsync.asData!.value
            .firstWhere(
              (c) => c.id == widget.courseId,
              orElse: () => CourseEntity(
                id: '',
                name: 'Tugas',
                code: '',
                lecturerName: '',
                accentColor: AppColors.primaryBlue,
                createdAt: DateTime.now(),
              ),
            )
            .name
        : 'Semua Tugas';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // Filter button
          if (widget.courseId == null)
            IconButton(
              icon: Badge(
                isLabelVisible:
                    filterState.priority != null || filterState.status != null,
                child: const Icon(Icons.filter_list_rounded),
              ),
              tooltip: 'Filter',
              onPressed: () => _showFilterSheet(context, filterState),
            ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return _EmptyTaskState(
              onAdd: () => _openForm(context),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                task: task,
                course: courseMap[task.courseId],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskDetailScreen(
                      taskId: task.id,
                      course: courseMap[task.courseId],
                    ),
                  ),
                ),
                onStatusChanged: (newStatus) {
                  ref
                      .read(taskControllerProvider.notifier)
                      .updateTaskStatus(task.id, newStatus);
                },
                onDelete: () => _confirmDelete(context, task),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskFormScreen(preselectedCourseId: widget.courseId),
    );
  }

  void _confirmDelete(BuildContext context, TaskEntity task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tugas?'),
        content: Text('Yakin ingin menghapus "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.priorityHigh),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(taskControllerProvider.notifier).deleteTask(task.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, TaskFilterState current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(current: current),
    );
  }
}

// ── Filter Sheet ─────────────────────────────────────────────────────────────

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet({required this.current});
  final TaskFilterState current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.accentBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Filter Tugas',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
          const SizedBox(height: 16),

          // Priority filter
          const Text('Prioritas',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: 'Semua',
                selected: current.priority == null,
                onTap: () =>
                    ref.read(taskFilterProvider.notifier).setPriority(null),
              ),
              ...TaskPriority.values.map((p) => _FilterChip(
                    label: p.label,
                    selected: current.priority == p,
                    onTap: () =>
                        ref.read(taskFilterProvider.notifier).setPriority(p),
                  )),
            ],
          ),
          const SizedBox(height: 16),

          // Status filter
          const Text('Status',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: 'Semua',
                selected: current.status == null,
                onTap: () =>
                    ref.read(taskFilterProvider.notifier).setStatus(null),
              ),
              ...TaskStatus.values.map((s) => _FilterChip(
                    label: s.label,
                    selected: current.status == s,
                    onTap: () =>
                        ref.read(taskFilterProvider.notifier).setStatus(s),
                  )),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(taskFilterProvider.notifier).clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Terapkan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primaryBlue : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.accentBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color:
                selected ? AppColors.surfaceWhite : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────────────

class _EmptyTaskState extends StatelessWidget {
  const _EmptyTaskState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt_outlined,
                size: 80, color: AppColors.accentBorder.withOpacity(0.6)),
            const SizedBox(height: 20),
            const Text('Belum ada tugas',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan tugas pertamamu\nuntuk mulai melacak tenggat waktu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF546E7A)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Tugas'),
            ),
          ],
        ),
      ),
    );
  }
}
