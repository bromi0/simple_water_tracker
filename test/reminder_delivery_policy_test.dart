import 'package:flutter_test/flutter_test.dart';
import 'package:simple_water_tracker/src/services/reminder_delivery_policy.dart';

void main() {
  const policy = ReminderDeliveryPolicy();
  final now = DateTime(2026, 8, 26, 12);

  test('keeps a future reminder at its calculated time', () {
    final reminder = now.add(const Duration(hours: 3));

    expect(policy.deliveryTime(reminderTime: reminder, now: now), reminder);
  });

  test('delays an overdue reminder until app exit grace has elapsed', () {
    expect(
      policy.deliveryTime(
        reminderTime: now.subtract(const Duration(hours: 1)),
        now: now,
      ),
      now.add(const Duration(minutes: 2)),
    );
  });

  test('suppresses an overdue retry during the 30 minute cooldown', () {
    expect(
      policy.deliveryTime(
        reminderTime: now.subtract(const Duration(hours: 1)),
        now: now,
        lastAttempt: now.subtract(const Duration(minutes: 10)),
      ),
      isNull,
    );
  });

  test('allows an overdue retry after the cooldown', () {
    expect(
      policy.deliveryTime(
        reminderTime: now.subtract(const Duration(hours: 1)),
        now: now,
        lastAttempt: now.subtract(const Duration(minutes: 31)),
      ),
      now.add(const Duration(minutes: 2)),
    );
  });

  test('applies the delivery adjustment hook', () {
    final quietHoursPolicy = ReminderDeliveryPolicy(
      adjustTime: (proposed) =>
          DateTime(proposed.year, proposed.month, proposed.day + 1, 8),
    );

    expect(
      quietHoursPolicy.deliveryTime(
        reminderTime: now.add(const Duration(hours: 3)),
        now: now,
      ),
      DateTime(2026, 8, 27, 8),
    );
  });
}
