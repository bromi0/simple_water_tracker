import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

/// Displays detailed information about a SampleItem.
class SampleItemDetailsView extends StatelessWidget {
  const SampleItemDetailsView({super.key});

  static const routeName = '/sample_item';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.itemDetails)),
      body: Center(child: Text(l10n.moreInformation)),
    );
  }
}
