import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// On-device local notifications (demo-mode).
///
/// Used for: tutor alerts (course enrollment, 1v1 booking requests),
/// 1v1 session reminder alarms (15 min before, both sides), task reminders.
///
/// [BACKEND] wiring point: replace the body of [notifyNow]/[scheduleAt]
/// with FCM/APNs delivery when the real backend exists. The call sites in
/// the tutor and planner features do not need to change.
class NotifyService {
  NotifyService._();

  static final NotifyService instance = NotifyService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  int _nextId = 1;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'lurniq_reminders',
          'Reminders',
          description: 'Session alarms, booking alerts and task reminders.',
          importance: Importance.high,
        ));
    _ready = true;
  }

  /// Asks for the runtime notification permission (Android 13+). Safe to
  /// call repeatedly; returns true when allowed.
  Future<bool> requestPermission() async {
    try {
      await init();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    } catch (e) {
      debugPrint('NotifyService.requestPermission failed: $e');
      return false;
    }
  }

  Future<void> notifyNow({
    required String title,
    required String body,
  }) async {
    try {
      await init();
      await _plugin.show(
        _nextId++,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'lurniq_reminders',
            'Reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      debugPrint('NotifyService.notifyNow failed: $e');
    }
  }

  /// Schedules a one-shot alarm at [at] (local time). Returns the
  /// notification id, or null if scheduling failed.
  Future<int?> scheduleAt({
    required DateTime at,
    required String title,
    required String body,
  }) async {
    try {
      await init();
      if (at.isBefore(DateTime.now().add(const Duration(seconds: 5)))) {
        return null;
      }
      final id = _nextId++;
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(at, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'lurniq_reminders',
            'Reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
      );
      return id;
    } catch (e) {
      debugPrint('NotifyService.scheduleAt failed: $e');
      return null;
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('NotifyService.cancel failed: $e');
    }
  }
}
