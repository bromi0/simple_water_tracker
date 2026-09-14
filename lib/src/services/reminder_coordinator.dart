import 'dart:async';

import 'notification_service.dart';
import '../localization/app_localizations.dart';
import '../localization/app_localizations_loader.dart';
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
    Future<bool> Function()? requestPermissions,
    Future<bool> Function()? readPermissions,
    Future<bool> Function(AppLocalizations)? scheduleTestNotification,
    Future<AppLocalizations> Function()? loadLocalizations,
    Future<void> Function(String, List<WateringNotification>)?
    schedulePlantNotifications,
    Future<void> Function(String, List<WateringNotification>)?
    replacePlantNotifications,
    Future<void> Function(String)? cancelPlantNotifications,
  }) : _readPermissions =
           readPermissions ?? NotificationService.isPermissionsGranted,
       _requestPermissions =
           requestPermissions ?? NotificationService.requestPermissions,
       _scheduleTestNotification =
           scheduleTestNotification ??
           NotificationService.scheduleTestNotification,
       _loadLocalizations = loadLocalizations ?? loadAppLocalizations,
       _initializeNotifications =
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
  final Future<bool> Function() _readPermissions;
  final Future<bool> Function() _requestPermissions;
  bool _permissionGranted = false;
  final Future<bool> Function(AppLocalizations) _scheduleTestNotification;
  final Future<AppLocalizations> Function() _loadLocalizations;
  Future<void>? _start;
  Future<void> _pending = Future.value();
  bool _disposed = false;

  Future<void> start() {
    if (_disposed) return Future.value();
    return _start ??= _begin().onError((Object error, StackTrace stack) {
      _start = null;
      Error.throwWithStackTrace(error, stack);
    });
  }

  Future<void> _begin() {
    final startup = _enqueue(() async {
      await appPerformance.measure('startup.reminders.ready', () async {
        await appPerformance.measure(
          'startup.reminders.initialize_delivery',
          _initializeNotifications,
        );
        _permissionGranted = await _readPermissions();
        await plantService.loaded;
        if (_disposed) return;
        await appPerformance.measure(
          'startup.reminders.sync_plants',
          _syncAllPlants,
        );
      });
    });
    _plantChangeSubscription ??= plantService.reminderChanges.listen(
      _plantReminderChanged,
    );
    return startup;
  }

  // Keep a recovered tail so one platform failure cannot poison later work.
  // The returned future still reports failure to explicit callers.
  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        appLogger.error(
          'reminder_reconciliation_failed',
          error: error,
          stackTrace: stack,
        );
      },
    );
    return result;
  }

  /// Completes after work already submitted to this coordinator has settled.
  Future<void> get settled => _pending;

  void dispose() {
    _disposed = true;
    unawaited(_plantChangeSubscription?.cancel());
    _plantChangeSubscription = null;
  }

  void _plantReminderChanged(PlantReminderChange change) {
    unawaited(
      _enqueue(() async {
        if (_disposed) return;
        // Read current plant state when this operation runs, even for a removal.
        await _syncPlant(change.plantId);
      }).catchError((Object _) {}),
    );
  }

  /// OS status is refreshed without prompting. Only newly enabled delivery
  /// reconciles here; ordinary foreground transitions do not move reminders.
  Future<bool> refreshNotificationPermission() =>
      _updatePermission(_readPermissions);

  Future<bool> requestNotificationsPermission() =>
      _updatePermission(_requestPermissions);

  Future<bool> _updatePermission(Future<bool> Function() readOrRequest) async {
    await start();
    return _enqueue(() async {
      if (_disposed) return false;
      final granted = await readOrRequest();
      if (_disposed) return false;
      if (granted && !_permissionGranted) await _syncAllPlants();
      // A failed reconciliation remains retryable on the next explicit action.
      _permissionGranted = granted;
      return granted;
    });
  }

  Future<bool> scheduleTestNotification() async {
    if (!await requestNotificationsPermission()) return false;
    return _scheduleTestNotification(await _loadLocalizations());
  }

  Future<void> _syncAllPlants() async {
    plantService.updateStoreState();
    for (final plantId
        in plantService.plants.map((plant) => plant.id).toList()) {
      if (_disposed) return;
      await _syncPlant(
        plantId,
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
    final l10n = await _loadLocalizations();
    final notifications = [
      WateringNotification(
        plantId: plantId,
        slot: WateringNotificationSlot.initial,
        deliveryTime: initialDeliveryTime,
        title: l10n.wateringNotificationTitle(reminder.plant.name),
        body: l10n.wateringNotificationBody,
        channelName: l10n.notificationChannelName,
        channelDescription: l10n.notificationChannelDescription,
        timeoutAfter: policy.retryDelay,
      ),
      WateringNotification(
        plantId: plantId,
        slot: WateringNotificationSlot.retry,
        deliveryTime: policy.retryDeliveryTime(initialDeliveryTime),
        title: l10n.wateringNotificationTitle(reminder.plant.name),
        body: l10n.wateringNotificationBody,
        channelName: l10n.notificationChannelName,
        channelDescription: l10n.notificationChannelDescription,
      ),
    ];
    if (replaceExisting) {
      await _replacePlantNotifications(plantId, notifications);
    } else {
      await _schedulePlantNotifications(plantId, notifications);
    }
  }
}
