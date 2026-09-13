import 'package:flutter/material.dart';

import '../basic_feature/watering_status_presentation.dart';
import 'settings_service.dart';

/// A class that many Widgets can interact with to read user settings, update
/// user settings, or listen to user settings changes.
///
/// Controllers glue Data Services to Flutter Widgets. The SettingsController
/// uses the SettingsService to store and retrieve user settings.
class SettingsController with ChangeNotifier {
  SettingsController(this._settingsService);

  // Make SettingsService a private variable so it is not used directly.
  final SettingsService _settingsService;

  // Make ThemeMode a private variable so it is not updated directly without
  // also persisting the changes with the SettingsService.
  late ThemeMode _themeMode;
  late PlantListLayout _plantListLayout;
  late WateringStatusPresentation _wateringStatusPresentation;

  // Allow Widgets to read the user's preferred ThemeMode.
  ThemeMode get themeMode => _themeMode;
  PlantListLayout get plantListLayout => _plantListLayout;
  WateringStatusPresentation get wateringStatusPresentation =>
      _wateringStatusPresentation;

  /// Load the user's settings from the SettingsService. It may load from a
  /// local database or the internet. The controller only knows it can load the
  /// settings from the service.
  Future<void> loadSettings() async {
    _themeMode = await _settingsService.themeMode();
    _plantListLayout = await _settingsService.plantListLayout();
    _wateringStatusPresentation = await _settingsService
        .wateringStatusPresentation();

    // Important! Inform listeners a change has occurred.
    notifyListeners();
  }

  /// Update and persist the ThemeMode based on the user's selection.
  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;
    if (newThemeMode == _themeMode) return;

    // store the new ThemeMode in memory
    _themeMode = newThemeMode;
    // Important! Inform listeners a change has occurred.
    notifyListeners();

    // Persist the changes to a local database or the internet using the
    // SettingService.
    await _settingsService.updateThemeMode(newThemeMode);
  }

  Future<void> updatePlantListLayout(PlantListLayout newLayout) async {
    if (newLayout == _plantListLayout) return;

    _plantListLayout = newLayout;
    notifyListeners();
    await _settingsService.updatePlantListLayout(newLayout);
  }

  Future<void> updateWateringStatusPresentation(
    WateringStatusPresentation newPresentation,
  ) async {
    if (newPresentation == _wateringStatusPresentation) return;

    _wateringStatusPresentation = newPresentation;
    notifyListeners();
    await _settingsService.updateWateringStatusPresentation(newPresentation);
  }
}
