import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The draft accompanying a photo returned after Android recreates the app.
class RecoveredPlantPhoto {
  const RecoveredPlantPhoto({
    required this.plantId,
    required this.name,
    required this.interval,
    required this.roomId,
    required this.bytes,
  });

  final String plantId;
  final String name;
  final String interval;
  final String? roomId;
  final Uint8List bytes;
}

/// Launches native photo selection without changing the plant until Save.
class PlantPhotoPicker {
  PlantPhotoPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  static const pendingKey = 'pending_plant_editor_photo';

  Future<Uint8List?> pick({
    required ImageSource source,
    required String plantId,
    required String name,
    required String interval,
    required String? roomId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    // The activity may be reclaimed while the system camera/gallery is open.
    // Remember the target and text draft before leaving Flutter.
    if (!await prefs.setString(
      pendingKey,
      jsonEncode({
        'plantId': plantId,
        'name': name,
        'interval': interval,
        'roomId': roomId,
      }),
    )) {
      throw StateError('Could not preserve the photo selection');
    }
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
        requestFullMetadata: false,
      );
      return await file?.readAsBytes();
    } finally {
      await prefs.remove(pendingKey);
    }
  }

  Future<RecoveredPlantPhoto?> recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString(pendingKey);
    try {
      final response = await _picker.retrieveLostData();
      if (response.exception != null) throw response.exception!;
      if (pending == null ||
          response.files == null ||
          response.files!.isEmpty) {
        return null;
      }
      final draft = jsonDecode(pending) as Map<String, dynamic>;
      return RecoveredPlantPhoto(
        plantId: draft['plantId'] as String,
        name: draft['name'] as String,
        interval: draft['interval'] as String,
        roomId: draft['roomId'] as String?,
        bytes: await response.files!.first.readAsBytes(),
      );
    } finally {
      await prefs.remove(pendingKey);
    }
  }
}
