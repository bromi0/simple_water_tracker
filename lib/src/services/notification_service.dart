import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:simple_water_tracker/main.dart';
import 'package:simple_water_tracker/src/services/plant_service.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static Future<void> zonedScheduleNotification({
    required int id,
    required DateTime dt,
    String title = 'default title',
    String body = 'default body',
  }) async {
    var futureDate = tz.TZDateTime.from(dt, tz.local);
    if (futureDate.compareTo(tz.TZDateTime.now(tz.local)) <= 0) {
      // print('Got date to schedule in the past: $futureDate');
      return;
    }
    await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        futureDate,
        const NotificationDetails(
            android: AndroidNotificationDetails(
                'mainChannel', 'Water time notifications',
                channelDescription:
                    'The notifications reminding to water your plants.')),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
    // print('Setup scheduled notification for $futureDate');
  }

  static Future<void> setupWaterScheduleNotifications(
      List<ExpectedWateringTime> wateringSchedule) async {
    // print('Clearing schedule.');
    flutterLocalNotificationsPlugin.cancelAll();
    var now = DateTime.now();
    for (var i = 0; i < wateringSchedule.length; i++) {
      final note = wateringSchedule[i];
      if (note.scheduledDateTime.compareTo(now) > 0) {
        zonedScheduleNotification(
            id: i,
            dt: note.scheduledDateTime,
            title: note.plant.name,
            body: '${note.plant.name}: Water me please...');
      }
    }
  }
}
