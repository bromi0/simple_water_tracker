import 'package:flutter/material.dart';

import '../camera/take_picture_screen.dart';
import '../settings/settings_view.dart';
import 'plant_list.dart';

/// Displays a list of SampleItems.
class PlantListView extends StatelessWidget {
  const PlantListView({
    super.key,
  });

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('How mah plants doin'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // Navigate to the settings page. If the user leaves and returns
                // to the app after it has been killed while running in the
                // background, the navigation stack is restored.
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
            NavigationDestination(
              selectedIcon: Icon(Icons.list),
              icon: Icon(Icons.list_outlined),
              label: 'Journal',
            ),
          ],
          onDestinationSelected: (int index) {
            if (index == 1) {
              Navigator.pushNamed(context, TakePictureScreen.routeName);
            }
          },
        ));
  }
}
