import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_water_tracker/src/services/room_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<RoomService> createService(Map<String, Object>? values) async {
    SharedPreferences.setMockInitialValues(values ?? {});
    final service = RoomService();
    await service.loaded;
    addTearDown(service.dispose);
    return service;
  }

  test('missing room storage loads an empty optional catalogue', () async {
    final service = await createService(null);

    expect(service.rooms, isEmpty);
  });

  test('rooms persist in their user-defined order', () async {
    final service = await createService(null);
    final kitchen = await service.add(' Kitchen ');
    final bedroom = await service.add('Bedroom');
    await service.reorder(1, 0);

    expect(service.rooms.map((room) => room.name), ['Bedroom', 'Kitchen']);

    final saved = SharedPreferences.getInstance().then(
      (prefs) => prefs.getString(RoomService.dataKey),
    );
    final decoded = jsonDecode((await saved)!) as List<dynamic>;
    expect(decoded.map((value) => value['id']), [bedroom.id, kitchen.id]);
  });

  test('room names are trimmed and unique without regard to case', () async {
    final service = await createService(null);
    await service.add('Living room');

    await expectLater(service.add('  living ROOM  '), throwsArgumentError);
    await expectLater(service.add('  '), throwsArgumentError);
  });
}
