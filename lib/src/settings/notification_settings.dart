import 'dart:async';

import 'package:flutter/material.dart';

import '../services/android_notification_permissions.dart';
import '../services/notification_service.dart';

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
  String? _error;

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
    String? error;
    NotificationPermissionState? status;
    try {
      if (request != null) await request();
      await widget.refreshPermission();
    } catch (_) {
      error = 'Could not update reminders. Try again.';
    }
    // Show the actual permission even if scheduling failed after it was granted.
    try {
      status = await widget.readState();
    } catch (_) {
      error = 'Could not read notification settings. Try again.';
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
    String? error;
    try {
      if (!await widget.openSettings()) {
        error = 'Could not open Android settings.';
      }
    } catch (_) {
      error = 'Could not open Android settings.';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final description = switch (_status) {
      NotificationPermissionState.enabled =>
        'Allowed by Android for watering notifications.',
      NotificationPermissionState.requestable =>
        'Notifications are off. Allow reminders when your plants need water.',
      NotificationPermissionState.settingsRequired =>
        'Notifications are off. Enable them in Android settings.',
      NotificationPermissionState.channelBlocked =>
        'The watering notification category is off. Enable it in Android settings.',
      NotificationPermissionState.unsupported =>
        'Notifications are currently available on Android only.',
      null => 'Checking notification settings…',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notifications', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(description),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null) ...[
          Text(_error!),
          TextButton(
            onPressed: _busy ? null : _refresh,
            child: const Text('Retry'),
          ),
        ],
        if (_status == NotificationPermissionState.requestable)
          FilledButton(
            onPressed: _busy
                ? null
                : () => _refresh(request: widget.requestPermission),
            child: const Text('Allow notifications'),
          ),
        if (_status != null &&
            _status != NotificationPermissionState.unsupported)
          OutlinedButton(
            onPressed: _busy ? null : _openSettings,
            child: const Text('Open Android notification settings'),
          ),
      ],
    );
  }
}
