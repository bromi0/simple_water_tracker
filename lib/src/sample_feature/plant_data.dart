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