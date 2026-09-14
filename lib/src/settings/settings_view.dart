import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/reminder_coordinator.dart';
import '../basic_feature/watering_status_presentation.dart';
import 'notification_settings.dart';
import 'settings_controller.dart';
import '../localization/app_localizations.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Selecting English while the system is English still changes the choice.
    final selectedLocale = context.select<SettingsController, Locale?>(
      (settings) => settings.locale,
    );
    final reminders = context.read<ReminderCoordinator>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.language, style: Theme.of(context).textTheme.titleMedium),
          DropdownButton<String>(
            isExpanded: true,
            itemHeight: null,
            value: selectedLocale?.toLanguageTag() ?? 'system',
            onChanged: (value) {
              if (value == null) return;
              controller.updateLocale(value == 'system' ? null : Locale(value));
            },
            items: [
              DropdownMenuItem(
                value: 'system',
                child: Text(l10n.systemLanguage),
              ),
              DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
              DropdownMenuItem(value: 'ru', child: Text(l10n.languageRussian)),
            ],
          ),
          const SizedBox(height: 24),
          DropdownButton<ThemeMode>(
            isExpanded: true,
            itemHeight: null,
            value: controller.themeMode,
            onChanged: controller.updateThemeMode,
            items: [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text(l10n.systemTheme),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text(l10n.lightTheme),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text(l10n.darkTheme),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.wateringStatus,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.wateringStatusHelp,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          SegmentedButton<WateringStatusPresentation>(
            segments: [
              ButtonSegment(
                value: WateringStatusPresentation.simple,
                label: Text(l10n.simpleStatus),
              ),
              ButtonSegment(
                value: WateringStatusPresentation.informative,
                label: Text(l10n.informativeStatus),
              ),
            ],
            selected: {controller.wateringStatusPresentation},
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            onSelectionChanged: (selected) =>
                controller.updateWateringStatusPresentation(selected.first),
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
