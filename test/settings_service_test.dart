import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_water_tracker/src/settings/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('old settings default to the one-column plant layout', () async {
    final settings = SettingsService.fromJson({'_themeMode': 'dark'});

    expect(await settings.themeMode(), ThemeMode.dark);
    expect(await settings.plantListLayout(), PlantListLayout.rows);
  });

  test('plant list layout is persisted with the other settings', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();

    await settings.updatePlantListLayout(PlantListLayout.grid);
    final reloaded = await SettingsService.loadFromPrefs();

    expect(await reloaded.plantListLayout(), PlantListLayout.grid);
  });
}
