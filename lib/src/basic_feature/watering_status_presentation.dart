import 'package:flutter/material.dart';

import '../services/watering_reminder_calculator.dart';
import 'plant_data.dart';

/// The amount of watering urgency conveyed by every plant-facing surface.
enum PlantWateringState { doingWell, waterSoon, needsWater }

/// Chooses whether plant surfaces include an estimated watering time.
enum WateringStatusPresentation { simple, informative }

/// A shared, UI-facing description of a plant's current watering state.
///
/// Keeping state, wording, and color selection together prevents a decorative
/// plant color from accidentally communicating watering urgency. The English
/// copy is deliberately centralized here so a future localization pass has one
/// presentation endpoint to replace.
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

  String get simpleLabel => switch (state) {
    PlantWateringState.doingWell => 'Doing well',
    PlantWateringState.waterSoon => 'Water soon',
    PlantWateringState.needsWater => 'Needs water',
  };

  String informativeLabel({DateTime? now}) {
    final remaining = estimatedWateringTime.difference(
      (now ?? DateTime.now()).toUtc(),
    );
    if (state == PlantWateringState.needsWater || remaining <= Duration.zero) {
      return 'Water now';
    }
    final hours = remaining.inMinutes.ceil() / 60;
    if (hours < 48) return 'Water in ~${hours.ceil()} h';
    final days = (hours / 24).ceil();
    return 'Water in ~$days ${days == 1 ? 'day' : 'days'}';
  }

  /// Compact copy keeps the informative grid card readable beside its action.
  String compactInformativeLabel({DateTime? now}) {
    final remaining = estimatedWateringTime.difference(
      (now ?? DateTime.now()).toUtc(),
    );
    if (state == PlantWateringState.needsWater || remaining <= Duration.zero) {
      return 'Water now';
    }
    final hours = remaining.inMinutes.ceil() / 60;
    if (hours < 48) return '~${hours.ceil()}h';
    return '~${(hours / 24).ceil()}d';
  }

  String semanticsLabel(
    WateringStatusPresentation presentation, {
    DateTime? now,
  }) {
    final detail = presentation == WateringStatusPresentation.informative
        ? ', ${informativeLabel(now: now)}'
        : '';
    return '$simpleLabel$detail';
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
