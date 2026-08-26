import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';
import 'plant_service.dart';
import 'reminder_delivery_policy.dart';

/// Connects derived plant reminders to platform notifications according to
/// application lifecycle. PlantService intentionally remains platform-agnostic.
class ReminderCoordinator with WidgetsBindingObserver {
  ReminderCoordinator({
    required this.plantService,
    this.policy = const ReminderDeliveryPolicy(),
  });

  static const _attemptsKey = 'watering_reminder_attempts';

  final PlantService plantService;
  final ReminderDeliveryPolicy policy;
  bool _isForeground = true;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    plantService.addListener(_plantStateChanged);
    await NotificationService.initializeNotifications();
    await plantService.loaded;
    await _returnToForeground();
  }

  void dispose() {
    if (!_started) return;
    WidgetsBinding.instance.removeObserver(this);
    plantService.removeListener(_plantStateChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isForeground = true;
        unawaited(_returnToForeground());
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (_isForeground) {
          _isForeground = false;
          unawaited(_scheduleForBackground());
        }
      case AppLifecycleState.inactive:
        // Permission dialogs and other temporary interruptions can report
        // inactive without the user actually leaving the app.
        break;
    }
  }

  void _plantStateChanged() {
    if (!_isForeground) unawaited(_scheduleForBackground());
  }

  Future<void> _scheduleForBackground() async {
    await plantService.loaded;
    plantService.updateStoreState();

    final now = DateTime.now();
    final attempts = await _loadAttempts();
    final notifications = <WateringNotification>[];
    final overduePlantIds = <String>{};

    for (final reminder in plantService.wateringSchedule) {
      final lastAttempt = attempts[reminder.plant.id];
      final deliveryTime = policy.deliveryTime(
        reminderTime: reminder.scheduledDateTime,
        now: now,
        lastAttempt: lastAttempt,
      );
      if (deliveryTime == null) continue;

      notifications.add(
        WateringNotification(
          plantId: reminder.plant.id,
          deliveryTime: deliveryTime,
          title: reminder.plant.name,
          body: '${reminder.plant.name}: Water me please...',
        ),
      );
      if (!reminder.scheduledDateTime.isAfter(now)) {
        overduePlantIds.add(reminder.plant.id);
      }
    }

    if (_isForeground) return;
    final scheduledPlantIds =
        await NotificationService.replaceWateringNotifications(notifications);
    // Scheduling crosses platform and preferences boundaries. The user may
    // have resumed while those awaits were running, so enforce foreground
    // cancellation again before recording an attempt.
    if (_isForeground) {
      await NotificationService.cancelWateringNotifications();
      return;
    }
    for (final plantId in scheduledPlantIds.intersection(overduePlantIds)) {
      // Store intended delivery, not background time. Returning during the
      // grace period can then remove an attempt that never reached the user.
      attempts[plantId] = notifications
          .firstWhere((notification) => notification.plantId == plantId)
          .deliveryTime;
    }
    await _saveAttempts(attempts);
  }

  Future<void> _returnToForeground() async {
    await NotificationService.cancelWateringNotifications();
    final attempts = await _loadAttempts();
    final now = DateTime.now();
    attempts.removeWhere(
      // Future timestamps are overdue notifications cancelled during their
      // exit grace period; they must not consume the retry cooldown.
      (_, attemptedDelivery) => attemptedDelivery.isAfter(now),
    );
    await _saveAttempts(attempts);
  }

  Future<Map<String, DateTime>> _loadAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_attemptsKey);
    if (encoded == null) return {};
    final values = jsonDecode(encoded) as Map<String, dynamic>;
    return values.map(
      (id, value) => MapEntry(id, DateTime.parse(value as String)),
    );
  }

  Future<void> _saveAttempts(Map<String, DateTime> attempts) async {
    final activePlantIds = plantService.plants.map((plant) => plant.id).toSet();
    attempts.removeWhere((plantId, _) => !activePlantIds.contains(plantId));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _attemptsKey,
      jsonEncode(
        attempts.map((id, time) => MapEntry(id, time.toIso8601String())),
      ),
    );
  }
}
