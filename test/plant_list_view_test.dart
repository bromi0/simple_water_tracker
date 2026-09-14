import 'package:simple_water_tracker/src/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_list_view.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_tile.dart';
import 'package:simple_water_tracker/src/services/plant_service.dart';
import 'package:simple_water_tracker/src/services/room_service.dart';
import 'package:simple_water_tracker/src/settings/settings_controller.dart';
import 'package:simple_water_tracker/src/settings/settings_service.dart';

void main() {
  for (final layout in PlantListLayout.values) {
    testWidgets('${layout.name} opens the dedicated editor', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = PlantService();
      final rooms = RoomService();
      await store.loaded;
      await rooms.loaded;
      final settings = SettingsController(SettingsService());
      await settings.loadSettings();
      await settings.updatePlantListLayout(layout);
      addTearDown(store.dispose);
      addTearDown(rooms.dispose);
      addTearDown(settings.dispose);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: store),
            ChangeNotifierProvider.value(value: rooms),
            ChangeNotifierProvider.value(value: settings),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PlantListView(settingsController: settings),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PlantTile).first);
      await tester.pumpAndSettle();
      expect(find.text('Edit plant'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
