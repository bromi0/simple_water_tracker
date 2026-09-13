import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_water_tracker/src/localization/app_localizations.dart';
import 'package:simple_water_tracker/src/rooms/room_management_view.dart';
import 'package:simple_water_tracker/src/services/plant_service.dart';
import 'package:simple_water_tracker/src/services/room_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('custom room dialog closes and saves without framework errors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'water_plant_data_key': '[]'});
    final plants = PlantService();
    final rooms = RoomService();
    await Future.wait([plants.loaded, rooms.loaded]);
    addTearDown(plants.dispose);
    addTearDown(rooms.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: plants),
          ChangeNotifierProvider.value(value: rooms),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RoomManagementView(),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Create room'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pump();
    expect(find.text('Enter a room name.'), findsOneWidget);
    expect(find.text('Create room'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Create room'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Plant shelf');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Plant shelf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
