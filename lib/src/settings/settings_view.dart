import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/reminder_coordinator.dart';
import 'notification_settings.dart';
import 'settings_controller.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final reminders = context.read<ReminderCoordinator>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButton<ThemeMode>(
            value: controller.themeMode,
            onChanged: controller.updateThemeMode,
            items: const [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('System Theme'),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Light Theme'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark Theme'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          NotificationSettings(
            refreshPermission: reminders.refreshNotificationPermission,
            requestPermission: reminders.requestNotificationsPermission,
          ),
        ],
      ),
    );
  }
}
