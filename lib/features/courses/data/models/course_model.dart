import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/course_entity.dart';

/// Maps between [Course] (Drift data class) and [CourseEntity] (domain).
extension CourseMapper on Course {
  CourseEntity toEntity() {
    return CourseEntity(
      id: id,
      name: name,
      code: code,
      lecturerName: lecturerName,
      accentColor: Color(accentColorValue),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    );
  }
}

extension CourseEntityMapper on CourseEntity {
  CoursesCompanion toCompanion() {
    return CoursesCompanion.insert(
      id: id,
      name: name,
      code: code,
      lecturerName: lecturerName,
      accentColorValue: accentColor.value,
      createdAt: createdAt.millisecondsSinceEpoch,
    );
  }
}

