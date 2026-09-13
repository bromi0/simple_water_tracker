import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../rooms/room_data.dart';

/// Owns the persisted room catalogue. Plant membership remains plant data.
class RoomService extends ChangeNotifier {
  RoomService() {
    loaded = _loadRooms();
  }

  static const dataKey = 'water_plant_rooms_data_key';
  late final Future<void> loaded;
  List<RoomData> _rooms = [];

  UnmodifiableListView<RoomData> get rooms => UnmodifiableListView(_rooms);

  RoomData? roomById(String? id) {
    if (id == null) return null;
    for (final room in _rooms) {
      if (room.id == id) return room;
    }
    return null;
  }

  Future<RoomData> add(String name) async {
    final normalizedName = _validateName(name);
    final room = RoomData(name: normalizedName);
    _rooms.add(room);
    try {
      await _saveRooms();
    } catch (_) {
      _rooms.removeLast();
      rethrow;
    }
    notifyListeners();
    return room;
  }

  Future<void> rename(RoomData room, String name) async {
    if (!_rooms.contains(room)) throw StateError('Room no longer exists');
    final normalizedName = _validateName(name, excluding: room);
    final oldName = room.name;
    room.name = normalizedName;
    try {
      await _saveRooms();
    } catch (_) {
      room.name = oldName;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _rooms.length) {
      throw RangeError.index(oldIndex, _rooms);
    }
    if (newIndex < 0 || newIndex >= _rooms.length) {
      throw RangeError.index(newIndex, _rooms);
    }
    if (oldIndex == newIndex) return;
    final previous = List<RoomData>.of(_rooms);
    final room = _rooms.removeAt(oldIndex);
    _rooms.insert(newIndex, room);
    try {
      await _saveRooms();
    } catch (_) {
      _rooms = previous;
      rethrow;
    }
    notifyListeners();
  }

  /// Removes only the catalogue entry. References on plants then naturally
  /// resolve as unassigned, even if a later cleanup save is interrupted.
  Future<void> remove(RoomData room) async {
    final index = _rooms.indexOf(room);
    if (index == -1) throw StateError('Room no longer exists');
    _rooms.removeAt(index);
    try {
      await _saveRooms();
    } catch (_) {
      _rooms.insert(index, room);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> _loadRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(dataKey);
    if (savedData == null || savedData.isEmpty) return;
    final decoded = jsonDecode(savedData) as List<dynamic>;
    _rooms = decoded
        .map((value) => RoomData.fromJson(value as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> _saveRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_rooms.map((room) => room.toJson()).toList());
    if (!await prefs.setString(dataKey, json)) {
      throw StateError('Could not save rooms');
    }
  }

  String _validateName(String name, {RoomData? excluding}) {
    final normalized = name.trim();
    if (normalized.isEmpty) throw ArgumentError('A room name is required');
    final normalizedKey = normalized.toLowerCase();
    final duplicate = _rooms.any(
      (room) => room != excluding && room.name.toLowerCase() == normalizedKey,
    );
    if (duplicate) throw ArgumentError('A room with that name already exists');
    return normalized;
  }
}
