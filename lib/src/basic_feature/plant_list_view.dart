import 'package:flutter/material.dart';

import '../camera/take_picture_screen.dart';
import '../settings/settings_view.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_service.dart';
import 'plant_list.dart';
import 'reminder_schedule_view.dart';

/// Hosts the plant collection, view toggle, and main-screen navigation.
class PlantListView extends StatelessWidget {
  const PlantListView({super.key, required this.settingsController});

  final SettingsController settingsController;

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plants'),
        actions: [
          IconButton(
            icon: Icon(
              settingsController.plantListLayout == PlantListLayout.rows
                  ? Icons.grid_view_rounded
                  : Icons.view_agenda_outlined,
            ),
            tooltip: settingsController.plantListLayout == PlantListLayout.rows
                ? 'Use two-column view'
                : 'Use one-column view',
            onPressed: () {
              final nextLayout =
                  settingsController.plantListLayout == PlantListLayout.rows
                  ? PlantListLayout.grid
                  : PlantListLayout.rows;
              settingsController.updatePlantListLayout(nextLayout);
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Watering schedule',
            onPressed: () {
              Navigator.pushNamed(context, ReminderScheduleView.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              // Use a restorable route so Android can restore this navigation
              // stack after reclaiming the app in the background.
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: PlantList(
        layout: settingsController.plantListLayout,
        onAddPlant: () {
          Navigator.pushNamed(context, TakePictureScreen.routeName);
        },
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.room),
            icon: Icon(Icons.room_outlined),
            label: 'Rooms',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.camera_roll),
            icon: Icon(Icons.camera_roll_outlined),
            label: 'Add Plant',
          ),
        ],
        onDestinationSelected: (int index) {
          if (index == 1) {
            Navigator.pushNamed(context, TakePictureScreen.routeName);
          }
        },
      ),
    );
  }
}
