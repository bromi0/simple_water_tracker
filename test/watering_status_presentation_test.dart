import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';
import 'package:simple_water_tracker/src/basic_feature/watering_status_presentation.dart';

void main() {
  final now = DateTime.utc(2026, 9, 13, 12);

  test('reports a healthy plant with an estimated watering time', () {
    final status = PlantWateringStatus.forPlant(
      PlantData(name: 'Fern', waterLevel: 80, wateringInterval: 3),
      now: now,
    );

    expect(status.state, PlantWateringState.doingWell);
    expect(status.simpleLabel, 'Doing well');
    expect(status.informativeLabel(now: now), 'Water in ~33 h');
    expect(status.compactInformativeLabel(now: now), '~33h');
  });

  test('keeps the existing soon boundary and reports an hourly estimate', () {
    final status = PlantWateringStatus.forPlant(
      PlantData(name: 'Fern', waterLevel: 55, wateringInterval: 2),
      now: now,
    );

    expect(status.state, PlantWateringState.waterSoon);
    expect(status.simpleLabel, 'Water soon');
    expect(status.informativeLabel(now: now), 'Water in ~10 h');
  });

  test('a zero-water plant is always due even with a future schedule time', () {
    final status = PlantWateringStatus.forPlant(
      PlantData(name: 'Fern', waterLevel: 0),
      estimatedWateringTime: now.add(const Duration(days: 1)),
      now: now,
    );

    expect(status.state, PlantWateringState.needsWater);
    expect(status.simpleLabel, 'Needs water');
    expect(status.informativeLabel(now: now), 'Water now');
  });

  test('uses the shared semantic color for due plants', () {
    final status = PlantWateringStatus.forPlant(
      PlantData(name: 'Fern', waterLevel: 0),
      now: now,
    );

    expect(
      status.colorFor(ThemeData()).toARGB32(),
      ThemeData().colorScheme.error.toARGB32(),
    );
  });
}
