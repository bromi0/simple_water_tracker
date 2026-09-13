import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';
import 'package:simple_water_tracker/src/basic_feature/reminder_schedule_view.dart';
import 'package:simple_water_tracker/src/services/plant_service.dart';
import 'package:simple_water_tracker/src/settings/settings_controller.dart';
import 'package:simple_water_tracker/src/settings/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'due schedule cards use watering status rather than plant color',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = PlantService();
      await store.loaded;
      final plant = PlantData(name: 'Fern', waterLevel: 0, color: Colors.green);
      store.wateringSchedule.add(
        ExpectedWateringTime(
          plant: plant,
          scheduledDateTime: DateTime.now().toUtc(),
        ),
      );
      final settings = SettingsController(SettingsService());
      await settings.loadSettings();
      addTearDown(store.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: store),
            ChangeNotifierProvider.value(value: settings),
          ],
          child: const MaterialApp(home: ReminderScheduleView()),
        ),
      );

      expect(find.text('Needs water'), findsOneWidget);
      expect(find.text('Water now'), findsOneWidget);
      final card = tester.widget<Card>(find.byType(Card).first);
      expect(
        card.color?.toARGB32(),
        ThemeData().colorScheme.error.withAlpha(28).toARGB32(),
      );
    },
  );
}
