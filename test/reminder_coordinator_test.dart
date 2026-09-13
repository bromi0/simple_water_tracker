import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';
import 'package:simple_water_tracker/src/services/notification_service.dart';
import 'package:simple_water_tracker/src/services/package_replacement_recovery.dart';
import 'package:simple_water_tracker/src/services/plant_service.dart';
import 'package:simple_water_tracker/src/services/reminder_coordinator.dart';
import 'package:simple_water_tracker/src/services/reminder_delivery_policy.dart';

void main() {
  Future<PlantService> store() async {
    final plant = PlantData(id: 'fern', name: 'Fern', waterLevel: 0);
    SharedPreferences.setMockInitialValues({
      'water_plant_data_key': jsonEncode([plant.toJson()]),
    });
    final service = PlantService();
    await service.loaded;
    addTearDown(service.dispose);
    return service;
  }

  test(
    'startup is shared and removal waits for in-flight scheduling',
    () async {
      final service = await store();
      final entered = Completer<void>();
      final release = Completer<void>();
      final calls = <String>[];
      final coordinator = ReminderCoordinator(
        plantService: service,
        initializeNotifications: () async {},
        readPermissions: () async => false,
        schedulePlantNotifications: (_, _) async {
          calls.add('schedule');
          entered.complete();
          await release.future;
          calls.add('scheduled');
        },
        cancelPlantNotifications: (_) async {
          calls.add('cancel');
        },
      );
      addTearDown(coordinator.dispose);
      final startup = coordinator.start();
      expect(identical(startup, coordinator.start()), isTrue);
      await entered.future;
      await service.remove(service.plants.single);
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['schedule']);
      release.complete();
      await startup;
      await coordinator.settled;
      expect(calls, ['schedule', 'scheduled', 'cancel']);
    },
  );

  test('removal during initialization is retained', () async {
    final service = await store();
    final initializing = Completer<void>();
    final release = Completer<void>();
    final cancelled = <String>[];
    final coordinator = ReminderCoordinator(
      plantService: service,
      readPermissions: () async => false,
      initializeNotifications: () async {
        initializing.complete();
        await release.future;
      },
      schedulePlantNotifications: (_, _) async => fail('removed plant'),
      cancelPlantNotifications: (id) async {
        cancelled.add(id);
      },
    );
    addTearDown(coordinator.dispose);
    final startup = coordinator.start();
    await initializing.future;
    await service.remove(service.plants.single);
    await Future<void>.delayed(Duration.zero);
    release.complete();
    await startup;
    await coordinator.settled;
    expect(cancelled, ['fern']);
  });

  test(
    'permission reconciliation reports platform failure to its caller',
    () async {
      final service = await store();
      var failScheduling = false;
      final coordinator = ReminderCoordinator(
        plantService: service,
        initializeNotifications: () async {},
        readPermissions: () async => false,
        requestPermissions: () async => true,
        schedulePlantNotifications: (_, _) async {
          if (failScheduling) throw StateError('platform failure');
        },
      );
      addTearDown(coordinator.dispose);
      await coordinator.start();
      failScheduling = true;
      await expectLater(
        coordinator.requestNotificationsPermission(),
        throwsStateError,
      );
      failScheduling = false;
      expect(await coordinator.requestNotificationsPermission(), isTrue);
    },
  );

  test('failed startup can retry without subscribing twice', () async {
    final service = await store();
    var failStartup = true;
    var replacements = 0;
    final coordinator = ReminderCoordinator(
      plantService: service,
      initializeNotifications: () async {},
      readPermissions: () async => true,
      schedulePlantNotifications: (_, _) async {
        if (failStartup) throw StateError('startup scheduling failed');
      },
      replacePlantNotifications: (_, _) async {
        replacements++;
      },
    );
    addTearDown(coordinator.dispose);
    await expectLater(coordinator.start(), throwsStateError);
    failStartup = false;
    await coordinator.start();
    await service.waterPlant(service.plants.single);
    await Future<void>.delayed(Duration.zero);
    await coordinator.settled;
    expect(replacements, 1);
  });

  test('queued edits use current state and recover after a failure', () async {
    final service = await store();
    final entered = Completer<void>();
    final release = Completer<void>();
    final names = <String>[];
    final coordinator = ReminderCoordinator(
      plantService: service,
      initializeNotifications: () async {},
      readPermissions: () async => false,
      schedulePlantNotifications: (_, _) async {},
      replacePlantNotifications: (_, notes) async {
        names.add(notes.first.title);
        if (names.length == 1) {
          entered.complete();
          await release.future;
          throw StateError('platform failure');
        }
      },
    );
    addTearDown(coordinator.dispose);
    await coordinator.start();
    await service.updatePlant(service.plants.single, 'First', 2);
    await entered.future;
    await service.updatePlant(service.plants.single, 'Latest', 3);
    await Future<void>.delayed(Duration.zero);
    expect(names, ['First']);
    release.complete();
    await coordinator.settled;
    expect(names, ['First', 'Latest']);
  });

  for (final testAction in [false, true]) {
    for (final granted in [false, true]) {
      test(
        'permission testAction=$testAction granted=$granted awaits reminders',
        () async {
          final service = await store();
          final entered = Completer<void>();
          final release = Completer<void>();
          var schedules = 0;
          var tests = 0;
          final coordinator = ReminderCoordinator(
            plantService: service,
            initializeNotifications: () async {},
            readPermissions: () async => false,
            requestPermissions: () async => granted,
            schedulePlantNotifications: (_, _) async {
              schedules++;
              if (schedules > 1) {
                entered.complete();
                await release.future;
              }
            },
            replacePlantNotifications: (_, _) async =>
                fail('must preserve alerts'),
            scheduleTestNotification: () async {
              tests++;
              return true;
            },
          );
          addTearDown(coordinator.dispose);
          await coordinator.start();
          var completed = false;
          final action =
              (testAction
                      ? coordinator.scheduleTestNotification()
                      : coordinator.requestNotificationsPermission())
                  .then((value) {
                    completed = true;
                    return value;
                  });
          if (granted) {
            await entered.future;
            expect(completed, isFalse);
            expect(tests, 0);
            release.complete();
          }
          expect(await action, granted);
          expect(schedules, granted ? 2 : 1);
          expect(tests, testAction && granted ? 1 : 0);
        },
      );
    }
  }

  test('permission refresh only reconciles a transition to enabled', () async {
    final service = await store();
    var granted = true;
    var schedules = 0;
    final coordinator = ReminderCoordinator(
      plantService: service,
      initializeNotifications: () async {},
      readPermissions: () async => granted,
      requestPermissions: () async => granted,
      schedulePlantNotifications: (_, _) async {
        schedules++;
      },
      scheduleTestNotification: () async => true,
    );
    addTearDown(coordinator.dispose);
    await coordinator.start();
    expect(schedules, 1);
    await coordinator.refreshNotificationPermission();
    await coordinator.scheduleTestNotification();
    expect(schedules, 1);
    granted = false;
    expect(await coordinator.refreshNotificationPermission(), isFalse);
    granted = true;
    expect(await coordinator.refreshNotificationPermission(), isTrue);
    expect(schedules, 2);
    await coordinator.refreshNotificationPermission();
    expect(schedules, 2);
  });

  test('creates an initial and retry reminder for a due plant', () async {
    final thirstyPlant = PlantData(
      id: 'thirsty-plant',
      name: 'Thirsty plant',
      waterLevel: 0,
    );
    SharedPreferences.setMockInitialValues({
      'water_plant_data_key': jsonEncode([thirstyPlant.toJson()]),
    });
    final replacements = <(String, List<WateringNotification>)>[];
    final plantService = PlantService();
    final coordinator = ReminderCoordinator(
      plantService: plantService,
      policy: const ReminderDeliveryPolicy(),
      initializeNotifications: () async {},
      readPermissions: () async => false,
      cancelPlantNotifications: (_) async {},
      schedulePlantNotifications: (plantId, notifications) async {
        replacements.add((plantId, notifications));
      },
    );

    await coordinator.start();

    expect(replacements, hasLength(1));
    final notifications = replacements.single.$2;
    expect(replacements.single.$1, thirstyPlant.id);
    expect(notifications.map((notification) => notification.slot), [
      WateringNotificationSlot.initial,
      WateringNotificationSlot.retry,
    ]);
    expect(notifications[0].timeoutAfter, const Duration(minutes: 30));
    expect(
      notifications[1].deliveryTime.difference(notifications[0].deliveryTime),
      const Duration(minutes: 30),
    );
    coordinator.dispose();
    plantService.dispose();
  });

  test('cancels only removed plant reminder slots', () async {
    final plant = PlantData(id: 'removed-plant', name: 'Fern', waterLevel: 0);
    SharedPreferences.setMockInitialValues({
      'water_plant_data_key': jsonEncode([plant.toJson()]),
    });
    final cancelledPlantIds = <String>[];
    final plantService = PlantService();
    final coordinator = ReminderCoordinator(
      plantService: plantService,
      initializeNotifications: () async {},
      readPermissions: () async => false,
      schedulePlantNotifications: (_, _) async {},
      replacePlantNotifications: (_, _) async {},
      cancelPlantNotifications: (plantId) async {
        cancelledPlantIds.add(plantId);
      },
    );
    await coordinator.start();

    await plantService.remove(plantService.plants.single);
    await Future<void>.delayed(Duration.zero);

    expect(cancelledPlantIds, contains(plant.id));
    coordinator.dispose();
    plantService.dispose();
  });

  test('package replacement recalculates reminders from plant state', () async {
    final thirstyPlant = PlantData(
      id: 'updated-app-plant',
      name: 'Updated app plant',
      waterLevel: 0,
    );
    SharedPreferences.setMockInitialValues({
      'water_plant_data_key': jsonEncode([thirstyPlant.toJson()]),
    });
    var platformConfigured = false;
    final scheduled = <(String, List<WateringNotification>)>[];

    await restoreWateringRemindersAfterPackageReplacement(
      configurePlatformNotifications: () async {
        platformConfigured = true;
      },
      createReminderCoordinator: (plantService) => ReminderCoordinator(
        plantService: plantService,
        initializeNotifications: () async {},
        readPermissions: () async => false,
        schedulePlantNotifications: (plantId, notifications) async {
          scheduled.add((plantId, notifications));
        },
        cancelPlantNotifications: (_) async {},
      ),
    );

    expect(platformConfigured, isTrue);
    expect(scheduled, hasLength(1));
    expect(scheduled.single.$1, thirstyPlant.id);
    expect(
      scheduled.single.$2.map((notification) => notification.slot),
      WateringNotificationSlot.values,
    );
  });
}
