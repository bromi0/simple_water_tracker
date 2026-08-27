import 'package:flutter_test/flutter_test.dart';
import 'package:simple_water_tracker/src/services/reminder_delivery_policy.dart';

void main() {
  const policy = ReminderDeliveryPolicy();
  final now = DateTime(2026, 8, 26, 12);

  test('keeps a future reminder at its calculated time', () {
    final reminder = now.add(const Duration(hours: 3));

    expect(
      policy.initialDeliveryTime(reminderTime: reminder, now: now),
      reminder,
    );
  });

  test('delays an overdue reminder until it can be scheduled', () {
    expect(
      policy.initialDeliveryTime(
        reminderTime: now.subtract(const Duration(hours: 1)),
        now: now,
      ),
      now.add(const Duration(minutes: 2)),
    );
  });

  test('schedules one retry after the configured delay', () {
    expect(policy.retryDeliveryTime(now), now.add(const Duration(minutes: 30)));
  });
}
