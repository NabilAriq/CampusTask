import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/course_entity.dart';
import '../controllers/course_controller.dart';

/// Bottom sheet form for creating or editing a Course.
class CourseFormScreen extends ConsumerStatefulWidget {
  const CourseFormScreen({super.key, this.existing});

  /// If provided, the form pre-fills with existing course data (edit mode).
  final CourseEntity? existing;

  @override
  ConsumerState<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends ConsumerState<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _lecturerCtrl;
  late Color _selectedColor;
  bool _saving = false;

  static const _colorOptions = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFF44336), // Red
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFE91E63), // Pink
    Color(0xFF8BC34A), // Light Green
    Color(0xFF3F51B5), // Indigo
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _codeCtrl = TextEditingController(text: c?.code ?? '');
    _lecturerCtrl = TextEditingController(text: c?.lecturerName ?? '');
    _selectedColor = c?.accentColor ?? _colorOptions.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _lecturerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final notifier = ref.read(courseControllerProvider.notifier);
      if (widget.existing == null) {
        await notifier.addCourse(
          name: _nameCtrl.text.trim(),
          code: _codeCtrl.text.trim().toUpperCase(),
          lecturerName: _lecturerCtrl.text.trim(),
          accentColor: _selectedColor,
        );
      } else {
        await notifier.updateCourse(widget.existing!.copyWith(
          name: _nameCtrl.text.trim(),
          code: _codeCtrl.text.trim().toUpperCase(),
          lecturerName: _lecturerCtrl.text.trim(),
          accentColor: _selectedColor,
        ));
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 64),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                isEdit ? 'Edit Mata Kuliah' : 'Tambah Mata Kuliah',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),

              // Name field
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Mata Kuliah *',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),

              // Code field
              TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kode Mata Kuliah *',
                  prefixIcon: Icon(Icons.tag_rounded),
                  hintText: 'Mis: CS101',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Kode wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // Lecturer field
              TextFormField(
                controller: _lecturerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Dosen *',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama dosen wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // Color picker
              const Text(
                'Warna Label',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colorOptions.map((color) {
                  final selected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(
                                color: AppColors.textDark, width: 2.5)
                            : null,
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Submit button
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEdit ? 'Simpan Perubahan' : 'Tambahkan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

