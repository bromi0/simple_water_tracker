import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_tile.dart';
import 'package:simple_water_tracker/src/services/plant_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlantService store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = PlantService();
    await store.loaded;
  });

  tearDown(() => store.dispose());

  testWidgets('row layout keeps one water action and opens the full editor', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.reset);
    final plant = PlantData(
      name: 'A very long plant name that needs room',
      waterLevel: 20,
    );

    await _pumpTile(tester, store, plant, PlantTileLayout.row);

    expect(find.text('Water'), findsOneWidget);
    expect(find.byTooltip('More actions for ${plant.name}'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(plant.name));
    await tester.pumpAndSettle();

    expect(find.text('Edit plant'), findsOneWidget);
    expect(find.byTooltip('Change photo'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    expect(find.text('Delete plant'), findsOneWidget);

    await tester.tap(find.byTooltip('Change photo'));
    await tester.pumpAndSettle();

    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Remove photo'), findsNothing);
  });

  testWidgets(
    'grid layout gives the photo card direct editor and water actions',
    (tester) async {
      final plant = PlantData(name: 'Cactus', waterLevel: 80);

      await _pumpTile(tester, store, plant, PlantTileLayout.grid);

      expect(find.bySemanticsLabel('Edit Cactus'), findsOneWidget);
      expect(find.byTooltip('Water Cactus'), findsOneWidget);
      expect(find.byTooltip('More actions for Cactus'), findsNothing);
      expect(find.text('80%'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.bySemanticsLabel('Edit Cactus'));
      await tester.pumpAndSettle();

      expect(find.text('Edit plant'), findsOneWidget);
      expect(find.byTooltip('Change photo'), findsOneWidget);
    },
  );

  testWidgets('editor saves a name and watering interval draft', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.reset);
    final plant = store.plants.first;
    await _pumpTile(tester, store, plant, PlantTileLayout.row);

    await tester.tap(find.text('Cactus'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Fern');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Fern',
    );
    await tester.tap(find.byTooltip('Increase watering interval'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Could not save this plant.'), findsNothing);
    expect(plant.name, 'Fern');
    expect(plant.wateringInterval, 4);
    expect(find.text('Edit plant'), findsNothing);
  });

  testWidgets('water action becomes undo without showing a snackbar', (
    tester,
  ) async {
    final plant = store.plants.first;
    final previousLevel = plant.waterLevel;
    await _pumpTile(tester, store, plant, PlantTileLayout.row);

    await tester.tap(find.byTooltip('Water Cactus'));
    await tester.pump();

    expect(find.byTooltip('Undo watering for Cactus'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.byTooltip('Undo watering for Cactus'));
    await tester.pump();

    expect(find.byTooltip('Water Cactus'), findsOneWidget);
    expect(plant.waterLevel, previousLevel);
  });

  testWidgets('undo action expires after fifteen minutes', (tester) async {
    final plant = store.plants.first;
    await _pumpTile(tester, store, plant, PlantTileLayout.grid);

    await tester.tap(find.byTooltip('Water Cactus'));
    await tester.pump();
    expect(find.byTooltip('Undo watering for Cactus'), findsOneWidget);

    await tester.pump(PlantData.undoWateringDuration);
    await tester.pump();

    expect(find.byTooltip('Water Cactus'), findsOneWidget);
  });
}

Future<void> _pumpTile(
  WidgetTester tester,
  PlantService store,
  PlantData plant,
  PlantTileLayout layout,
) {
  final tile = PlantTile(plant: plant, layout: layout);
  return tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(
        size: Size(393, 800),
        textScaler: TextScaler.linear(1.25),
      ),
      child: ChangeNotifierProvider.value(
        value: store,
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: layout == PlantTileLayout.grid ? 175 : 393,
                height: layout == PlantTileLayout.grid ? 237 : null,
                child: tile,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
