import 'notification_service.dart';
import '../localization/app_localizations_loader.dart';
import 'plant_service.dart';
import 'reminder_coordinator.dart';
import '../settings/settings_service.dart';

/// Recalculates the desired Android reminders from persisted plant state.
///
/// Android invokes this without an Activity after replacing the package.
/// This is the sole package-replacement recovery path; the notification
/// plugin restores its cached pending alarms only after device boot.
Future<void> restoreWateringRemindersAfterPackageReplacement({
  Future<void> Function()? configurePlatformNotifications,
  PlantService Function()? createPlantService,
  ReminderCoordinator Function(PlantService)? createReminderCoordinator,
}) async {
  await (configurePlatformNotifications ??
      NotificationService.configurePlatformNotifications)();

  final plantService = (createPlantService ?? PlantService.new)();
  final settings = await SettingsService.loadFromPrefs();
  final coordinatorFactory =
      createReminderCoordinator ??
      (service) => ReminderCoordinator(
        plantService: service,
        loadLocalizations: () async => loadAppLocalizations(
          locale: localeForLanguageTag(await settings.localeTag()),
        ),
      );
  final coordinator = coordinatorFactory(plantService);
  try {
    await coordinator.start();
  } finally {
    coordinator.dispose();
    plantService.dispose();
  }
}
