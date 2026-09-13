import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'room_data.g.dart';

/// A user-created room. Position in the persisted list is its display order.
@JsonSerializable()
class RoomData {
  RoomData({required this.name, String? id}) : id = id ?? const Uuid().v4();

  factory RoomData.fromJson(Map<String, dynamic> json) =>
      _$RoomDataFromJson(json);

  Map<String, dynamic> toJson() => _$RoomDataToJson(this);

  final String id;
  String name;
}

/// Stable identifiers for room names offered during setup.
///
/// The presentation layer maps these identifiers to localized labels. They are
/// never persisted, so changing a translation cannot rename a user's room.
enum RoomSuggestion {
  livingRoom,
  bedroom,
  kitchen,
  diningRoom,
  office,
  balcony,
  hallway,
  patio,
  terrace,
  porch,
  garden,
  greenhouse,
  yard,
}
