import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/task_entity.dart';
import '../controllers/task_controller.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../widgets/priority_badge.dart';
import '../widgets/status_chip.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({
    super.key,
    required this.taskId,
    this.course,
  });

  final String taskId;
  final CourseEntity? course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksProvider);

    return tasksAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (tasks) {
        final task =
            tasks.where((t) => t.id == taskId).firstOrNull;
        if (task == null) {
          return const Scaffold(
              body: Center(child: Text('Tugas tidak ditemukan')));
        }
        return _TaskDetailBody(task: task, course: course);
      },
    );
  }
}

class _TaskDetailBody extends ConsumerWidget {
  const _TaskDetailBody({required this.task, this.course});
  final TaskEntity task;
  final CourseEntity? course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat =
        DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm', 'id_ID');
    final isOverdue = task.isOverdue;
    final isUrgent = task.isUrgent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tugas'),
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => TaskFormScreen(existing: task),
              );
            },
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Course chip ─────────────────────────────────────────────
            if (course != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: course!.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: course!.accentColor.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: course!.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${course!.code} · ${course!.name}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: course!.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ── Title ───────────────────────────────────────────────────
            Text(
              task.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                decoration: task.status == TaskStatus.completed
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // ── Priority + Status row ───────────────────────────────────
            Row(
              children: [
                PriorityBadge(priority: task.priority),
                const SizedBox(width: 8),
                StatusChip(
                  status: task.status,
                  onTap: () {
                    final next = _nextStatus(task.status);
                    ref
                        .read(taskControllerProvider.notifier)
                        .updateTaskStatus(task.id, next);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // ── Deadline card ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isOverdue
                    ? AppColors.priorityHigh.withOpacity(0.06)
                    : isUrgent
                        ? AppColors.priorityMedium.withOpacity(0.06)
                        : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOverdue
                      ? AppColors.priorityHigh.withOpacity(0.3)
                      : isUrgent
                          ? AppColors.priorityMedium.withOpacity(0.3)
                          : AppColors.accentBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 28,
                    color: isOverdue
                        ? AppColors.priorityHigh
                        : isUrgent
                            ? AppColors.priorityMedium
                            : AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOverdue
                              ? '⚠ Tenggat Telah Lewat!'
                              : isUrgent
                                  ? '🔔 Segera!'
                                  : 'Tenggat Waktu',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOverdue
                                ? AppColors.priorityHigh
                                : isUrgent
                                    ? AppColors.priorityMedium
                                    : AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(task.deadline),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Pukul ${timeFormat.format(task.deadline)} WIB',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF546E7A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Description ─────────────────────────────────────────────
            if (task.description != null &&
                task.description!.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Deskripsi / Instruksi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accentBorder),
                ),
                child: Text(
                  task.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Created at ──────────────────────────────────────────────
            Text(
              'Ditambahkan ${dateFormat.format(task.createdAt)}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF90A4AE),
              ),
            ),
            const SizedBox(height: 32),

            // ── Quick status toggle buttons ─────────────────────────────
            const Text(
              'Ubah Status',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: TaskStatus.values.map((s) {
                final selected = task.status == s;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => ref
                          .read(taskControllerProvider.notifier)
                          .updateTaskStatus(task.id, s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? _statusColor(s).withOpacity(0.15)
                              : AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? _statusColor(s)
                                : AppColors.accentBorder,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          s.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? _statusColor(s)
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return AppColors.statusPending;
      case TaskStatus.inProgress:
        return AppColors.statusInProgress;
      case TaskStatus.completed:
        return AppColors.statusCompleted;
    }
  }

  TaskStatus _nextStatus(TaskStatus current) {
    switch (current) {
      case TaskStatus.pending:
        return TaskStatus.inProgress;
      case TaskStatus.inProgress:
        return TaskStatus.completed;
      case TaskStatus.completed:
        return TaskStatus.pending;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
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
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

