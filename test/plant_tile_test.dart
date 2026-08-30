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

  testWidgets(
    'row layout keeps one water action and moves other actions to menu',
    (tester) async {
      final plant = PlantData(
        name: 'A very long plant name that needs room',
        waterLevel: 20,
      );

      await _pumpTile(tester, store, plant, PlantTileLayout.row);

      expect(find.text('Water'), findsOneWidget);
      expect(find.byTooltip('More actions for ${plant.name}'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('More actions for ${plant.name}'));
      await tester.pumpAndSettle();

      expect(find.text('Undo watering'), findsOneWidget);
      expect(find.text('Edit plant'), findsOneWidget);
      expect(find.text('Delete plant'), findsOneWidget);
    },
  );

  testWidgets('grid layout gives the photo card explicit accessible actions', (
    tester,
  ) async {
    final plant = PlantData(name: 'Cactus', waterLevel: 80);

    await _pumpTile(tester, store, plant, PlantTileLayout.grid);

    expect(find.bySemanticsLabel('Edit Cactus'), findsOneWidget);
    expect(find.byTooltip('Water Cactus'), findsOneWidget);
    expect(find.byTooltip('More actions for Cactus'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
      child: MaterialApp(
        home: ChangeNotifierProvider.value(
          value: store,
          child: Scaffold(
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
