import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:simple_water_tracker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // get static instance from package
  static final _notifications = flutterLocalNotificationsPlugin;
  static const _wateringIdsKey = 'watering_notification_ids';
  static bool _notificationsEnabled = false;
  static final Set<int> _wateringNotificationIds = {};

  static Future<void> initializeNotifications() async {
    _notificationsEnabled = await isPermissionsGranted();
  }

  static Future<bool> zonedScheduleNotification({
    required int id,
    required DateTime dt,
    String title = 'default title',
    String body = 'default body',
  }) async {
    if (!_notificationsEnabled) return false;
    var futureDate = tz.TZDateTime.from(dt, tz.local);
    if (futureDate.compareTo(tz.TZDateTime.now(tz.local)) <= 0) {
      // print('Got date to schedule in the past: $futureDate');
      return false;
    }
    const androidNotificationDetails = AndroidNotificationDetails(
      'mainChannel',
      'Water time notifications',
      channelDescription: 'The notifications reminding to water your plants.',
      importance: Importance.high,
    );
    const notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: futureDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return true;
  }

  static Future<Set<String>> replaceWateringNotifications(
    List<WateringNotification> notifications,
  ) async {
    // Accept the complete desired set. This boundary can later compose several
    // plants into morning or room summaries without changing PlantService.
    await cancelWateringNotifications();
    if (!_notificationsEnabled) return {};
    final scheduledPlantIds = <String>{};
    for (final note in notifications) {
      final id = _notificationId(note.plantId);
      final scheduled = await zonedScheduleNotification(
        id: id,
        dt: note.deliveryTime,
        title: note.title,
        body: note.body,
      );
      if (scheduled) {
        _wateringNotificationIds.add(id);
        scheduledPlantIds.add(note.plantId);
      }
    }
    await _saveWateringNotificationIds();
    return scheduledPlantIds;
  }

  static Future<void> cancelWateringNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    // Persist IDs because Android notifications outlive the Dart process. This
    // also keeps the independent test notification outside bulk cancellation.
    _wateringNotificationIds.addAll(
      prefs.getStringList(_wateringIdsKey)?.map(int.parse) ?? const [],
    );
    for (final id in _wateringNotificationIds) {
      await flutterLocalNotificationsPlugin.cancel(id: id);
    }
    _wateringNotificationIds.clear();
    await prefs.remove(_wateringIdsKey);
  }

  static Future<void> _saveWateringNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _wateringIdsKey,
      _wateringNotificationIds.map((id) => id.toString()).toList(),
    );
  }

  static Future<bool> isPermissionsGranted() async {
    if (kIsWeb) {
      return false; // Web doesn't support local notifications yet
    }

    return await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled() ??
        false;
  }

  static int _notificationId(String plantId) {
    // A stable plant ID gives the platform one replaceable notification slot
    // per plant instead of tying IDs to the current list order.
    var hash = 0;
    for (final codeUnit in plantId.codeUnits) {
      hash = 0x1fffffff & (hash * 31 + codeUnit);
    }
    return hash;
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) {
      return false; // Web doesn't support local notifications yet
    }

    try {
      final ios = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      final macos = await _notifications
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final android = await androidImplementation
          ?.requestNotificationsPermission();

      _notificationsEnabled = ios ?? macos ?? android ?? false;
      return _notificationsEnabled;
    } catch (e) {
      // stderr.writeln('Error requesting notifications permission: $e');
      return false;
    }
  }

  static Future<bool> scheduleTestNotification() async {
    if (!_notificationsEnabled && !await requestPermissions()) return false;
    return zonedScheduleNotification(
      id: 999,
      dt: DateTime.now().add(const Duration(minutes: 1)),
      title: 'Watering reminder test',
      body: 'Notifications are working.',
    );
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

class WateringNotification {
  const WateringNotification({
    required this.plantId,
    required this.deliveryTime,
    required this.title,
    required this.body,
  });

  final String plantId;
  final DateTime deliveryTime;
  final String title;
  final String body;
}
