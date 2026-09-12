import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_service.g.dart';

/// The two supported presentations of the main plant collection.
enum PlantListLayout { rows, grid }

/// A service that stores and retrieves user settings.
///
/// By default, this class does not persist user settings. If you'd like to
/// persist the user settings locally, use the shared_preferences package. If
/// you'd like to store settings on a web server, use the http package.
@JsonSerializable()
class SettingsService {
  static const String dataKey = 'water_plant_appsettings_data_key';
  SettingsService();
  @JsonKey(includeFromJson: true, includeToJson: true)
  ThemeMode _themeMode = ThemeMode.system;
  @JsonKey(
    includeFromJson: true,
    includeToJson: true,
    defaultValue: PlantListLayout.rows,
  )
  PlantListLayout _plantListLayout = PlantListLayout.rows;

  Future<ThemeMode> themeMode() async => _themeMode;

  Future<PlantListLayout> plantListLayout() async => _plantListLayout;

  /// Persists the user's preferred ThemeMode to local or remote storage.
  Future<void> updateThemeMode(ThemeMode theme) async {
    _themeMode = theme;
    _saveSettingsData();
  }

  Future<void> updatePlantListLayout(PlantListLayout layout) async {
    _plantListLayout = layout;
    await _saveSettingsData();
  }

  factory SettingsService.fromJson(Map<String, dynamic> json) =>
      _$SettingsServiceFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsServiceToJson(this);

  static Future<SettingsService> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(dataKey) ?? '';
    if (savedData.isNotEmpty) {
      final decodedData = jsonDecode(savedData) as Map<String, dynamic>;
      return SettingsService.fromJson(decodedData);
    }
    return SettingsService();
  }

  Future<void> _saveSettingsData() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(this);
    await prefs.setString(dataKey, jsonString);
  }
}
