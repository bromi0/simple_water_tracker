import 'package:flutter/widgets.dart';

import '../localization/app_localizations.dart';
import 'room_data.dart';

/// Labels supplied by a locale for room suggestions.
///
/// Add a suggestion to a locale's map only when that place is useful in that
/// locale. The chooser will omit absent labels instead of falling back to a
/// different language.
Map<RoomSuggestion, String> roomSuggestionLabels(
  AppLocalizations localizations,
  Locale locale,
) {
  switch (locale.languageCode) {
    case 'en':
      return {
        RoomSuggestion.livingRoom: localizations.roomSuggestionLivingRoom,
        RoomSuggestion.bedroom: localizations.roomSuggestionBedroom,
        RoomSuggestion.kitchen: localizations.roomSuggestionKitchen,
        RoomSuggestion.diningRoom: localizations.roomSuggestionDiningRoom,
        RoomSuggestion.office: localizations.roomSuggestionOffice,
        RoomSuggestion.balcony: localizations.roomSuggestionBalcony,
        RoomSuggestion.hallway: localizations.roomSuggestionHallway,
        RoomSuggestion.patio: localizations.roomSuggestionPatio,
        RoomSuggestion.terrace: localizations.roomSuggestionTerrace,
        RoomSuggestion.porch: localizations.roomSuggestionPorch,
        RoomSuggestion.garden: localizations.roomSuggestionGarden,
        RoomSuggestion.greenhouse: localizations.roomSuggestionGreenhouse,
        RoomSuggestion.yard: localizations.roomSuggestionYard,
      };
    default:
      return const {};
  }
}
