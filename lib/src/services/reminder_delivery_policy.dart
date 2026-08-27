class ReminderDeliveryPolicy {
  const ReminderDeliveryPolicy({
    this.overdueDeliveryDelay = const Duration(minutes: 2),
    this.retryDelay = const Duration(minutes: 30),
  });

  /// Gives an already-due plant a short delay so a newly saved state does not
  /// interrupt the user immediately. Future reminders retain their calculated
  /// watering time.
  final Duration overdueDeliveryDelay;

  /// The one follow-up reminder stays scheduled even if the first alert is
  /// dismissed. A later plant state change replaces both notification slots.
  final Duration retryDelay;

  DateTime initialDeliveryTime({
    required DateTime reminderTime,
    required DateTime now,
  }) =>
      reminderTime.isAfter(now) ? reminderTime : now.add(overdueDeliveryDelay);

  DateTime retryDeliveryTime(DateTime initialDeliveryTime) =>
      initialDeliveryTime.add(retryDelay);
}
