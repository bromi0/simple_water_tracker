import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_water_tracker/src/sample_feature/plant_data.dart';

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
    _savePlantData();
    notifyListeners();
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

  final String dataKey = 'my_data_key';

  Future<void> _savePlantData() async {
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
      notifyListeners();
    }
  }
}
