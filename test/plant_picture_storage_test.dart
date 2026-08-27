import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_water_tracker/src/services/plant_picture_storage.dart';

void main() {
  test('should atomically save non-empty picture bytes', () async {
    final directory = await Directory.systemTemp.createTemp('plant-picture-');
    addTearDown(() => directory.delete(recursive: true));

    final path = await PlantPictureStorage.save(
      plantId: 'fern',
      pictureBytes: Future.value(Uint8List.fromList([1, 2, 3])),
      destinationDirectory: directory,
    );

    expect(path, '${directory.path}/fern.jpg');
    expect(await File(path).readAsBytes(), [1, 2, 3]);
    expect(File('$path.tmp').existsSync(), isFalse);
  });

  test('should reject an empty picture without leaving a file', () async {
    final directory = await Directory.systemTemp.createTemp('plant-picture-');
    addTearDown(() => directory.delete(recursive: true));

    final save = PlantPictureStorage.save(
      plantId: 'fern',
      pictureBytes: Future.value(Uint8List(0)),
      destinationDirectory: directory,
    );

    await expectLater(save, throwsStateError);
    expect(File('${directory.path}/fern.jpg').existsSync(), isFalse);
    expect(File('${directory.path}/fern.jpg.tmp').existsSync(), isFalse);
  });
}
