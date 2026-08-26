import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class PlantPictureStorage {
  static Future<String> save({
    required String plantId,
    required Future<Uint8List> pictureBytes,
    Directory? destinationDirectory,
  }) async {
    final directory =
        destinationDirectory ?? await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$plantId.jpg';
    final file = File(filePath);
    await file.writeAsBytes(await pictureBytes);
    return filePath;
  }
}
