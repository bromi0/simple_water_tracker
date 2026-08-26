class WateringReminderCalculator {
  const WateringReminderCalculator();

  DateTime calculate({
    required DateTime now,
    required int waterLevel,
    required int wateringIntervalDays,
    required int wateringThreshold,
  }) {
    final remainingWater = waterLevel - wateringThreshold;
    // Water level is modeled as a linear percentage loss across the selected
    // watering interval, so each percentage point represents this many seconds.
    final secondsPerWaterLevelPoint =
        const Duration(days: 1).inSeconds * wateringIntervalDays / 100;
    final secondsUntilReminder = (remainingWater * secondsPerWaterLevelPoint)
        .round();

    if (secondsUntilReminder <= 0) return now;
    return now.add(Duration(seconds: secondsUntilReminder));
  }
}
