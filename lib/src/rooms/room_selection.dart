/// The temporary collection shown on the plant screen.
///
/// It is intentionally navigation state, rather than a persisted preference:
/// reopening the app always starts with the complete collection.
class RoomSelection {
  const RoomSelection._(this.roomId, {required this.isUnassigned});

  const RoomSelection.all() : this._(null, isUnassigned: false);
  const RoomSelection.unassigned() : this._(null, isUnassigned: true);
  const RoomSelection.room(String roomId) : this._(roomId, isUnassigned: false);

  final String? roomId;
  final bool isUnassigned;

  bool get isAll => roomId == null && !isUnassigned;

  @override
  bool operator ==(Object other) =>
      other is RoomSelection &&
      other.roomId == roomId &&
      other.isUnassigned == isUnassigned;

  @override
  int get hashCode => Object.hash(roomId, isUnassigned);
}
