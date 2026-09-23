import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/task_entity.dart';
import '../../../courses/domain/entities/course_entity.dart';
import 'priority_badge.dart';
import 'status_chip.dart';

/// A list-item card representing a single task.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.course,
    this.onTap,
    this.onStatusChanged,
    this.onDelete,
  });

  final TaskEntity task;
  final CourseEntity? course;
  final VoidCallback? onTap;
  final ValueChanged<TaskStatus>? onStatusChanged;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    final isOverdue = task.isOverdue;
    final isUrgent = task.isUrgent;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────────────────────
              Row(
                children: [
                  // Course color dot + label
                  if (course != null) ...[
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
                      course!.code,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  PriorityBadge(priority: task.priority, compact: true),
                  if (onDelete != null) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: onDelete,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: AppColors.statusPending,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // ── Title ──────────────────────────────────────────────────
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  decoration: task.status == TaskStatus.completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (task.description != null &&
                  task.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF546E7A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 10),

              // ── Footer row ─────────────────────────────────────────────
              Row(
                children: [
                  // Deadline
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: isOverdue
                        ? AppColors.priorityHigh
                        : isUrgent
                            ? AppColors.priorityMedium
                            : AppColors.accentBorder,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(task.deadline),
                    style: TextStyle(
                      fontSize: 11,
                      color: isOverdue
                          ? AppColors.priorityHigh
                          : isUrgent
                              ? AppColors.priorityMedium
                              : const Color(0xFF546E7A),
                      fontWeight:
                          (isOverdue || isUrgent) ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (isOverdue) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.priorityHigh.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TERLAMBAT',
                        style: TextStyle(
                            fontSize: 9,
                            color: AppColors.priorityHigh,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Status chip — tappable to cycle
                  StatusChip(
                    status: task.status,
                    compact: true,
                    onTap: onStatusChanged != null
                        ? () {
                            final next = _nextStatus(task.status);
                            onStatusChanged!(next);
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
}

