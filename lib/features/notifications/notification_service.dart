
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/constants/app_constants.dart';
import 'package:campus_task/features/tasks/domain/entities/task_entity.dart';

/// Service responsible for scheduling and cancelling local notifications.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Schedules 3 reminder notifications for a task:
  ///  - 72 hours before deadline (H-3 days)
  ///  - 24 hours before deadline (H-1 day)
  ///  -  3 hours before deadline
  Future<void> scheduleTaskReminders(TaskEntity task) async {
    await cancelTaskReminders(task.id);

    final deadlineLocal = tz.TZDateTime.from(task.deadline, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    final offsets = [
      (AppConstants.notifyHours3Days, '3 hari lagi tenggat!'),
      (AppConstants.notifyHours1Day, 'Besok tenggat waktu!'),
      (AppConstants.notifyHours3Hours, '3 jam lagi tenggat waktu!'),
    ];

    for (final (hours, subtitle) in offsets) {
      final scheduledTime =
          deadlineLocal.subtract(Duration(hours: hours));

      // Skip if the scheduled time is already in the past.
      if (scheduledTime.isBefore(now)) continue;

      final notifId = _notifId(task.id, hours);

      await _plugin.zonedSchedule(
        notifId,
        '📚 ${task.title}',
        subtitle,
        scheduledTime,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.id,
      );
    }
  }

  /// Cancels all 3 reminders for the given task.
  Future<void> cancelTaskReminders(String taskId) async {
    for (final hours in [
      AppConstants.notifyHours3Days,
      AppConstants.notifyHours1Day,
      AppConstants.notifyHours3Hours,
    ]) {
      await _plugin.cancel(_notifId(taskId, hours));
    }
  }

  /// Derives a stable integer notification ID from taskId + offset.
  int _notifId(String taskId, int hoursOffset) {
    return (taskId.hashCode.abs() + hoursOffset) % 2147483647;
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
