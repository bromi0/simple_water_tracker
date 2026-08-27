import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import '../services/watering_reminder_calculator.dart';

part 'plant_data.g.dart';

@JsonSerializable(explicitToJson: true)
class PlantData {
  PlantData({
    required this.name,
    required this.waterLevel,
    this.color = Colors.green,
    this.wateringInterval = 3,
    // we don't save it for now, will start when there is UI to change.
    this.wateringThreshold = 35,
    String? id,
  }) : id = id ?? const Uuid().v4();

  final String id; // UUID
  @JsonKey(defaultValue: "Unknown")
  String name;
  @JsonKey(defaultValue: 100)
  int waterLevel; // Assuming a value between 0-100
  @ColorSerializer()
  final Color color; // Represents the plant photo for now
  int wateringInterval; // Desired watering interval in days
  @JsonKey(includeToJson: false)
  int wateringThreshold; // water level percentile when the notification is supposed to happen
  String? picturePath;
  bool _isPictureSaving = false;
  bool _didPictureSaveFail = false;

  bool get isPictureSaving => _isPictureSaving;
  bool get didPictureSaveFail => _didPictureSaveFail;

  @JsonKey(includeToJson: true, includeFromJson: true)
  List<WateringRecord> _wateringHistory = []; // List to store watering timestamps

  factory PlantData.fromJson(Map<String, dynamic> json) =>
      _$PlantDataFromJson(json);

  Map<String, dynamic> toJson() => _$PlantDataToJson(this);

  Future<void> attachPicture(Future<String> savedPicturePath) async {
    _isPictureSaving = true;
    _didPictureSaveFail = false;
    try {
      picturePath = await savedPicturePath;
    } catch (_) {
      _didPictureSaveFail = true;
      rethrow;
    } finally {
      _isPictureSaving = false;
    }
  }

  void waterPlant() {
    if (waterLevel < 100) {
      _wateringHistory.add(
        WateringRecord(
          timestamp: DateTime.now().toUtc(),
          previousWaterLevel: waterLevel,
        ),
      ); // Add current timestamp to wateringHistory
      waterLevel = 100; // Reset water level to 100 after watering
    }
  }

  void updateWaterLevel() {
    if (_wateringHistory.isEmpty) return;
    final now = DateTime.now();
    final durationSinceLastWatering = now.difference(
      _wateringHistory.last.timestamp,
    );
    final elapsedHours = durationSinceLastWatering.inHours;
    final intervalHours = wateringInterval * 24; // Convert days to hours

    // Calculate water level drop based on elapsed time and desired watering interval
    waterLevel = 100 - ((elapsedHours / intervalHours) * 100).floor();
    waterLevel = waterLevel.clamp(
      0,
      100,
    ); // Ensure water level stays within 0-100 range
  }

  void undoWatering() {
    if (_wateringHistory.isNotEmpty) {
      final now = DateTime.now();
      final lastTimestamp = _wateringHistory.last.timestamp.toLocal();
      final todayDate = DateTime(now.year, now.month, now.day);
      final lastWateringRecordDate = DateTime(
        lastTimestamp.year,
        lastTimestamp.month,
        lastTimestamp.day,
      );

      if (lastWateringRecordDate == todayDate) {
        waterLevel = _wateringHistory.last.previousWaterLevel;
        _wateringHistory.removeLast();
      }
    }
  }

  DateTime calculateWhenShouldWater({
    DateTime? now,
    WateringReminderCalculator calculator = const WateringReminderCalculator(),
  }) {
    // the water level should be updated because we don't run any background calculations
    updateWaterLevel();
    return calculator.calculate(
      now: (now ?? DateTime.now()).toUtc(),
      waterLevel: waterLevel,
      wateringIntervalDays: wateringInterval,
      wateringThreshold: wateringThreshold,
    );
  }
}

@JsonSerializable()
class WateringRecord {
  WateringRecord({
    required DateTime timestamp,
    required this.previousWaterLevel,
  }) : timestamp = timestamp.toUtc();

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
    return object.toARGB32();
  }
}
