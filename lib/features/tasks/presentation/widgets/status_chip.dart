import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/task_entity.dart';

/// A chip showing the task status with a tap callback to cycle through statuses.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.onTap,
    this.compact = false,
  });

  final TaskStatus status;
  final VoidCallback? onTap;
  final bool compact;

  Color get _color {
    switch (status) {
      case TaskStatus.pending:
        return AppColors.statusPending;
      case TaskStatus.inProgress:
        return AppColors.statusInProgress;
      case TaskStatus.completed:
        return AppColors.statusCompleted;
    }
  }

  IconData get _icon {
    switch (status) {
      case TaskStatus.pending:
        return Icons.radio_button_unchecked_rounded;
      case TaskStatus.inProgress:
        return Icons.timelapse_rounded;
      case TaskStatus.completed:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10,
          vertical: compact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: compact ? 11 : 13, color: _color),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                color: _color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
