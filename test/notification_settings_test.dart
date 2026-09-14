import 'package:simple_water_tracker/src/localization/app_localizations.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_water_tracker/src/services/android_notification_permissions.dart';
import 'package:simple_water_tracker/src/settings/notification_settings.dart';

void main() {
  testWidgets('request updates status and prevents duplicate taps', (
    tester,
  ) async {
    var state = NotificationPermissionState.requestable;
    final request = Completer<bool>();
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NotificationSettings(
            refreshPermission: () async =>
                state == NotificationPermissionState.enabled,
            readState: () async => state,
            requestPermission: () {
              requests++;
              return request.future;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allow notifications'));
    await tester.pump();
    await tester.tap(find.text('Allow notifications'));
    expect(requests, 1);
    state = NotificationPermissionState.enabled;
    request.complete(true);
    await tester.pumpAndSettle();
    expect(find.textContaining('Allowed by Android'), findsOneWidget);
    expect(find.text('Allow notifications'), findsNothing);
  });

  testWidgets('OS settings return refreshes permission without requesting', (
    tester,
  ) async {
    var state = NotificationPermissionState.settingsRequired;
    var opened = 0;
    var refreshes = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NotificationSettings(
            refreshPermission: () async {
              refreshes++;
              return state == NotificationPermissionState.enabled;
            },
            readState: () async => state,
            requestPermission: () async => throw StateError('must not prompt'),
            openSettings: () async {
              opened++;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Allow notifications'), findsNothing);
    await tester.tap(find.text('Open Android notification settings'));
    await tester.pumpAndSettle();
    expect(opened, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    state = NotificationPermissionState.enabled;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(refreshes, 2);
    expect(find.textContaining('Allowed by Android'), findsOneWidget);
  });

  testWidgets(
    'scheduling failure still shows granted OS permission and retry',
    (tester) async {
      var state = NotificationPermissionState.requestable;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NotificationSettings(
              refreshPermission: () async => false,
              readState: () async => state,
              requestPermission: () async {
                state = NotificationPermissionState.enabled;
                throw StateError('scheduling failed');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Allow notifications'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Allowed by Android'), findsOneWidget);
      expect(
        find.text('Could not update reminders. Try again.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    },
  );

  for (final state in [
    NotificationPermissionState.channelBlocked,
    NotificationPermissionState.unsupported,
  ]) {
    testWidgets('$state does not offer a runtime permission request', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NotificationSettings(
              refreshPermission: () async => false,
              readState: () async => state,
              requestPermission: () async =>
                  throw StateError('must not prompt'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Allow notifications'), findsNothing);
      expect(
        find.text('Open Android notification settings'),
        state == NotificationPermissionState.unsupported
            ? findsNothing
            : findsOneWidget,
      );
    });
  }
}
