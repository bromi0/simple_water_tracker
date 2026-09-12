import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_list_view.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_tile.dart';
import 'package:simple_water_tracker/src/services/plant_service.dart';
import 'package:simple_water_tracker/src/settings/settings_controller.dart';
import 'package:simple_water_tracker/src/settings/settings_service.dart';

void main() {
  for (final layout in PlantListLayout.values) {
    testWidgets(
      '${layout.name} viewport stays stable while editor avoids keyboard',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final store = PlantService();
        await store.loaded;
        final settings = SettingsController(SettingsService());
        await settings.loadSettings();
        await settings.updatePlantListLayout(layout);
        addTearDown(store.dispose);
        addTearDown(settings.dispose);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(400, 800);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: store,
            child: MaterialApp(
              home: PlantListView(settingsController: settings),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final collection = find.byKey(
          PageStorageKey(
            layout == PlantListLayout.rows
                ? 'plant-row-list'
                : 'plant-grid-list',
          ),
        );
        final viewport = tester.getRect(collection);
        await tester.tap(find.byType(PlantTile).first);
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Draft name');
        for (final bottom in [80.0, 200.0, 300.0, 150.0, 0.0]) {
          tester.view.viewInsets = FakeViewPadding(bottom: bottom);
          await tester.pumpAndSettle();
          expect(tester.getRect(collection), viewport);
          expect(
            tester.getBottomRight(find.widgetWithText(FilledButton, 'Save')).dy,
            lessThanOrEqualTo(800 - bottom),
          );
          expect(find.text('Draft name'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
