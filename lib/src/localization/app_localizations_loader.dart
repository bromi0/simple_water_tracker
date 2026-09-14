import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Loads generated messages where a widget BuildContext is unavailable.
Future<AppLocalizations> loadAppLocalizations({Locale? locale}) {
  final resolved =
      locale ??
      basicLocaleListResolution(
    PlatformDispatcher.instance.locales,
        AppLocalizations.supportedLocales,
      );
  return AppLocalizations.delegate.load(resolved);
}

Locale? localeForLanguageTag(String? tag) {
  for (final supported in AppLocalizations.supportedLocales) {
    if (supported.toLanguageTag() == tag) return supported;
  }
  return null;
}
