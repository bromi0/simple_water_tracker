import 'package:flutter_test/flutter_test.dart';
import 'package:simple_water_tracker/src/services/watering_reminder_calculator.dart';

void main() {
  const calculator = WateringReminderCalculator();
  final now = DateTime(2026, 8, 26, 12);

  test(
    'full plant reaches a 35 percent threshold after 65 percent of interval',
    () {
      final reminder = calculator.calculate(
        now: now,
        waterLevel: 100,
        wateringIntervalDays: 4,
        wateringThreshold: 35,
      );

      expect(reminder, DateTime(2026, 8, 29, 2, 24));
    },
  );

  test(
    'partly depleted plant uses only its remaining water above threshold',
    () {
      final reminder = calculator.calculate(
        now: now,
        waterLevel: 50,
        wateringIntervalDays: 2,
        wateringThreshold: 35,
      );

      expect(reminder, DateTime(2026, 8, 26, 19, 12));
    },
  );

  test('plant already below threshold is due now', () {
    final reminder = calculator.calculate(
      now: now,
      waterLevel: 20,
      wateringIntervalDays: 2,
      wateringThreshold: 35,
    );

    expect(reminder, now);
  });
}
