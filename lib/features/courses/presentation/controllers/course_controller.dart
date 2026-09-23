import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/repositories/course_repository.dart';
import '../../domain/entities/course_entity.dart';

// ── Database provider ────────────────────────────────────────────────────────

/// Provides the singleton [AppDatabase] instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── Repository providers ─────────────────────────────────────────────────────

/// Provides the [CourseRepository] backed by Drift.
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return DriftCourseRepository(ref.watch(appDatabaseProvider));
});

// ── Stream providers ─────────────────────────────────────────────────────────

/// Watches all courses as a reactive stream.
final coursesProvider = StreamProvider<List<CourseEntity>>((ref) {
  return ref.watch(courseRepositoryProvider).watchAllCourses();
});

// ── Controller ───────────────────────────────────────────────────────────────

/// State notifier for course mutations (add, update, delete).
class CourseController extends AsyncNotifier<List<CourseEntity>> {
  CourseRepository get _repo => ref.read(courseRepositoryProvider);

  @override
  Future<List<CourseEntity>> build() async {
    return _repo.getAllCourses();
  }

  Future<void> addCourse({
    required String name,
    required String code,
    required String lecturerName,
    required Color accentColor,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.addCourse(
        name: name,
        code: code,
        lecturerName: lecturerName,
        accentColor: accentColor,
      );
      return _repo.getAllCourses();
    });
  }

  Future<void> updateCourse(CourseEntity course) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.updateCourse(course);
      return _repo.getAllCourses();
    });
  }

  Future<void> deleteCourse(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.deleteCourse(id);
      return _repo.getAllCourses();
    });
  }
}

final courseControllerProvider =
    AsyncNotifierProvider<CourseController, List<CourseEntity>>(
  CourseController.new,
);

