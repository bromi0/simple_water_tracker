import 'dart:async';

import 'package:flutter/material.dart';

import '../services/android_notification_permissions.dart';
import '../services/notification_service.dart';
import '../localization/app_localizations.dart';

enum _NotificationError { updateReminders, readSettings, openSettings }

/// Reads OS-owned state instead of storing an app notification preference.
class NotificationSettings extends StatefulWidget {
  const NotificationSettings({
    super.key,
    required this.refreshPermission,
    required this.requestPermission,
    this.readState = NotificationService.permissionState,
    this.openSettings = NotificationService.openNotificationSettings,
  });

  final Future<bool> Function() refreshPermission;
  final Future<bool> Function() requestPermission;
  final Future<NotificationPermissionState> Function() readState;
  final Future<bool> Function() openSettings;

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings>
    with WidgetsBindingObserver {
  NotificationPermissionState? _status;
  bool _busy = false;
  _NotificationError? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) {
      unawaited(_refresh());
    }
  }

  Future<void> _refresh({Future<bool> Function()? request}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    _NotificationError? error;
    NotificationPermissionState? status;
    try {
      if (request != null) await request();
      await widget.refreshPermission();
    } catch (_) {
      error = _NotificationError.updateReminders;
    }
    // Show the actual permission even if scheduling failed after it was granted.
    try {
      status = await widget.readState();
    } catch (_) {
      error = _NotificationError.readSettings;
    }
    if (!mounted) return;
    setState(() {
      _status = status;
      _error = error;
      _busy = false;
    });
  }

  Future<void> _openSettings() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    _NotificationError? error;
    try {
      if (!await widget.openSettings()) {
        error = _NotificationError.openSettings;
      }
    } catch (_) {
      error = _NotificationError.openSettings;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final description = switch (_status) {
      NotificationPermissionState.enabled =>
        l10n.notificationsEnabledDescription,
      NotificationPermissionState.requestable =>
        l10n.notificationsRequestableDescription,
      NotificationPermissionState.settingsRequired =>
        l10n.notificationsSettingsRequiredDescription,
      NotificationPermissionState.channelBlocked =>
        l10n.notificationsChannelBlockedDescription,
      NotificationPermissionState.unsupported =>
        l10n.notificationsUnsupportedDescription,
      null => l10n.checkingNotificationSettings,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.notifications,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(description),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null) ...[
          Text(switch (_error!) {
            _NotificationError.updateReminders => l10n.reminderUpdateFailed,
            _NotificationError.readSettings =>
              l10n.notificationSettingsReadFailed,
            _NotificationError.openSettings => l10n.androidSettingsOpenFailed,
          }),
          TextButton(
            onPressed: _busy ? null : _refresh,
            child: Text(l10n.retry),
          ),
        ],
        if (_status == NotificationPermissionState.requestable)
          FilledButton(
            onPressed: _busy
                ? null
                : () => _refresh(request: widget.requestPermission),
            child: Text(l10n.allowNotifications),
          ),
        if (_status != null &&
            _status != NotificationPermissionState.unsupported)
          OutlinedButton(
            onPressed: _busy ? null : _openSettings,
            child: Text(l10n.openNotificationSettings),
          ),
      ],
    );
  }
}
