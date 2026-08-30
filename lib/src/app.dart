import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:simple_water_tracker/src/camera/take_picture_screen.dart';
import 'package:simple_water_tracker/src/localization/app_localizations.dart';

import 'basic_feature/sample_item_details_view.dart';
import 'basic_feature/plant_list_view.dart';
import 'basic_feature/reminder_schedule_view.dart';
import 'observability/app_observability.dart';
import 'services/plant_service.dart';
import 'services/reminder_coordinator.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';

/// The Widget that configures your application.
class SimplyWaterPlantApp extends StatefulWidget {
  const SimplyWaterPlantApp({super.key, required this.settingsController});

  final SettingsController settingsController;

  @override
  State<SimplyWaterPlantApp> createState() => _SimplyWaterPlantAppState();
}

class _SimplyWaterPlantAppState extends State<SimplyWaterPlantApp> {
  // These objects share the app lifecycle: the coordinator observes and
  // schedules from the same PlantService instance exposed to the widgets.
  late final PlantService _plantService;
  late final ReminderCoordinator _reminderCoordinator;

  @override
  void initState() {
    super.initState();
    _plantService = PlantService();
    _reminderCoordinator = ReminderCoordinator(plantService: _plantService);
    _startReminderCoordinator();
  }

  Future<void> _startReminderCoordinator() async {
    try {
      await _reminderCoordinator.start();
    } catch (error, stackTrace) {
      // Notification delivery must not take down an otherwise usable app.
      appLogger.error(
        'reminder_coordinator_start_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void dispose() {
    _reminderCoordinator.dispose();
    _plantService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return ListenableBuilder(
      listenable: widget.settingsController,
      builder: (BuildContext context, Widget? child) {
        return ChangeNotifierProvider.value(
          // The state owns and disposes this existing instance.
          value: _plantService,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            // Providing a restorationScopeId allows the Navigator built by the
            // MaterialApp to restore the navigation stack when a user leaves and
            // returns to the app after it has been killed while running in the
            // background.
            restorationScopeId: 'app',

            // Provide the generated AppLocalizations to the MaterialApp. This
            // allows descendant Widgets to display the correct translations
            // depending on the user's locale.
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English, no country code
            ],

            // Use AppLocalizations to configure the correct application title
            // depending on the user's locale.
            //
            // The appTitle is defined in .arb files found in the localization
            // directory.
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context)!.appTitle,

            // Define a light and dark color theme. Then, read the user's
            // preferred ThemeMode (light, dark, or system default) from the
            // SettingsController to display the correct theme.
            theme: ThemeData(),
            darkTheme: ThemeData.dark(),
            themeMode: widget.settingsController.themeMode,

            // Define a function to handle named routes in order to support
            // Flutter web url navigation and deep linking.
            onGenerateRoute: (RouteSettings routeSettings) {
              return MaterialPageRoute<void>(
                settings: routeSettings,
                builder: (BuildContext context) {
                  switch (routeSettings.name) {
                    case SettingsView.routeName:
                      return SettingsView(
                        controller: widget.settingsController,
                      );
                    case ReminderScheduleView.routeName:
                      return const ReminderScheduleView();
                    case SampleItemDetailsView.routeName:
                      return const SampleItemDetailsView();
                    case TakePictureScreen.routeName:
                      return const TakePictureScreen();
                    case PlantListView.routeName:
                    default:
                      return PlantListView(
                        settingsController: widget.settingsController,
                      );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
