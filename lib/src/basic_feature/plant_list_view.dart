import 'package:flutter/material.dart';

import '../camera/take_picture_screen.dart';
import '../settings/settings_view.dart';
import 'plant_list.dart';
import 'reminder_schedule_view.dart';

class PlantListView extends StatelessWidget {
  const PlantListView({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How mah plants doin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Watering schedule',
            onPressed: () {
              Navigator.pushNamed(context, ReminderScheduleView.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Use a restorable route so Android can restore this navigation
              // stack after reclaiming the app in the background.
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: const PlantList(),
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
