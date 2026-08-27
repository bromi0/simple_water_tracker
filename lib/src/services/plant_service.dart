import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';

class ExpectedWateringTime {
  ExpectedWateringTime({required this.plant, required this.scheduledDateTime});
  final PlantData plant;
  final DateTime scheduledDateTime;
}

/// A persisted plant change that requires its platform reminder slots to be
/// rebuilt. It deliberately contains no notification-platform details.
class PlantReminderChange {
  const PlantReminderChange.updated(this.plantId) : isRemoved = false;

  const PlantReminderChange.removed(this.plantId) : isRemoved = true;

  final String plantId;
  final bool isRemoved;
}

class PlantService extends ChangeNotifier {
  PlantService() {
    loaded = _loadPlantData();
  }

  // Coordinators can await persisted data without starting a second load.
  late final Future<void> loaded;

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

  // Derived application state only; platform notification state lives in the
  // reminder coordinator and NotificationService.
  final List<ExpectedWateringTime> wateringSchedule = [];
  final _reminderChanges = StreamController<PlantReminderChange>.broadcast();

  Stream<PlantReminderChange> get reminderChanges => _reminderChanges.stream;

  Future<void> add(PlantData plant, {Future<String>? pictureSave}) async {
    final pictureAttachment = pictureSave == null
        ? null
        : plant.attachPicture(pictureSave);
    _plants.add(plant);
    await _savePlantData();
    _reminderChanges.add(PlantReminderChange.updated(plant.id));
    notifyListeners();

    try {
      await pictureAttachment;
    } catch (error) {
      debugPrint('Could not save plant picture: $error');
    }
    // Picture persistence does not alter watering state, but its path still
    // needs to be saved after the asynchronous copy finishes.
    await _savePlantData();
    notifyListeners();
  }

  Future<void> remove(PlantData plant) async {
    final plantId = plant.id;
    _plants.remove(plant);
    await _savePlantData();
    _reminderChanges.add(PlantReminderChange.removed(plantId));
    notifyListeners();
  }

  Future<void> waterPlant(PlantData plant) async {
    plant.waterPlant();
    await _savePlantData();
    _reminderChanges.add(PlantReminderChange.updated(plant.id));
    notifyListeners();
  }

  Future<void> undoWaterPlant(PlantData plant) async {
    plant.undoWatering();
    await _savePlantData();
    _reminderChanges.add(PlantReminderChange.updated(plant.id));
    notifyListeners();
  }

  Future<void> updatePlant(
    PlantData plant,
    String name,
    int wateringInterval,
  ) async {
    plant.name = name;
    plant.wateringInterval = wateringInterval;
    await _savePlantData();
    _reminderChanges.add(PlantReminderChange.updated(plant.id));
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
        plant: plant,
        scheduledDateTime: plant.calculateWhenShouldWater(),
      );
      wateringSchedule.add(expectedWatering);
    }
    wateringSchedule.sort(
      (a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime),
    );
  }

  final String dataKey = 'water_plant_data_key';

  void updateStoreState() {
    calculateWaterLevels();
    calculateWateringSchedule();
  }

  Future<void> refreshReminders() async {
    await loaded;
    updateStoreState();
    for (final plant in _plants) {
      _reminderChanges.add(PlantReminderChange.updated(plant.id));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_reminderChanges.close());
    super.dispose();
  }

  Future<void> _savePlantData() async {
    updateStoreState();
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> jsonList = _plants
        .map((plantData) => plantData.toJson())
        .toList();

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
      calculateWateringSchedule();
      notifyListeners();
    }
  }
}
