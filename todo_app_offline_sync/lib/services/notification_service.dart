import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

/// Service for managing local push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Callback for handling notification taps
  Function(String taskId)? onNotificationTap;

  /// Initialize the notification plugin with Android configuration
  Future<void> initialize() async {
    if (_initialized) return;

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings (for future iOS support)
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Request notification permissions for Android 13+
    await _requestPermissions();

    // Set up notification channels for Android
    await _setupNotificationChannels();

    _initialized = true;
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Set up notification channels for Android
  Future<void> _setupNotificationChannels() async {
    const androidChannel = AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Notifications for upcoming task due dates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }
  }

  /// Handle notification tap
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && onNotificationTap != null) {
      // Payload contains the task ID
      onNotificationTap!(payload);
    }
  }

  /// Schedule a notification for a task with due date
  /// Schedules notification 1 hour before due date if due date is within 24 hours
  Future<void> scheduleNotification(Task task) async {
    if (!_initialized) {
      await initialize();
    }

    // Only schedule if task has a due date
    if (task.dueDate == null) return;

    final now = DateTime.now();
    final dueDate = task.dueDate!;

    // Check if due date is within 24 hours
    final timeUntilDue = dueDate.difference(now);
    if (timeUntilDue.inHours < 0 || timeUntilDue.inHours > 24) {
      // Don't schedule if due date is in the past or more than 24 hours away
      return;
    }

    // Schedule notification 1 hour before due date
    final notificationTime = dueDate.subtract(const Duration(hours: 1));

    // Don't schedule if notification time is in the past
    if (notificationTime.isBefore(now)) {
      return;
    }

    // Convert to timezone-aware datetime
    final scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);

    // Create notification details
    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for upcoming task due dates',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule the notification
    // Use task ID hash code as notification ID
    final notificationId = task.id.hashCode;

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Task Due Soon',
      task.title,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id, // Pass task ID as payload for navigation
    );
  }

  /// Cancel notification for a specific task
  Future<void> cancelNotification(String taskId) async {
    if (!_initialized) {
      await initialize();
    }

    // Use task ID hash code as notification ID (same as in scheduleNotification)
    final notificationId = taskId.hashCode;
    await _notificationsPlugin.cancel(notificationId);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_initialized) {
      await initialize();
    }

    await _notificationsPlugin.cancelAll();
  }

  /// Check if a notification is scheduled for a task
  Future<bool> isNotificationScheduled(String taskId) async {
    if (!_initialized) {
      await initialize();
    }

    final pendingNotifications =
        await _notificationsPlugin.pendingNotificationRequests();
    final notificationId = taskId.hashCode;

    return pendingNotifications
        .any((notification) => notification.id == notificationId);
  }
}
