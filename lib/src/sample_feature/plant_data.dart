import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'plant_data.g.dart';

@JsonSerializable(explicitToJson: true)
class PlantData {
  PlantData({
    required this.name,
    required this.waterLevel,
    this.color = Colors.green,
    this.wateringInterval = 7,
    XFile? picture, 
  }) : id = const Uuid().v4() {
    savePictureToFile(picture);
  }

  final String id; // UUID
  @JsonKey(defaultValue: "Unknown")
  final String name;
  @JsonKey(defaultValue: 100)
  int waterLevel; // Assuming a value between 0-100
  @JsonKey(includeToJson: false)
  @ColorSerializer()
  final Color color; // Represents the plant photo for now
  int wateringInterval; // Desired watering interval in days
  String? picturePath;

  @JsonKey(includeToJson: true, includeFromJson: true)
  List<WateringRecord> _wateringHistory =
      []; // List to store watering timestamps

  factory PlantData.fromJson(Map<String, dynamic> json) =>
      _$PlantDataFromJson(json);

  Map<String, dynamic> toJson() => _$PlantDataToJson(this);

  Future<void> savePictureToFile(XFile? picture) async {
    if (picture == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$id.jpg';
    final file = File(filePath);
    await file.writeAsBytes(await picture.readAsBytes());
    picturePath = filePath;
  }

  void waterPlant() {
    if (waterLevel < 100) {
      _wateringHistory.add(WateringRecord(
        timestamp: DateTime.now(),
        previousWaterLevel: waterLevel,
      )); // Add current timestamp to wateringHistory
      waterLevel = 100; // Reset water level to 100 after watering
    }
  }

  void updateWaterLevel() {
    final now = DateTime.now();
    final durationSinceLastWatering =
        now.difference(_wateringHistory.last.timestamp);
    final elapsedHours = durationSinceLastWatering.inHours;
    final intervalHours = wateringInterval * 24; // Convert days to hours

    // Calculate water level drop based on elapsed time and desired watering interval
    waterLevel = 100 - ((elapsedHours / intervalHours) * 100).floor();
    waterLevel =
        waterLevel.clamp(0, 100); // Ensure water level stays within 0-100 range
  }

  void undoWatering() {
    if (_wateringHistory.isNotEmpty) {
      final now = DateTime.now();
      final lastTimestamp = _wateringHistory.last.timestamp;
      final todayDate = DateTime(now.year, now.month, now.day);
      final lastWateringRecordDate =
          DateTime(lastTimestamp.year, lastTimestamp.month, lastTimestamp.day);

      if (lastWateringRecordDate == todayDate) {
        waterLevel = _wateringHistory.last.previousWaterLevel;
        _wateringHistory.removeLast();
      }
    }
  }
}

@JsonSerializable()
class WateringRecord {
  WateringRecord({
    required this.timestamp,
    required this.previousWaterLevel,
  });

  factory WateringRecord.fromJson(Map<String, dynamic> json) =>
      _$WateringRecordFromJson(json);

  Map<String, dynamic> toJson() => _$WateringRecordToJson(this);

  final DateTime timestamp;
  final int previousWaterLevel;
}

class ColorSerializer implements JsonConverter<Color, int> {
  const ColorSerializer();

  @override
  Color fromJson(int json) {
    return Color(json);
  }

  @override
  int toJson(Color object) {
    return object.value;
  }
}
