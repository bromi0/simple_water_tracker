import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';
import 'package:uuid/uuid.dart';

import '../observability/app_observability.dart';
import 'plant_picture_storage.dart';

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
    loaded = appPerformance.measure('startup.plants.load', _loadPlantData);
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

  PlantData? plantById(String id) {
    for (final plant in _plants) {
      if (plant.id == id) return plant;
    }
    return null;
  }

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
    int wateringInterval, {
    Uint8List? pictureBytes,
  }) async {
    if (!_plants.contains(plant)) throw StateError('Plant no longer exists');
    if (name.trim().isEmpty || wateringInterval < 1) {
      throw ArgumentError('A name and a positive interval are required');
    }
    // A new file keeps the original intact until Save succeeds and avoids
    // reusing Flutter's cached image for the previous photo.
    final newPicturePath = pictureBytes == null
        ? plant.picturePath
        : await PlantPictureStorage.save(
            plantId: '${plant.id}-${const Uuid().v4()}',
            pictureBytes: Future.value(pictureBytes),
          );
    if (!_plants.contains(plant)) throw StateError('Plant no longer exists');
    final oldName = plant.name;
    final oldInterval = plant.wateringInterval;
    final oldPicturePath = plant.picturePath;
    plant.name = name;
    plant.wateringInterval = wateringInterval;
    plant.picturePath = newPicturePath;
    try {
      await _savePlantData();
    } catch (_) {
      plant.name = oldName;
      plant.wateringInterval = oldInterval;
      plant.picturePath = oldPicturePath;
      updateStoreState();
      if (newPicturePath != oldPicturePath) {
        await _deleteStoredPicture(newPicturePath);
      }
      rethrow;
    }
    if (newPicturePath != oldPicturePath) {
      // The prior image is application-owned and is no longer reachable after
      // the replacement path has been persisted.
      await _deleteStoredPicture(oldPicturePath);
    }
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
    if (!await prefs.setString(dataKey, jsonString)) {
      throw StateError('Could not save plants');
    }
  }

  Future<void> _deleteStoredPicture(String? picturePath) async {
    try {
      await PlantPictureStorage.delete(picturePath);
    } catch (error, stackTrace) {
      // The persisted plant is already valid; an orphaned file can be cleaned
      // up later and must not make the edit look like it failed.
      appLogger.error(
        'plant_picture_delete_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
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
