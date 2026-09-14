import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_editor_screen.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_list_view.dart';
import 'package:simple_water_tracker/src/basic_feature/reminder_schedule_view.dart';
import 'package:simple_water_tracker/src/camera/take_picture_screen.dart';
import 'package:simple_water_tracker/src/localization/app_localizations.dart';
import 'package:simple_water_tracker/src/rooms/room_management_view.dart';
import 'package:simple_water_tracker/src/services/plant_service.dart';
import 'package:simple_water_tracker/src/services/reminder_coordinator.dart';
import 'package:simple_water_tracker/src/services/room_service.dart';
import 'package:simple_water_tracker/src/settings/settings_controller.dart';
import 'package:simple_water_tracker/src/settings/settings_service.dart';
import 'package:simple_water_tracker/src/settings/settings_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PlantService plants;
  late RoomService rooms;
  late SettingsController settings;
  late ReminderCoordinator reminders;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/camera'),
          (call) async => call.method == 'availableCameras' ? [] : null,
        );
    SharedPreferences.setMockInitialValues({'water_plant_data_key': '[]'});
    plants = PlantService();
    rooms = RoomService();
    settings = SettingsController(SettingsService());
    await Future.wait([plants.loaded, rooms.loaded, settings.loadSettings()]);
    reminders = ReminderCoordinator(
      plantService: plants,
      initializeNotifications: () async {},
      readPermissions: () async => false,
      schedulePlantNotifications: (_, _) async {},
      replacePlantNotifications: (_, _) async {},
    );
    await reminders.start();
  });

  tearDown(() {
    reminders.dispose();
    plants.dispose();
    rooms.dispose();
    settings.dispose();
  });

  Widget app(Widget home, {double textScale = 1, Locale? locale}) =>
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: plants),
          ChangeNotifierProvider.value(value: rooms),
          ChangeNotifierProvider.value(value: settings),
          Provider.value(value: reminders),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: home,
        ),
      );

  void russianDevice(WidgetTester tester) {
    tester.platformDispatcher.localesTestValue = [const Locale('ru', 'RU')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
  }

  testWidgets('language selector switches Settings immediately', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: settings,
        builder: (context, child) =>
            app(SettingsView(controller: settings), locale: settings.locale),
      ),
    );
    await tester.runAsync(() => reminders.settled);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Русский').last);
    await tester.pumpAndSettle();
    expect(settings.locale, const Locale('ru'));
    expect(find.text('Настройки'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Как в системе').last);
    await tester.pumpAndSettle();
    expect(settings.locale, isNull);
    expect(find.text('Settings'), findsOneWidget);
  });

  test('Russian plurals use one, few, and many forms', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ru'));
    for (final entry in [
      (0, 'растений', 'дней', 'часов'),
      (1, 'растение', 'день', 'час'),
      (2, 'растения', 'дня', 'часа'),
      (5, 'растений', 'дней', 'часов'),
      (11, 'растений', 'дней', 'часов'),
      (21, 'растение', 'день', 'час'),
      (22, 'растения', 'дня', 'часа'),
      (25, 'растений', 'дней', 'часов'),
    ]) {
      final (count, plantUnit, dayUnit, hourUnit) = entry;
      expect(l10n.plantCount(count), '$count $plantUnit');
      expect(l10n.dayCount(count), '$count $dayUnit');
      expect(l10n.wateringInterval(count), 'Раз в $count $dayUnit');
      expect(
        l10n.waterInHoursSpoken(count),
        'Полив примерно через $count $hourUnit',
      );
    }
    expect(l10n.waterPlant('Пышный папоротник'), 'Полить: Пышный папоротник');
    expect(l10n.plantNameSuggestion1, 'Цветущая азалия');
    expect(l10n.plantNameSuggestion2, 'Пышный папоротник');
  });

  testWidgets('locale changes preserve the editor and its draft', (
    tester,
  ) async {
    final plant = PlantData(name: 'My Fern', waterLevel: 80);
    await plants.add(plant);
    await tester.pumpWidget(
      app(PlantEditorScreen(plant: plant), locale: const Locale('ru')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Редактирование'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Мой папоротник');

    await tester.pumpWidget(
      app(PlantEditorScreen(plant: plant), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Edit plant'), findsOneWidget);
    expect(find.text('Мой папоротник'), findsOneWidget);
    expect(plant.name, 'My Fern');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'room validation follows language changes without renaming rooms',
    (tester) async {
      russianDevice(tester);
      await rooms.add('Living room');
      await tester.pumpWidget(app(const RoomManagementView()));
      await tester.pumpAndSettle();
      expect(find.text('Гостиная'), findsOneWidget);
      expect(find.text('Living room'), findsOneWidget);
      await tester.tap(find.byTooltip('Создать комнату'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Создать'));
      await tester.pump();
      expect(find.text('Введите название комнаты.'), findsOneWidget);

      tester.platformDispatcher.localesTestValue = [const Locale('en')];
      await tester.pumpAndSettle();
      expect(find.text('Enter a room name.'), findsOneWidget);
      expect(rooms.rooms.single.name, 'Living room');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Russian grid exposes translated actions and full spoken estimates',
    (tester) async {
      russianDevice(tester);
      await settings.updatePlantListLayout(PlantListLayout.grid);
      await plants.add(PlantData(name: 'Папоротник', waterLevel: 80));
      await tester.pumpWidget(
        app(PlantListView(settingsController: settings), textScale: 1.25),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Изменить: Папоротник'), findsOneWidget);
      expect(find.byTooltip('Полить: Папоротник'), findsOneWidget);
      expect(find.text('Всё хорошо'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp('Всё хорошо. Полив примерно через .* часа'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a Russian name suggestion remains draft content after language change',
    (tester) async {
      russianDevice(tester);
      await tester.pumpWidget(app(const TakePictureScreen()));
      await tester.pumpAndSettle();
      final suggested = tester
          .widget<TextField>(find.byType(TextField))
          .decoration!
          .hintText!;
      expect(suggested, matches(RegExp('[А-Яа-яЁё]')));
      tester.platformDispatcher.localesTestValue = [const Locale('en')];
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.hintText,
        suggested,
      );
      await tester.ensureVisible(find.text('Add without photo'));
      await tester.tap(find.text('Add without photo'));
      await tester.pumpAndSettle();
      expect(plants.plants.single.name, suggested);
    },
  );

  testWidgets('Russian room dialog fits large text above the keyboard', (
    tester,
  ) async {
    russianDevice(tester);
    tester.view.physicalSize = const Size(320, 700);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpWidget(app(const RoomManagementView(), textScale: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Создать комнату'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Создать'));
    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();
    expect(find.text('Введите название комнаты.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final screenName in [
    'plants',
    'editor',
    'schedule',
    'rooms',
    'settings',
    'camera',
  ]) {
    testWidgets('Russian $screenName tolerates narrow width and large text', (
      tester,
    ) async {
      russianDevice(tester);
      tester.view.physicalSize = const Size(320, 700);
      final plant = PlantData(
        name: 'Очень длинное название растения',
        waterLevel: 80,
      );
      await plants.add(plant);
      final screen = switch (screenName) {
        'plants' => PlantListView(settingsController: settings),
        'editor' => PlantEditorScreen(plant: plant),
        'schedule' => const ReminderScheduleView(),
        'rooms' => const RoomManagementView(),
        'settings' => SettingsView(controller: settings),
        _ => const TakePictureScreen(),
      };
      await tester.pumpWidget(app(screen, textScale: 2));
      // The coordinator was created in asynchronous setUp; drain its existing
      // queue before settling frames in the widget test's fake clock.
      await tester.runAsync(() => reminders.settled);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '${screen.runtimeType}');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
