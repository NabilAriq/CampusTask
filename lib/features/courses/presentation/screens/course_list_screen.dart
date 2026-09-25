import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/course_entity.dart';
import '../controllers/course_controller.dart';
import 'course_form_screen.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/controllers/task_controller.dart';
import '../../../tasks/presentation/screens/task_detail_screen.dart';
import '../../../tasks/presentation/screens/task_list_screen.dart';
import '../../../tasks/presentation/widgets/priority_badge.dart';
import '../../../tasks/presentation/widgets/status_chip.dart';

import '../../../tasks/presentation/widgets/calendar_panel_widget.dart';
import '../../../tasks/presentation/screens/task_form_screen.dart';

class CourseListScreen extends ConsumerStatefulWidget {
  const CourseListScreen({super.key});

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeScreen(context),
          _buildCalendarScreen(context),
          const TaskListScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Mata Kuliah',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Kalender',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Semua Tugas',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final activeTasksAsync = ref.watch(activeTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusTask'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Kalender Tugas',
            onPressed: () => setState(() => _currentIndex = 1),
          ),
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'Semua Tugas',
            onPressed: () => setState(() => _currentIndex = 2),
          ),
        ],
      ),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (courses) {
          final courseMap = {for (final c in courses) c.id: c};
          final activeTasks = activeTasksAsync.asData?.value ?? [];

          return CustomScrollView(
            slivers: [
              // ── Active Tasks Section (Scrollable Horizontal) ───────────────
              SliverToBoxAdapter(
                child: _ActiveTasksSection(
                  tasks: activeTasks,
                  courseMap: courseMap,
                  onStatusChanged: (taskId, newStatus) {
                    ref
                        .read(taskControllerProvider.notifier)
                        .updateTaskStatus(taskId, newStatus);
                  },
                ),
              ),

              // ── Calendar Panel Section on Home Page ────────────────────────
              SliverToBoxAdapter(
                child: CalendarPanelWidget(
                  showHeaderTitle: true,
                  onOpenFullScreen: () => setState(() => _currentIndex = 1),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // ── Courses Section Header ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.school_outlined,
                          size: 20, color: AppColors.textDark),
                      const SizedBox(width: 8),
                      const Text(
                        'Daftar Mata Kuliah',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${courses.length}',
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
              ),

              // ── Course Cards List or Empty State ───────────────────────────
              if (courses.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _EmptyState(
                      onAdd: () => _openForm(context),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final course = courses[index];
                        return _CourseCard(
                          course: course,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TaskListScreen(courseId: course.id),
                            ),
                          ),
                          onEdit: () => _openForm(context, course: course),
                          onDelete: () =>
                              _confirmDelete(context, ref, course),
                        );
                      },
                      childCount: courses.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        tooltip: 'Tambah Mata Kuliah',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Tugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah Tugas',
            onPressed: () => _openTaskForm(context),
          ),
        ],
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: 80),
          child: CalendarPanelWidget(
            showHeaderTitle: false,
            maxTasksPreview: 50,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskForm(context),
        tooltip: 'Tambah Tugas',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openTaskForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskFormScreen(
        initialDeadline: DateTime.now(),
      ),
    );
  }

  void _openForm(BuildContext context, {CourseEntity? course}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CourseFormScreen(existing: course),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, CourseEntity course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Mata Kuliah?'),
        content: Text(
          'Menghapus "${course.name}" juga akan menghapus semua tugas terkait. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.priorityHigh),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(courseControllerProvider.notifier)
                  .deleteCourse(course.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ── Course Card ──────────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final CourseEntity course;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Accent color indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: course.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: course.accentColor.withOpacity(0.6), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    course.code.length > 4
                        ? course.code.substring(0, 4)
                        : course.code,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: course.accentColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      course.lecturerName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF546E7A),
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.accentBorder),
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus',
                          style: TextStyle(color: AppColors.priorityHigh))),
                ],
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.accentBorder),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined,
                size: 80, color: AppColors.accentBorder.withValues(alpha: 0.6)),
            const SizedBox(height: 20),
            const Text(
              'Belum ada mata kuliah',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan mata kuliah pertamamu\nuntuk mulai mencatat tugas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF546E7A)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Mata Kuliah'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active Tasks Section ─────────────────────────────────────────────────────

class _ActiveTasksSection extends StatelessWidget {
  const _ActiveTasksSection({
    required this.tasks,
    required this.courseMap,
    required this.onStatusChanged,
  });

  final List<TaskEntity> tasks;
  final Map<String, CourseEntity> courseMap;
  final void Function(String taskId, TaskStatus status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.pending_actions_rounded,
                  size: 20, color: AppColors.textDark),
              const SizedBox(width: 8),
              const Text(
                'Tugas Belum Selesai',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${tasks.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TaskListScreen()),
                ),
                child: const Text('Semua Tugas'),
              ),
            ],
          ),
        ),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accentBorder.withValues(alpha: 0.5),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.statusCompleted, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tidak ada tugas berjalan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Semua tugas telah diselesaikan atau belum ada tugas baru.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF546E7A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 148,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final task = tasks[index];
                final course = courseMap[task.courseId];
                return _ActiveTaskCard(
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
                  onStatusChanged: (newStatus) =>
                      onStatusChanged(task.id, newStatus),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Active Task Card (Horizontal Scroll Item) ────────────────────────────────

class _ActiveTaskCard extends StatelessWidget {
  const _ActiveTaskCard({
    required this.task,
    required this.course,
    required this.onTap,
    required this.onStatusChanged,
  });

  final TaskEntity task;
  final CourseEntity? course;
  final VoidCallback onTap;
  final ValueChanged<TaskStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, HH:mm', 'id_ID');
    final isOverdue = task.isOverdue;
    final isUrgent = task.isUrgent;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isOverdue
              ? AppColors.priorityHigh.withValues(alpha: 0.5)
              : isUrgent
                  ? AppColors.priorityMedium.withValues(alpha: 0.5)
                  : AppColors.accentBorder.withValues(alpha: 0.4),
          width: (isOverdue || isUrgent) ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: Course code badge + Priority badge
                Row(
                  children: [
                    if (course != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: course!.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: course!.accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              course!.code,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: course!.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    PriorityBadge(priority: task.priority, compact: true),
                  ],
                ),
                // Task title
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Bottom row: Deadline + Status chip
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: isOverdue
                          ? AppColors.priorityHigh
                          : isUrgent
                              ? AppColors.priorityMedium
                              : const Color(0xFF546E7A),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        dateFormat.format(task.deadline),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: (isOverdue || isUrgent)
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isOverdue
                              ? AppColors.priorityHigh
                              : isUrgent
                                  ? AppColors.priorityMedium
                                  : const Color(0xFF546E7A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusChip(
                      status: task.status,
                      compact: true,
                      onTap: () {
                        final next = task.status == TaskStatus.pending
                            ? TaskStatus.inProgress
                            : TaskStatus.completed;
                        onStatusChanged(next);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


