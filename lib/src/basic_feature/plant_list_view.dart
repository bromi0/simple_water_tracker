import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simple_water_tracker/main.dart';

import '../camera/take_picture_screen.dart';
import '../settings/settings_view.dart';
import 'plant_list.dart';

/// Displays a list of SampleItems.
class PlantListView extends StatefulWidget {
  const PlantListView({
    super.key,
  });

  static const routeName = '/';

  @override
  State<PlantListView> createState() => _PlantListViewState();
}

class _PlantListViewState extends State<PlantListView> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _isAndroidPermissionGranted();
    _requestPermissions();
    // _configureDidReceiveLocalNotificationSubject();
    // _configureSelectNotificationSubject();
  }

  Future<void> _isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      final bool granted = await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;

      setState(() {
        _notificationsEnabled = granted;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission();
      setState(() {
        _notificationsEnabled = grantedNotificationPermission ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('How mah plants doin'),
          actions: [
            IconButton(
              icon: const Icon(Icons.punch_clock),
              onPressed: () async {
                // Test local notifications
                // await NotificationService.zonedScheduleNotification();
              },
            ),
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
            // NavigationDestination(
            //   selectedIcon: Icon(Icons.list),
            //   icon: Icon(Icons.list_outlined),
            //   label: 'Journal',
            // ),
          ],
          onDestinationSelected: (int index) async {
            if (index == 1) {
              if (await Permission.camera.request().isGranted) {
                if (context.mounted) {
                  Navigator.pushNamed(context, TakePictureScreen.routeName);
                }
              }
            }
          },
        ));
  }
}
