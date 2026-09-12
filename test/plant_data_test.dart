import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';

void main() {
  test('should store watering timestamps as UTC instants', () {
    final record = WateringRecord(
      timestamp: DateTime.parse('2026-08-27T15:30:00+03:00'),
      previousWaterLevel: 40,
    );

    expect(record.timestamp, DateTime.utc(2026, 8, 27, 12, 30));
    expect(record.toJson()['timestamp'], '2026-08-27T12:30:00.000Z');
  });

  test('should expose picture saving state until its path is ready', () async {
    final plant = PlantData(name: 'Fern', waterLevel: 0);
    final savedPicturePath = Completer<String>();
    final save = plant.attachPicture(savedPicturePath.future);

    expect(plant.isPictureSaving, isTrue);
    expect(plant.picturePath, isNull);

    savedPicturePath.complete('/pictures/fern.jpg');
    await save;

    expect(plant.isPictureSaving, isFalse);
    expect(plant.picturePath, '/pictures/fern.jpg');
  });

  test('should expose a failed picture save', () async {
    final plant = PlantData(name: 'Fern', waterLevel: 0);
    final savedPicturePath = Completer<String>();
    final save = plant.attachPicture(savedPicturePath.future);

    savedPicturePath.completeError(StateError('disk full'));

    await expectLater(save, throwsStateError);
    expect(plant.isPictureSaving, isFalse);
    expect(plant.didPictureSaveFail, isTrue);
    expect(plant.picturePath, isNull);
  });

  test('should expose watering as undoable for fifteen minutes', () {
    final plant = PlantData(name: 'Fern', waterLevel: 40);

    plant.waterPlant();
    final wateredAt = plant.lastWateringTimestamp!;

    expect(plant.canUndoWatering, isTrue);
    expect(
      plant.undoWateringTimeRemaining(
        now: wateredAt.add(const Duration(minutes: 14, seconds: 59)),
      ),
      const Duration(seconds: 1),
    );
    expect(
      plant.undoWateringTimeRemaining(
        now: wateredAt.add(const Duration(minutes: 15)),
      ),
      isNull,
    );
    expect(plant.wateringHistory, hasLength(1));
    expect(
      () => plant.wateringHistory.add(
        WateringRecord(timestamp: DateTime.now(), previousWaterLevel: 0),
      ),
      throwsUnsupportedError,
    );
  });

  test('should reject an undo after fifteen minutes', () {
    final plant = PlantData(name: 'Fern', waterLevel: 40)..waterPlant();

    plant.undoWatering(
      now: plant.lastWateringTimestamp!.add(const Duration(minutes: 15)),
    );

    expect(plant.waterLevel, 100);
    expect(plant.wateringHistory, hasLength(1));
  });
}
