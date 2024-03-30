import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class PlantData {
  PlantData({
    required this.name,
    required this.waterLevel,
    this.color = Colors.green,
    this.wateringInterval = 7,
  }) : id = const Uuid().v4();

  final String id; // UUID
  final String name;
  int waterLevel; // Assuming a value between 0-100
  final Color color; // Represents the plant photo for now
  int wateringInterval; // Desired watering interval in days
  final List<_WateringRecord> _wateringHistory =
      []; // List to store watering timestamps

  void waterPlant() {
    if (waterLevel < 100) {
      _wateringHistory.add(_WateringRecord(
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

class PlantStore extends ChangeNotifier {
  final List<PlantData> _plants = [
    PlantData(name: 'Cactus', waterLevel: 80, color: Colors.green.shade400),
    PlantData(name: 'Sunflower', waterLevel: 50, color: Colors.yellow),
    PlantData(name: 'Rose', waterLevel: 20, color: Colors.red),
    PlantData(name: 'Cactus', waterLevel: 80, color: Colors.green.shade300),
    PlantData(name: 'Sunflower', waterLevel: 50, color: Colors.yellow),
    PlantData(name: 'Rose', waterLevel: 20, color: Colors.red),
    // Add more plant data here
  ];

  UnmodifiableListView<PlantData> get plants => UnmodifiableListView(_plants);

  void add(PlantData plant) {
    _plants.add(plant);
    notifyListeners();
  }

  void remove(PlantData plant) {
    _plants.remove(plant);
    notifyListeners();
  }

  void waterPlant(PlantData plant) {
    plant.waterPlant();
    notifyListeners();
  }

  void undoWaterPlant(PlantData plant) {
    plant.undoWatering();
    notifyListeners();
  }
}

class _WateringRecord {
  _WateringRecord({
    required this.timestamp,
    required this.previousWaterLevel,
  });

  final DateTime timestamp;
  final int previousWaterLevel;
}
