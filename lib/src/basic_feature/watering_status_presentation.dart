import 'package:flutter/material.dart';

import '../services/watering_reminder_calculator.dart';
import '../localization/app_localizations.dart';
import 'plant_data.dart';

/// The amount of watering urgency conveyed by every plant-facing surface.
enum PlantWateringState { doingWell, waterSoon, needsWater }

/// Chooses whether plant surfaces include an estimated watering time.
enum WateringStatusPresentation { simple, informative }

/// A shared, UI-facing description of a plant's current watering state.
///
/// Keeping state, wording, and color selection together prevents a decorative
/// plant color from accidentally communicating watering urgency. Messages use
/// the generated localization API at this shared presentation boundary.
class PlantWateringStatus {
  const PlantWateringStatus._({
    required this.state,
    required this.estimatedWateringTime,
  });

  final PlantWateringState state;
  final DateTime estimatedWateringTime;

  factory PlantWateringStatus.forPlant(
    PlantData plant, {
    DateTime? estimatedWateringTime,
    DateTime? now,
  }) {
    final currentTime = (now ?? DateTime.now()).toUtc();
    final dueAt =
        estimatedWateringTime ??
        const WateringReminderCalculator().calculate(
          now: currentTime,
          waterLevel: plant.waterLevel,
          wateringIntervalDays: plant.wateringInterval,
          wateringThreshold: plant.wateringThreshold,
        );
    final isDue =
        plant.waterLevel <= plant.wateringThreshold ||
        !dueAt.isAfter(currentTime);
    final state = isDue
        ? PlantWateringState.needsWater
        : plant.waterLevel <= plant.wateringThreshold + 20
        ? PlantWateringState.waterSoon
        : PlantWateringState.doingWell;
    return PlantWateringStatus._(state: state, estimatedWateringTime: dueAt);
  }

  String simpleLabel(AppLocalizations l10n) => switch (state) {
    PlantWateringState.doingWell => l10n.doingWell,
    PlantWateringState.waterSoon => l10n.waterSoon,
    PlantWateringState.needsWater => l10n.needsWater,
  };

  // Preserve the 48-hour cutoff and round positive estimates up, including
  // sub-minute durations. All visual and spoken variants share this rounding.
  ({bool due, bool useHours, int count}) _estimate(DateTime? now) {
    final remaining = estimatedWateringTime.difference(
      (now ?? DateTime.now()).toUtc(),
    );
    if (state == PlantWateringState.needsWater || remaining <= Duration.zero) {
      return (due: true, useHours: true, count: 0);
    }
    final hours = remaining.inMicroseconds / Duration.microsecondsPerHour;
    return (
      due: false,
      useHours: hours < 48,
      count: hours < 48 ? hours.ceil() : (hours / 24).ceil(),
    );
  }

  String informativeLabel(AppLocalizations l10n, {DateTime? now}) {
    final estimate = _estimate(now);
    if (estimate.due) return l10n.waterNow;
    return estimate.useHours
        ? l10n.waterInHours(estimate.count)
        : l10n.waterInDays(estimate.count);
  }

  String compactInformativeLabel(AppLocalizations l10n, {DateTime? now}) {
    final estimate = _estimate(now);
    if (estimate.due) return l10n.waterNow;
    return estimate.useHours
        ? l10n.waterInHoursCompact(estimate.count)
        : l10n.waterInDaysCompact(estimate.count);
  }

  String semanticsLabel(
    AppLocalizations l10n,
    WateringStatusPresentation presentation, {
    DateTime? now,
  }) {
    final label = simpleLabel(l10n);
    if (presentation == WateringStatusPresentation.simple) return label;
    final estimate = _estimate(now);
    final detail = estimate.due
        ? l10n.waterNow
        : estimate.useHours
        ? l10n.waterInHoursSpoken(estimate.count)
        : l10n.waterInDaysSpoken(estimate.count);
    return l10n.wateringStatusWithEstimate(label, detail);
  }

  Color colorFor(ThemeData theme) {
    return switch (state) {
      PlantWateringState.needsWater => theme.colorScheme.error,
      PlantWateringState.waterSoon =>
        theme.brightness == Brightness.dark
            ? Colors.amber.shade300
            : Colors.amber.shade800,
      PlantWateringState.doingWell =>
        theme.brightness == Brightness.dark
            ? Colors.green.shade300
            : Colors.green.shade700,
    };
  }

  Color onImageColor() => switch (state) {
    PlantWateringState.needsWater => Colors.red.shade200,
    PlantWateringState.waterSoon => Colors.amber.shade200,
    PlantWateringState.doingWell => Colors.green.shade200,
  };
}
