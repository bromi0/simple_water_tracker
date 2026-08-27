import 'notification_service.dart';
import 'plant_service.dart';
import 'reminder_coordinator.dart';

/// Recalculates the desired Android reminders from persisted plant state.
///
/// Android invokes this without an Activity after replacing the package.
/// Stable notification IDs make the operation idempotent with both normal app
/// startup and the notification plugin's own pending-alarm restoration.
Future<void> restoreWateringRemindersAfterPackageReplacement({
  Future<void> Function()? configurePlatformNotifications,
  PlantService Function()? createPlantService,
  ReminderCoordinator Function(PlantService)? createReminderCoordinator,
}) async {
  await (configurePlatformNotifications ??
      NotificationService.configurePlatformNotifications)();

  final plantService = (createPlantService ?? PlantService.new)();
  final coordinatorFactory =
      createReminderCoordinator ??
      (service) => ReminderCoordinator(plantService: service);
  final coordinator = coordinatorFactory(plantService);
  try {
    await coordinator.start();
  } finally {
    coordinator.dispose();
    plantService.dispose();
  }
}
