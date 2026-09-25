import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/task_entity.dart';
import '../controllers/task_controller.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../courses/presentation/controllers/course_controller.dart';
import 'task_card.dart';
import '../screens/task_form_screen.dart';
import '../screens/task_detail_screen.dart';

class CalendarPanelWidget extends ConsumerStatefulWidget {
  const CalendarPanelWidget({
    super.key,
    this.showHeaderTitle = false,
    this.onOpenFullScreen,
    this.maxTasksPreview = 5,
  });

  /// Whether to show the "Kalender Deadline Tugas" section title with "Buka Penuh" button.
  final bool showHeaderTitle;

  /// Optional callback to navigate to full calendar view or switch tab.
  final VoidCallback? onOpenFullScreen;

  /// Max tasks to preview under the calendar when embedded.
  final int maxTasksPreview;

  @override
  ConsumerState<CalendarPanelWidget> createState() =>
      _CalendarPanelWidgetState();
}

class _CalendarPanelWidgetState extends ConsumerState<CalendarPanelWidget> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  void _openTaskForm({DateTime? initialDeadline}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskFormScreen(
        initialDeadline: initialDeadline ?? _selectedDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(allTasksProvider);
    final coursesAsync = ref.watch(coursesProvider);

    final courseMap = coursesAsync.asData?.value != null
        ? {for (final c in coursesAsync.asData!.value) c.id: c}
        : <String, CourseEntity>{};

    return tasksAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text('Error: $e')),
      ),
      data: (allTasks) {
        // Group tasks by deadline date (normalized to midnight)
        final Map<DateTime, List<TaskEntity>> tasksByDate = {};
        for (final task in allTasks) {
          final dateKey = DateTime(
            task.deadline.year,
            task.deadline.month,
            task.deadline.day,
          );
          tasksByDate.putIfAbsent(dateKey, () => []).add(task);
        }

        final selectedDateKey = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );
        final selectedTasks = tasksByDate[selectedDateKey] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section Header (if enabled) ─────────────────────────
            if (widget.showHeaderTitle)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        size: 20, color: AppColors.textDark),
                    const SizedBox(width: 8),
                    const Text(
                      'Kalender Deadline Tugas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    if (widget.onOpenFullScreen != null)
                      TextButton.icon(
                        onPressed: widget.onOpenFullScreen,
                        icon: const Icon(Icons.fullscreen_rounded, size: 18),
                        label: const Text('Buka Penuh'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                  ],
                ),
              ),

            // ── Month Header & Navigation ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _previousMonth,
                    tooltip: 'Bulan Sebelumnya',
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        DateFormat.yMMMM('id_ID').format(_focusedMonth),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _nextMonth,
                    tooltip: 'Bulan Berikutnya',
                  ),
                  TextButton(
                    onPressed: _goToToday,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Hari Ini'),
                  ),
                ],
              ),
            ),

            // ── Calendar Status Legend ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.accentBorder.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _LegendItem(
                      color: AppColors.statusPending,
                      label: 'Belum Dimulai',
                    ),
                    _LegendItem(
                      color: AppColors.statusInProgress,
                      label: 'Sedang Berjalan',
                    ),
                    _LegendItem(
                      color: AppColors.statusCompleted,
                      label: 'Selesai',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Days of Week Header ──────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _DayHeaderCell('Sen'),
                  _DayHeaderCell('Sel'),
                  _DayHeaderCell('Rab'),
                  _DayHeaderCell('Kam'),
                  _DayHeaderCell('Jum'),
                  _DayHeaderCell('Sab'),
                  _DayHeaderCell('Min', isWeekend: true),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── Calendar Days Grid ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.accentBorder.withValues(alpha: 0.4),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _CalendarGrid(
                  focusedMonth: _focusedMonth,
                  selectedDate: _selectedDate,
                  tasksByDate: tasksByDate,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                      if (date.month != _focusedMonth.month) {
                        _focusedMonth = DateTime(date.year, date.month, 1);
                      }
                    });
                  },
                ),
              ),
            ),

            // ── Selected Date Tasks Header ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.event_note_rounded,
                      size: 20, color: AppColors.textDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                          .format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${selectedTasks.length} tugas',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Selected Date Tasks Content ──────────────────────────
            if (selectedTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentBorder.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 40,
                        color: AppColors.accentBorder.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tidak ada deadline tugas',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tidak ada tugas yang jatuh tempo pada tanggal ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF546E7A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _openTaskForm(
                          initialDeadline: _selectedDate,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Tambah Tugas di Tanggal Ini'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(color: AppColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: selectedTasks
                      .take(widget.maxTasksPreview)
                      .map((task) {
                    final course = courseMap[task.courseId];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TaskCard(
                        task: task,
                        course: course,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskDetailScreen(
                              taskId: task.id,
                              course: course,
                            ),
                          ),
                        ),
                        onStatusChanged: (newStatus) {
                          ref
                              .read(taskControllerProvider.notifier)
                              .updateTaskStatus(task.id, newStatus);
                        },
                        onDelete: () =>
                            _confirmDeleteTask(context, ref, task),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  void _confirmDeleteTask(
      BuildContext context, WidgetRef ref, TaskEntity task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tugas?'),
        content: Text('Hapus tugas "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.priorityHigh,
              foregroundColor: Colors.white,
            ),
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
}

// ── Status Legend Item ───────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF546E7A),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Day Header Cell ─────────────────────────────────────────────────────────

class _DayHeaderCell extends StatelessWidget {
  const _DayHeaderCell(this.day, {this.isWeekend = false});

  final String day;
  final bool isWeekend;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          day,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isWeekend ? AppColors.priorityHigh : const Color(0xFF546E7A),
          ),
        ),
      ),
    );
  }
}

