import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/course_entity.dart';
import '../models/course_model.dart';

/// Abstract contract for course persistence operations.
abstract class CourseRepository {
  Stream<List<CourseEntity>> watchAllCourses();
  Future<List<CourseEntity>> getAllCourses();
  Future<CourseEntity?> getCourseById(String id);
  Future<void> addCourse({
    required String name,
    required String code,
    required String lecturerName,
    required Color accentColor,
  });
  Future<void> updateCourse(CourseEntity course);
  Future<void> deleteCourse(String id);
}

/// Drift-backed implementation of [CourseRepository].
class DriftCourseRepository implements CourseRepository {
  const DriftCourseRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  @override
  Stream<List<CourseEntity>> watchAllCourses() =>
      _db.watchAllCourses().map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Future<List<CourseEntity>> getAllCourses() async {
    final rows = await _db.getAllCourses();
    return rows.map((r) => r.toEntity()).toList();
  }

  @override
  Future<CourseEntity?> getCourseById(String id) async {
    final row = await _db.getCourseById(id);
    return row?.toEntity();
  }

  @override
  Future<void> addCourse({
    required String name,
    required String code,
    required String lecturerName,
    required Color accentColor,
  }) async {
    final entity = CourseEntity(
      id: _uuid.v4(),
      name: name,
      code: code,
      lecturerName: lecturerName,
      accentColor: accentColor,
      createdAt: DateTime.now(),
    );
    await _db.insertCourse(entity.toCompanion());
  }

  @override
  Future<void> updateCourse(CourseEntity course) async {
    await _db.updateCourse(course.toCompanion());
  }

  @override
  Future<void> deleteCourse(String id) async {
    await _db.deleteCourse(id);
  }
}

