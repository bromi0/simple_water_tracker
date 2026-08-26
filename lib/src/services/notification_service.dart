import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:simple_water_tracker/main.dart';
import 'package:simple_water_tracker/src/services/plant_service.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // get static instance from package
  static final _notifications = flutterLocalNotificationsPlugin;
  static bool _notificationsEnabled = false;

  static Future<void> initializeNotifications() async {
    // Only check permissions on non-web platforms
    final granted = await NotificationService.isPermissionsGranted();
    final requested =
        granted ? true : await NotificationService.requestPermissions();

    _notificationsEnabled = requested;
  }

  static Future<void> zonedScheduleNotification({
    required int id,
    required DateTime dt,
    String title = 'default title',
    String body = 'default body',
  }) async {
    if (!_notificationsEnabled) return;
    var futureDate = tz.TZDateTime.from(dt, tz.local);
    if (futureDate.compareTo(tz.TZDateTime.now(tz.local)) <= 0) {
      // print('Got date to schedule in the past: $futureDate');
      return;
    }
    const androidNotificationDetails = AndroidNotificationDetails(
        'mainChannel', 'Water time notifications',
        channelDescription: 'The notifications reminding to water your plants.',
        importance: Importance.high);
    const notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
        id, title, body, futureDate, notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
    // print('Setup scheduled notification for $futureDate');
  }

  static Future<void> setupWaterScheduleNotifications(
      List<ExpectedWateringTime> wateringSchedule) async {
    // print('Clearing schedule.');
    if (!_notificationsEnabled) return;
    flutterLocalNotificationsPlugin.cancelAll();
    var now = DateTime.now();
    for (var i = 0; i < wateringSchedule.length; i++) {
      final note = wateringSchedule[i];
      if (note.scheduledDateTime.compareTo(now) > 0) {
        zonedScheduleNotification(
            id: i,
            dt: note.scheduledDateTime,
            title: note.plant.name,
            body: '${note.plant.name}: Water me please...');
      }
    }
  }

  static Future<bool> isPermissionsGranted() async {
    if (kIsWeb) {
      return false; // Web doesn't support local notifications yet
    }

    return await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) {
      return false; // Web doesn't support local notifications yet
    }

    try {
      final ios = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      final macos = await _notifications
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final android =
          await androidImplementation?.requestNotificationsPermission();

      return ios ?? macos ?? android ?? false;
    } catch (e) {
      // stderr.writeln('Error requesting notifications permission: $e');
      return false;
    }
  }

  static Future<void> debugNotifications() async {
    final List<ActiveNotification> activeNotifications =
        await flutterLocalNotificationsPlugin.getActiveNotifications();
    debugPrint('Active notifications: $activeNotifications');
    final List<PendingNotificationRequest> pendingNotifications =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    debugPrint('Pending notifications: $pendingNotifications');
  }
}
