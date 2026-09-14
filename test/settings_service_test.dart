import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_water_tracker/src/basic_feature/watering_status_presentation.dart';
import 'package:simple_water_tracker/src/settings/settings_service.dart';
import 'package:simple_water_tracker/src/settings/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('language choice restores and can return to system default', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = SettingsController(SettingsService());
    await controller.loadSettings();
    expect(controller.locale, isNull);
    await controller.updateLocale(const Locale('ru'));
    final restored = SettingsController(await SettingsService.loadFromPrefs());
    await restored.loadSettings();
    expect(restored.locale, const Locale('ru'));
    await restored.updateLocale(null);
    expect(restored.locale, isNull);
    expect(await (await SettingsService.loadFromPrefs()).localeTag(), isNull);
    controller.dispose();
    restored.dispose();
  });

  test('old settings default to the one-column plant layout', () async {
    final settings = SettingsService.fromJson({'_themeMode': 'dark'});

    expect(await settings.themeMode(), ThemeMode.dark);
    expect(await settings.plantListLayout(), PlantListLayout.rows);
    expect(
      await settings.wateringStatusPresentation(),
      WateringStatusPresentation.informative,
    );
  });

  test('plant list layout is persisted with the other settings', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();

    await settings.updatePlantListLayout(PlantListLayout.grid);
    final reloaded = await SettingsService.loadFromPrefs();

    expect(await reloaded.plantListLayout(), PlantListLayout.grid);
  });

  test(
    'watering status presentation is persisted with the other settings',
    () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService();

      await settings.updateWateringStatusPresentation(
        WateringStatusPresentation.simple,
      );
      final reloaded = await SettingsService.loadFromPrefs();

      expect(
        await reloaded.wateringStatusPresentation(),
        WateringStatusPresentation.simple,
      );
    },
  );
}
