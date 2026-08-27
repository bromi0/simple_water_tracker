import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';
import 'package:simple_water_tracker/src/services/notification_service.dart';
import 'package:simple_water_tracker/src/services/plant_service.dart';
import 'package:simple_water_tracker/src/services/reminder_coordinator.dart';
import 'package:simple_water_tracker/src/services/reminder_delivery_policy.dart';

void main() {
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
}
