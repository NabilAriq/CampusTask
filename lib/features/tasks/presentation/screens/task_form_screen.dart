import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/task_entity.dart';
import '../controllers/task_controller.dart';
import '../../../courses/presentation/controllers/course_controller.dart';
import '../../../notifications/notification_service.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.existing, this.preselectedCourseId});

  final TaskEntity? existing;
  final String? preselectedCourseId;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late TaskPriority _priority;
  late TaskStatus _status;
  DateTime? _deadline;
  String? _selectedCourseId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _priority = e?.priority ?? TaskPriority.medium;
    _status = e?.status ?? TaskStatus.pending;
    _deadline = e?.deadline;
    _selectedCourseId = e?.courseId ?? widget.preselectedCourseId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 1)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
    );
    if (time == null || !mounted) return;

    setState(() {
      _deadline = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal & jam tenggat terlebih dahulu')),
      );
      return;
    }
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata kuliah terlebih dahulu')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final notifier = ref.read(taskControllerProvider.notifier);
      if (widget.existing == null) {
        await notifier.addTask(
          courseId: _selectedCourseId!,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          priority: _priority,
          status: _status,
          deadline: _deadline!,
        );
        // Schedule notifications for the new task
        final repo = ref.read(taskRepositoryProvider);
        final tasks = await repo.watchAllTasks().first;
        final newTask = tasks.firstWhere(
          (t) =>
              t.title == _titleCtrl.text.trim() &&
              t.courseId == _selectedCourseId,
          orElse: () => tasks.last,
        );
        await NotificationService.instance.scheduleTaskReminders(newTask);
      } else {
        final updated = widget.existing!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          priority: _priority,
          status: _status,
          deadline: _deadline!,
          courseId: _selectedCourseId,
        );
        await notifier.updateTask(updated);
        await NotificationService.instance.scheduleTaskReminders(updated);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final courses = coursesAsync.asData?.value ?? [];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;

    return Container(
      margin: const EdgeInsets.only(top: 64),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
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
              Text(
                isEdit ? 'Edit Tugas' : 'Tambah Tugas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul Tugas *',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi / Instruksi',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),

              // Course dropdown
              DropdownButtonFormField<String>(
                value: _selectedCourseId,
                decoration: const InputDecoration(
                  labelText: 'Mata Kuliah *',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: courses
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: c.accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${c.code} — ${c.name}'),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCourseId = v),
                validator: (v) =>
                    v == null ? 'Pilih mata kuliah' : null,
              ),
              const SizedBox(height: 14),

              // Deadline picker
              GestureDetector(
                onTap: _pickDeadline,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _deadline == null
                          ? AppColors.accentBorder
                          : AppColors.primaryBlue,
                      width: _deadline == null ? 1.2 : 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.primaryBlue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _deadline == null
                              ? 'Pilih Tanggal & Jam Tenggat *'
                              : DateFormat('EEEE, dd MMMM yyyy · HH:mm', 'id_ID')
                                  .format(_deadline!),
                          style: TextStyle(
                            color: _deadline == null
                                ? AppColors.textDark.withOpacity(0.5)
                                : AppColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_deadline != null)
                        GestureDetector(
                          onTap: () => setState(() => _deadline = null),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.statusPending),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Priority selector
              const Text('Prioritas',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              Row(
                children: TaskPriority.values.map((p) {
                  final selected = _priority == p;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? _priorityColor(p).withOpacity(0.15)
                                : AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? _priorityColor(p)
                                  : AppColors.accentBorder,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(_priorityIcon(p),
                                  size: 18, color: _priorityColor(p)),
                              const SizedBox(height: 4),
                              Text(
                                p.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _priorityColor(p),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Status selector
              const Text('Status',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              DropdownButtonFormField<TaskStatus>(
                value: _status,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: TaskStatus.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEdit ? 'Simpan Perubahan' : 'Tambahkan Tugas'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return AppColors.priorityLow;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.high:
        return AppColors.priorityHigh;
    }
  }

  IconData _priorityIcon(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return Icons.arrow_downward_rounded;
      case TaskPriority.medium:
        return Icons.remove_rounded;
      case TaskPriority.high:
        return Icons.arrow_upward_rounded;
    }
  }
}
