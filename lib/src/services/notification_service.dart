import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../observability/app_observability.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static const _legacyWateringIdsKey = 'watering_notification_ids';
  static bool _notificationsEnabled = false;
  static Future<void>? _platformConfiguration;

  /// Configures the platform plugin before any reminder reconciliation.
  ///
  /// This is deliberately independent of the widget tree so Android package
  /// replacement recovery can run it in a headless Flutter engine.
  static Future<void> configurePlatformNotifications() {
    return _platformConfiguration ??= appPerformance.measure(
      'startup.notifications.configure',
      _configurePlatformNotifications,
    );
  }

  static Future<void> _configurePlatformNotifications() async {
    if (kIsWeb || !Platform.isAndroid) return;

    appPerformance.measureSync(
      'startup.notifications.timezone_database',
      tz_data.initializeTimeZones,
    );
    final timeZone = await appPerformance.measure(
      'startup.notifications.device_timezone',
      FlutterTimezone.getLocalTimezone,
    );
    appPerformance.measureSync(
      'startup.notifications.set_timezone',
      () => tz.setLocalLocation(tz.getLocation(timeZone.identifier)),
    );

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('notification_icon'),
    );
    await appPerformance.measure(
      'startup.notifications.plugin',
      () => _notifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _notificationResponseReceived,
      ),
    );
  }

  static void _notificationResponseReceived(NotificationResponse response) {
    switch (response.notificationResponseType) {
      case NotificationResponseType.selectedNotification:
      case NotificationResponseType.selectedNotificationAction:
        break;
      case NotificationResponseType.notificationDismissed:
        // Dismissal is neutral: only watering a plant changes its state.
        break;
    }
  }

  static Future<void> initializeNotifications() async {
    await configurePlatformNotifications();
    await _cancelLegacyWateringNotifications();
    _notificationsEnabled = await isPermissionsGranted();
  }

  static Future<bool> zonedScheduleNotification({
    required int id,
    required DateTime dt,
    String title = 'default title',
    String body = 'default body',
    Duration? timeoutAfter,
  }) async {
    if (!_notificationsEnabled) return false;
    var futureDate = tz.TZDateTime.from(dt, tz.local);
    if (futureDate.compareTo(tz.TZDateTime.now(tz.local)) <= 0) {
      // print('Got date to schedule in the past: $futureDate');
      return false;
    }
    final androidNotificationDetails = AndroidNotificationDetails(
      'mainChannel',
      'Water time notifications',
      channelDescription: 'The notifications reminding to water your plants.',
      importance: Importance.high,
      timeoutAfter: timeoutAfter?.inMilliseconds,
    );
    final notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: futureDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return true;
  }

  static Future<void> replaceWateringNotificationsForPlant(
    String plantId,
    List<WateringNotification> notifications,
  ) async {
    await cancelWateringNotificationsForPlant(plantId);
    await scheduleWateringNotificationsForPlant(plantId, notifications);
  }

  /// Updates a plant's pending alarm slots without clearing an active alert.
  /// This is used on app start, when unchanged reminders should remain visible.
  static Future<void> scheduleWateringNotificationsForPlant(
    String plantId,
    List<WateringNotification> notifications,
  ) async {
    if (!_notificationsEnabled) return;
    for (final note in notifications) {
      await zonedScheduleNotification(
        id: _notificationId(note.plantId, note.slot),
        dt: note.deliveryTime,
        title: note.title,
        body: note.body,
        timeoutAfter: note.timeoutAfter,
      );
    }
  }

  static Future<void> cancelWateringNotificationsForPlant(
    String plantId,
  ) async {
    for (final slot in WateringNotificationSlot.values) {
      await _notifications.cancel(id: _notificationId(plantId, slot));
    }
  }

  static Future<void> _cancelLegacyWateringNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_legacyWateringIdsKey) ?? const [];
    for (final id in ids) {
      await _notifications.cancel(id: int.parse(id));
    }
    await prefs.remove(_legacyWateringIdsKey);
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

  static int _notificationId(String plantId, WateringNotificationSlot slot) {
    // A stable plant ID gives the platform one replaceable notification slot
    // per plant instead of tying IDs to the current list order.
    var hash = 0;
    for (final codeUnit in plantId.codeUnits) {
      hash = 0x1fffffff & (hash * 31 + codeUnit);
    }
    if (slot == WateringNotificationSlot.initial) return hash;
    return 0x1fffffff & (hash * 31 + slot.index);
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
    final List<ActiveNotification> activeNotifications = await _notifications
        .getActiveNotifications();
    debugPrint('Active notifications: $activeNotifications');
    final List<PendingNotificationRequest> pendingNotifications =
        await _notifications.pendingNotificationRequests();
    debugPrint('Pending notifications: $pendingNotifications');
  }
}

class WateringNotification {
  const WateringNotification({
    required this.plantId,
    required this.slot,
    required this.deliveryTime,
    required this.title,
    required this.body,
    this.timeoutAfter,
  });

  final String plantId;
  final WateringNotificationSlot slot;
  final DateTime deliveryTime;
  final String title;
  final String body;
  final Duration? timeoutAfter;
}

enum WateringNotificationSlot { initial, retry }
