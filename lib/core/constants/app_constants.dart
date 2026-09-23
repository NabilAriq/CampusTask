abstract final class AppConstants {
  // ── Route names ────────────────────────────────────────────────────────
  static const String routeCourseList = '/';
  static const String routeCourseForm = '/courses/form';
  static const String routeTaskList = '/tasks';
  static const String routeTaskForm = '/tasks/form';
  static const String routeTaskDetail = '/tasks/detail';

  // ── Notification channel ──────────────────────────────────────────────
  static const String notificationChannelId = 'campus_task_reminders';
  static const String notificationChannelName = 'Task Reminders';
  static const String notificationChannelDesc =
      'Scheduled reminders for upcoming task deadlines';

  // ── Notification offsets (in hours before deadline) ───────────────────
  static const int notifyHours3Days = 72;
  static const int notifyHours1Day = 24;
  static const int notifyHours3Hours = 3;

  // ── Misc ───────────────────────────────────────────────────────────────
  static const int maxCourseColorOptions = 12;
  static const String dbName = 'campus_task.db';
}

