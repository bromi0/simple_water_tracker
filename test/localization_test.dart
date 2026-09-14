import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_water_tracker/src/helpers/plant_name_generator.dart';
import 'package:simple_water_tracker/src/localization/app_localizations.dart';

void main() {
  test('English is the fallback for unsupported and regional locales', () {
    expect(AppLocalizations.supportedLocales.first, const Locale('en'));
    for (final preferred in [const Locale('zz'), const Locale('en', 'GB')]) {
      expect(
        basicLocaleListResolution([
          preferred,
        ], AppLocalizations.supportedLocales),
        const Locale('en'),
      );
    }
  });

  test('messages preserve user names and pluralize counts', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(l10n.plantCount(0), '0 plants');
    expect(l10n.plantCount(1), '1 plant');
    expect(l10n.plantCount(2), '2 plants');
    expect(l10n.wateringInterval(1), 'Every 1 day');
    expect(l10n.wateringInterval(2), 'Every 2 days');
    expect(l10n.roomPlantsKept(1), '1 plant will be kept without a room.');
    expect(l10n.roomPlantsKept(2), '2 plants will be kept without a room.');
    expect(l10n.waterPlant('Мой «Кактус» {1}'), 'Water Мой «Кактус» {1}');
  });

  test('random suggestions select complete localized phrases', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final phrases = {
      l10n.plantNameSuggestion1,
      l10n.plantNameSuggestion2,
      l10n.plantNameSuggestion3,
      l10n.plantNameSuggestion4,
      l10n.plantNameSuggestion5,
      l10n.plantNameSuggestion6,
      l10n.plantNameSuggestion7,
      l10n.plantNameSuggestion8,
      l10n.plantNameSuggestion9,
      l10n.plantNameSuggestion10,
    };
    final random = Random(42);
    final selected = List.generate(
      100,
      (_) => generateRandomPlantName(l10n, random: random),
    ).toSet();
    expect(selected, phrases);
  });
}
