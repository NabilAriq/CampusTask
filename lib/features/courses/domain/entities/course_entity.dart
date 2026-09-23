import 'package:flutter/material.dart';

/// Pure domain entity for a Course.
/// This is framework-independent and lives in the domain layer.
class CourseEntity {
  const CourseEntity({
    required this.id,
    required this.name,
    required this.code,
    required this.lecturerName,
    required this.accentColor,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String code;
  final String lecturerName;
  final Color accentColor;
  final DateTime createdAt;

  CourseEntity copyWith({
    String? id,
    String? name,
    String? code,
    String? lecturerName,
    Color? accentColor,
    DateTime? createdAt,
  }) {
    return CourseEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      lecturerName: lecturerName ?? this.lecturerName,
      accentColor: accentColor ?? this.accentColor,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CourseEntity(id: $id, name: $name, code: $code)';
}

