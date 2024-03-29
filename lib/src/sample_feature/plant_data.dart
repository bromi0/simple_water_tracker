import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class PlantData {
  PlantData({
    required this.name,
    required this.waterLevel,
    this.color = Colors.green,
  }) : id = const Uuid().v4();

  final String id; // UUID
  final String name;
  final int waterLevel; // Assuming a value between 0-100
  final Color color; // Represents the plant photo for now

  // You can add more properties or methods if needed
}

class PlantStore extends ChangeNotifier {
  final List<PlantData> _plants = [
    PlantData(name: 'Cactus', waterLevel: 80, color: Colors.green.shade400),
    PlantData(name: 'Sunflower', waterLevel: 50, color: Colors.yellow),
    PlantData(name: 'Rose', waterLevel: 20, color: Colors.red),
    PlantData(name: 'Cactus', waterLevel: 80, color: Colors.green.shade400),
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
}
