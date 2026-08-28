import 'dart:async';

import 'notification_service.dart';
import '../observability/app_observability.dart';
import 'plant_service.dart';
import 'reminder_delivery_policy.dart';

/// Connects domain-level plant changes to the platform notification service.
///
/// Reminders are scheduled when plant state is saved, not when the application
/// moves between foreground and background states.
class ReminderCoordinator {
  ReminderCoordinator({
    required this.plantService,
    this.policy = const ReminderDeliveryPolicy(),
    Future<void> Function()? initializeNotifications,
    Future<void> Function(String, List<WateringNotification>)?
    schedulePlantNotifications,
    Future<void> Function(String, List<WateringNotification>)?
    replacePlantNotifications,
    Future<void> Function(String)? cancelPlantNotifications,
  }) : _initializeNotifications =
           initializeNotifications ??
           NotificationService.initializeNotifications,
       _replacePlantNotifications =
           replacePlantNotifications ??
           NotificationService.replaceWateringNotificationsForPlant,
       _schedulePlantNotifications =
           schedulePlantNotifications ??
           NotificationService.scheduleWateringNotificationsForPlant,
       _cancelPlantNotifications =
           cancelPlantNotifications ??
           NotificationService.cancelWateringNotificationsForPlant;

  final PlantService plantService;
  final ReminderDeliveryPolicy policy;
  final Future<void> Function() _initializeNotifications;
  final Future<void> Function(String, List<WateringNotification>)
  _replacePlantNotifications;
  final Future<void> Function(String, List<WateringNotification>)
  _schedulePlantNotifications;
  final Future<void> Function(String) _cancelPlantNotifications;

  StreamSubscription<PlantReminderChange>? _plantChangeSubscription;
  bool _started = false;
  bool _ready = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await appPerformance.measure('startup.reminders.ready', () async {
      _plantChangeSubscription = plantService.reminderChanges.listen(
        _plantReminderChanged,
      );

      await appPerformance.measure(
        'startup.reminders.initialize_delivery',
        _initializeNotifications,
      );
      await plantService.loaded;
      _ready = true;
      await appPerformance.measure(
        'startup.reminders.sync_plants',
        _syncAllPlants,
      );
    });
  }

  void dispose() {
    _ready = false;
    unawaited(_plantChangeSubscription?.cancel());
    _plantChangeSubscription = null;
  }

  void _plantReminderChanged(PlantReminderChange change) {
    if (!_ready) return;
    if (change.isRemoved) {
      unawaited(_cancelPlantNotifications(change.plantId));
      return;
    }
    unawaited(_syncPlant(change.plantId));
  }

  Future<void> _syncAllPlants() async {
    plantService.updateStoreState();
    for (final plant in plantService.plants) {
      await _syncPlant(
        plant.id,
        refreshStoreState: false,
        replaceExisting: false,
      );
    }
  }

  Future<void> _syncPlant(
    String plantId, {
    bool refreshStoreState = true,
    bool replaceExisting = true,
  }) async {
    if (refreshStoreState) plantService.updateStoreState();

    ExpectedWateringTime? reminder;
    for (final candidate in plantService.wateringSchedule) {
      if (candidate.plant.id == plantId) {
        reminder = candidate;
        break;
      }
    }
    if (reminder == null) {
      await _cancelPlantNotifications(plantId);
      return;
    }

    final initialDeliveryTime = policy.initialDeliveryTime(
      reminderTime: reminder.scheduledDateTime,
      now: DateTime.now().toUtc(),
    );
    final notifications = [
      WateringNotification(
        plantId: plantId,
        slot: WateringNotificationSlot.initial,
        deliveryTime: initialDeliveryTime,
        title: reminder.plant.name,
        body: '${reminder.plant.name}: Water me please...',
        timeoutAfter: policy.retryDelay,
      ),
      WateringNotification(
        plantId: plantId,
        slot: WateringNotificationSlot.retry,
        deliveryTime: policy.retryDeliveryTime(initialDeliveryTime),
        title: reminder.plant.name,
        body: '${reminder.plant.name}: Water me please...',
      ),
    ];
    if (replaceExisting) {
      await _replacePlantNotifications(plantId, notifications);
    } else {
      await _schedulePlantNotifications(plantId, notifications);
    }
  }
}
