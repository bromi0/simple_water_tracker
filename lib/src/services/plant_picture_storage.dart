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
    final temporaryFile = File('$filePath.tmp');
    try {
      final bytes = await pictureBytes;
      if (bytes.isEmpty) {
        throw StateError('Captured picture is empty');
      }
      await temporaryFile.writeAsBytes(bytes, flush: true);
      return (await temporaryFile.rename(filePath)).path;
    } catch (_) {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
      rethrow;
    }
  }

  static Future<void> delete(String? picturePath) async {
    if (picturePath == null) return;
    final file = File(picturePath);
    if (await file.exists()) await file.delete();
  }
}
