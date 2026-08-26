typedef ReminderTimeAdjustment = DateTime Function(DateTime proposedTime);

class ReminderDeliveryPolicy {
  const ReminderDeliveryPolicy({
    this.backgroundGrace = const Duration(minutes: 2),
    this.retryCooldown = const Duration(minutes: 30),
    this.adjustTime,
  });

  final Duration backgroundGrace;
  final Duration retryCooldown;

  /// Hook for a future quiet-hours policy. It may move a proposed delivery
  /// forward, for example from nighttime to the next morning.
  final ReminderTimeAdjustment? adjustTime;

  /// Returns null when an overdue reminder is still inside its retry cooldown.
  /// Future reminders keep their calculated time; due reminders receive the
  /// background grace period before any optional delivery-window adjustment.
  DateTime? deliveryTime({
    required DateTime reminderTime,
    required DateTime now,
    DateTime? lastAttempt,
  }) {
    var proposedTime = reminderTime.isAfter(now)
        ? reminderTime
        : now.add(backgroundGrace);

    if (!reminderTime.isAfter(now) && lastAttempt != null) {
      final retryAt = lastAttempt.add(retryCooldown);
      if (retryAt.isAfter(proposedTime)) return null;
    }

    proposedTime = adjustTime?.call(proposedTime) ?? proposedTime;
    return proposedTime.isBefore(now) ? now : proposedTime;
  }
}
