import 'package:simple_water_tracker/src/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';
import 'package:simple_water_tracker/src/basic_feature/watering_status_presentation.dart';

void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });
  final now = DateTime.utc(2026, 9, 13, 12);

  test('reports a healthy plant with an estimated watering time', () {
    final status = PlantWateringStatus.forPlant(
      PlantData(name: 'Fern', waterLevel: 80, wateringInterval: 3),
      now: now,
    );

    expect(status.state, PlantWateringState.doingWell);
    expect(status.simpleLabel(l10n), 'Doing well');
    expect(status.informativeLabel(l10n, now: now), 'Water in ~33 h');
    expect(status.compactInformativeLabel(l10n, now: now), '~33h');
  });

  test('keeps the existing soon boundary and reports an hourly estimate', () {
    final status = PlantWateringStatus.forPlant(
      PlantData(name: 'Fern', waterLevel: 55, wateringInterval: 2),
      now: now,
    );

    expect(status.state, PlantWateringState.waterSoon);
    expect(status.simpleLabel(l10n), 'Water soon');
    expect(status.informativeLabel(l10n, now: now), 'Water in ~10 h');
  });

  test('a zero-water plant is always due even with a future schedule time', () {
    final status = PlantWateringStatus.forPlant(
      PlantData(name: 'Fern', waterLevel: 0),
      estimatedWateringTime: now.add(const Duration(days: 1)),
      now: now,
    );

    expect(status.state, PlantWateringState.needsWater);
    expect(status.simpleLabel(l10n), 'Needs water');
    expect(status.informativeLabel(l10n, now: now), 'Water now');
  });

  test('all estimate variants share hour/day rounding and due boundaries', () {
    for (final entry in [
      (
        remaining: const Duration(seconds: 30),
        full: 'Water in ~1 h',
        compact: '~1h',
        spoken: 'Water in approximately 1 hour',
      ),
      (
        remaining: const Duration(hours: 47, minutes: 59),
        full: 'Water in ~48 h',
        compact: '~48h',
        spoken: 'Water in approximately 48 hours',
      ),
      (
        remaining: const Duration(hours: 48),
        full: 'Water in ~2 days',
        compact: '~2d',
        spoken: 'Water in approximately 2 days',
      ),
      (
        remaining: Duration.zero,
        full: 'Water now',
        compact: 'Water now',
        spoken: 'Water now',
      ),
    ]) {
      final status = PlantWateringStatus.forPlant(
        PlantData(name: 'Fern', waterLevel: 100),
        estimatedWateringTime: now.add(entry.remaining),
        now: now,
      );
      expect(status.informativeLabel(l10n, now: now), entry.full);
      expect(status.compactInformativeLabel(l10n, now: now), entry.compact);
      expect(
        status.semanticsLabel(
          l10n,
          WateringStatusPresentation.informative,
          now: now,
        ),
        '${status.simpleLabel(l10n)}, ${entry.spoken}',
      );
    }
  });

  test('uses the shared semantic color for due plants', () {
    final status = PlantWateringStatus.forPlant(
      PlantData(name: 'Fern', waterLevel: 0),
      now: now,
    );

    expect(
      status.colorFor(ThemeData()).toARGB32(),
      ThemeData().colorScheme.error.toARGB32(),
    );
  });
}
