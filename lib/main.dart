import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/app.dart';
import 'src/services/notification_service.dart';
import 'src/services/package_replacement_recovery.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

const _notificationRecoveryChannel = MethodChannel(
  'com.bromiapps.simplywaterplant/notification_recovery',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Camera init
  // final cameras = await availableCameras();
  // final firstCamera = cameras.first;

  await NotificationService.configurePlatformNotifications();

  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  final settingsController = SettingsController(
    await SettingsService.loadFromPrefs(),
  );

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(
    SimplyWaterPlantApp(
      settingsController: settingsController,
      // mainCamera: firstCamera,
    ),
  );
}

/// Rebuilds watering reminders after Android removes posted notifications
/// while replacing the package. Android starts this entry point in a headless
/// Flutter engine; it never creates the application widget tree.
@pragma('vm:entry-point')
Future<void> notificationRecoveryMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? failure;
  StackTrace? failureStack;
  try {
    await restoreWateringRemindersAfterPackageReplacement();
  } catch (error, stackTrace) {
    failure = error;
    failureStack = stackTrace;
    debugPrint('Package replacement reminder recovery failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  try {
    await _notificationRecoveryChannel.invokeMethod<void>('complete', {
      'success': failure == null,
      if (failure != null) 'error': failure.toString(),
      if (failureStack != null) 'stackTrace': failureStack.toString(),
    });
  } catch (error, stackTrace) {
    // The native receiver may have timed out. There is no UI isolate to report
    // through, so leave a diagnostic in logcat and allow this isolate to end.
    debugPrint('Could not report reminder recovery completion: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
