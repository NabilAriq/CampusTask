import 'package:flutter/material.dart';

/// Centralized color palette for CampusTask.
/// All colors follow the PRD monochromatic blue design system.
abstract final class AppColors {
  /// #E3F2FD — Scaffold background and secondary surfaces
  static const Color backgroundLight = Color(0xFFE3F2FD);

  /// #90CAF9 — Card borders, dividers, and neutral badges
  static const Color accentBorder = Color(0xFF90CAF9);

  /// #2196F3 — Primary CTA: FAB, buttons, progress bars, active status
  static const Color primaryBlue = Color(0xFF2196F3);

  /// #0D47A1 — AppBar titles, task names, high-priority text
  static const Color textDark = Color(0xFF0D47A1);

  /// #FFFFFF — Card surfaces, input field containers
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // ── Derived semantic colors ──────────────────────────────────────────────

  /// Low priority indicator — soft green
  static const Color priorityLow = Color(0xFF4CAF50);

  /// Medium priority indicator — amber
  static const Color priorityMedium = Color(0xFFFFC107);

  /// High priority indicator — deep red
  static const Color priorityHigh = Color(0xFFF44336);

  /// Status: pending
  static const Color statusPending = Color(0xFF9E9E9E);

  /// Status: in progress
  static const Color statusInProgress = Color(0xFF2196F3);

  /// Status: completed
  static const Color statusCompleted = Color(0xFF4CAF50);
}

