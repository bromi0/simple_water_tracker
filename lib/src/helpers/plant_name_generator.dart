import 'dart:math';

import '../localization/app_localizations.dart';

/// Select whole phrases so translations can preserve grammatical agreement.
String generateRandomPlantName(AppLocalizations l10n, {Random? random}) {
  final suggestions = [
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
  ];
  return suggestions[(random ?? Random()).nextInt(suggestions.length)];
}
