import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';
import 'package:simple_water_tracker/src/services/plant_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PlantService> createService({
    PictureSaver? pictureSaver,
    PictureDeleter? pictureDeleter,
  }) async {
    SharedPreferences.setMockInitialValues({'water_plant_data_key': '[]'});
    final service = PlantService(
      pictureSaver: pictureSaver ?? _unexpectedPictureSave,
      pictureDeleter: pictureDeleter ?? _ignorePictureDelete,
    );
    await service.loaded;
    addTearDown(service.dispose);
    return service;
  }

  test(
    'failed photo creation leaves no plant or reminder change behind',
    () async {
      final service = await createService(
        pictureSaver: ({required plantId, required pictureBytes}) async {
          throw StateError('disk full');
        },
      );
      final changes = <PlantReminderChange>[];
      final subscription = service.reminderChanges.listen(changes.add);
      addTearDown(subscription.cancel);

      await expectLater(
        service.add(
          PlantData(name: 'Fern', waterLevel: 0),
          pictureBytes: Uint8List.fromList([1]),
        ),
        throwsStateError,
      );

      expect(service.plants, isEmpty);
      expect(changes, isEmpty);
    },
  );

  test('creation uses the editor validation and normalizes a name', () async {
    final service = await createService();

    await expectLater(
      service.add(PlantData(name: '   ', waterLevel: 0)),
      throwsArgumentError,
    );
    final plant = PlantData(name: '  Fern  ', waterLevel: 0);
    await service.add(plant);

    expect(service.plants, [plant]);
    expect(plant.name, 'Fern');
  });

  test('creation persists its completed photo and notifies once', () async {
    final service = await createService(
      pictureSaver: ({required plantId, required pictureBytes}) async {
        expect(await pictureBytes, [1, 2, 3]);
        return '/pictures/$plantId.jpg';
      },
    );
    final changes = <PlantReminderChange>[];
    final subscription = service.reminderChanges.listen(changes.add);
    addTearDown(subscription.cancel);
    final plant = PlantData(id: 'fern', name: 'Fern', waterLevel: 0);

    await service.add(plant, pictureBytes: Uint8List.fromList([1, 2, 3]));
    await Future<void>.delayed(Duration.zero);

    expect(service.plants, [plant]);
    expect(plant.picturePath, '/pictures/fern.jpg');
    expect(changes.map((change) => change.plantId), ['fern']);
  });

  test('removal releases the persisted plant photo after saving', () async {
    final deletedPaths = <String?>[];
    final service = await createService(
      pictureSaver: ({required plantId, required pictureBytes}) async =>
          '/pictures/fern.jpg',
      pictureDeleter: (path) async => deletedPaths.add(path),
    );
    final plant = PlantData(name: 'Fern', waterLevel: 0);
    await service.add(plant, pictureBytes: Uint8List.fromList([1]));

    await service.remove(plant);

    expect(service.plants, isEmpty);
    expect(deletedPaths, ['/pictures/fern.jpg']);
  });

  test(
    'a replaced photo is deleted when its plant disappears mid-save',
    () async {
      final saveStarted = Completer<void>();
      final allowSave = Completer<void>();
      final deletedPaths = <String?>[];
      var saveCount = 0;
      final service = await createService(
        pictureSaver: ({required plantId, required pictureBytes}) async {
          if (saveCount++ == 0) return '/pictures/old.jpg';
          saveStarted.complete();
          await allowSave.future;
          return '/pictures/new.jpg';
        },
        pictureDeleter: (path) async => deletedPaths.add(path),
      );
      final plant = PlantData(name: 'Fern', waterLevel: 0);
      await service.add(plant, pictureBytes: Uint8List.fromList([1]));

      final update = service.updatePlant(
        plant,
        'Fern',
        3,
        pictureBytes: Uint8List.fromList([1]),
      );
      await saveStarted.future;
      await service.remove(plant);
      allowSave.complete();

      await expectLater(update, throwsStateError);
      expect(deletedPaths, ['/pictures/old.jpg', '/pictures/new.jpg']);
    },
  );
}

Future<String> _unexpectedPictureSave({
  required String plantId,
  required Future<Uint8List> pictureBytes,
}) => throw StateError('Unexpected picture save');

Future<void> _ignorePictureDelete(String? _) async {}
