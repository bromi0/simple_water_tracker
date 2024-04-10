import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';
import 'notification_service.dart';

class ExpectedWateringTime {
  ExpectedWateringTime({required this.plant, required this.scheduledDateTime});
  final PlantData plant;
  final DateTime scheduledDateTime;
}

class PlantService extends ChangeNotifier {
  PlantService() {
    _loadPlantData();
  }

  List<PlantData> _plants = [
    PlantData(name: 'Cactus', waterLevel: 80, color: Colors.green.shade400),
    PlantData(name: 'Sunflower', waterLevel: 50, color: Colors.yellow),
    PlantData(name: 'Rose', waterLevel: 20, color: Colors.red),
    PlantData(name: 'Cactus', waterLevel: 80, color: Colors.green.shade300),
    PlantData(name: 'Sunflower', waterLevel: 50, color: Colors.yellow),
    PlantData(name: 'Rose', waterLevel: 20, color: Colors.red),
    // Add more plant data here
  ];

  UnmodifiableListView<PlantData> get plants => UnmodifiableListView(_plants);

  List<ExpectedWateringTime> wateringSchedule = [];

  void add(PlantData plant) {
    _plants.add(plant);
    notifyListeners();
  }

  void remove(PlantData plant) {
    _plants.remove(plant);
    notifyListeners();
  }

  void waterPlant(PlantData plant) async {
    plant.waterPlant();
    _savePlantData();
    notifyListeners();
    await NotificationService.setupWaterScheduleNotifications(wateringSchedule);
  }

  void undoWaterPlant(PlantData plant) {
    plant.undoWatering();
    _savePlantData();
    notifyListeners();
  }

  void updatePlant(PlantData plant, String name, int wateringInterval) {
    plant.name = name;
    plant.wateringInterval = wateringInterval;
    _savePlantData();
    notifyListeners();
  }

  void calculateWaterLevels() {
    for (var plantData in _plants) {
      plantData.updateWaterLevel();
    }
  }

  void calculateWateringSchedule() {
    wateringSchedule.clear();
    for (var plant in _plants) {
      final expectedWatering = ExpectedWateringTime(
          plant: plant, scheduledDateTime: plant.calculateWhenShouldWater());
      wateringSchedule.add(expectedWatering);
    }
    wateringSchedule
        .sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
  }

  final String dataKey = 'water_plant_data_key';

  void updateStoreState() {
    calculateWaterLevels();
    calculateWateringSchedule();
  }

  Future<void> _savePlantData() async {
    updateStoreState();
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> jsonList =
        _plants.map((plantData) => plantData.toJson()).toList();

    // Encode the list of JSON maps to a JSON string
    String jsonString = jsonEncode(jsonList);
    await prefs.setString(dataKey, jsonString);
  }

  Future<void> _loadPlantData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(dataKey) ?? '';
    if (savedData.isNotEmpty) {
      final decodedData = jsonDecode(savedData) as List<dynamic>;
      _plants = decodedData
          .map((e) => PlantData.fromJson(e as Map<String, dynamic>))
          .toList();
      calculateWaterLevels();
      notifyListeners();
    }
  }
}
