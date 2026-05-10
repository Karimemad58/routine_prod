import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _supported => !kIsWeb;

  Future<void> init(InitializationSettings settings) async {
    if (!_supported) return;
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> scheduleDailyRoutineReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_supported || !_initialized) return;
    // The `hour` and `minute` are accepted for future precise scheduling but
    // currently the plugin's `periodicallyShow(daily)` cadence is used as a
    // best-effort fallback.
    await _plugin.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.daily,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_daily',
          'Routine Daily',
          channelDescription: 'Daily AM/PM routine reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelAll() async {
    if (!_supported || !_initialized) return;
    await _plugin.cancelAll();
  }
}