// ── Calendar Grid ───────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.focusedMonth,
    required this.selectedDate,
    required this.tasksByDate,
    required this.onDateSelected,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final Map<DateTime, List<TaskEntity>> tasksByDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;

    final startPadding = (firstDayOfMonth.weekday - 1) % 7;
    final totalSlots = startPadding + daysInMonth;
    final rowCount = (totalSlots / 7).ceil();

    final today = DateTime.now();

    return Column(
      children: List.generate(rowCount, (rowIndex) {
        return Row(
          children: List.generate(7, (colIndex) {
            final slotIndex = (rowIndex * 7) + colIndex;
            final dayNumber = slotIndex - startPadding + 1;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              DateTime otherDate;
              if (dayNumber < 1) {
                otherDate = DateTime(
                  focusedMonth.year,
                  focusedMonth.month,
                  dayNumber,
                );
              } else {
                otherDate = DateTime(
                  focusedMonth.year,
                  focusedMonth.month + 1,
                  dayNumber - daysInMonth,
                );
              }

              return Expanded(
                child: _DateCell(
                  date: otherDate,
                  isCurrentMonth: false,
                  isSelected: _isSameDay(otherDate, selectedDate),
                  isToday: _isSameDay(otherDate, today),
                  tasks: tasksByDate[DateTime(
                          otherDate.year, otherDate.month, otherDate.day)] ??
                      [],
                  onTap: () => onDateSelected(otherDate),
                ),
              );
            }

            final cellDate = DateTime(
              focusedMonth.year,
              focusedMonth.month,
              dayNumber,
            );
            final cellTasks = tasksByDate[cellDate] ?? [];

            return Expanded(
              child: _DateCell(
                date: cellDate,
                isCurrentMonth: true,
                isSelected: _isSameDay(cellDate, selectedDate),
                isToday: _isSameDay(cellDate, today),
                tasks: cellTasks,
                onTap: () => onDateSelected(cellDate),
              ),
            );
          }),
        );
      }),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ── Single Date Cell ────────────────────────────────────────────────────────

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.tasks,
    required this.onTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final List<TaskEntity> tasks;
  final VoidCallback onTap;

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return AppColors.statusPending;
      case TaskStatus.inProgress:
        return AppColors.statusInProgress;
      case TaskStatus.completed:
        return AppColors.statusCompleted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isCurrentMonth
        ? (date.weekday == DateTime.sunday
            ? AppColors.priorityHigh
            : AppColors.textDark)
        : const Color(0xFFCFD8DC);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 78,
        margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2),
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.08)
              : isCurrentMonth
                  ? AppColors.surfaceWhite
                  : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppColors.primaryBlue, width: 2)
              : isToday
                  ? Border.all(color: AppColors.primaryBlue, width: 1.5)
                  : Border.all(
                      color: AppColors.accentBorder.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
        ),
        child: Column(
          children: [
            // ── Date Number ─────────────────────────────────────────
            if (isToday)
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${date.day}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Container(
                height: 20,
                alignment: Alignment.center,
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? AppColors.primaryBlue : textColor,
                  ),
                ),
              ),

            const SizedBox(height: 2),

            // ── Stacked Task Status Boxes (List) ─────────────────────
            Expanded(
              child: tasks.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (tasks.length <= 3)
                          ...tasks.map((task) => _TaskBox(
                                title: task.title,
                                color: _getStatusColor(task.status),
                              ))
                        else ...[
                          _TaskBox(
                            title: tasks[0].title,
                            color: _getStatusColor(tasks[0].status),
                          ),
                          _TaskBox(
                            title: tasks[1].title,
                            color: _getStatusColor(tasks[1].status),
                          ),
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 0.5),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '+${tasks.length - 2}',
                              style: const TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryBlue,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small Task Status Box inside Calendar Cell ───────────────────────────────

class _TaskBox extends StatelessWidget {
  const _TaskBox({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.1,
        ),
      ),
    );
  }
}
