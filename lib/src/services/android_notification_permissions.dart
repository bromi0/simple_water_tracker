import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

enum NotificationPermissionState {
  unsupported,
  enabled,
  requestable,
  settingsRequired,
  channelBlocked,
}

/// Android policy only. An iOS implementation will need its own authorization
/// states and settings flow rather than reusing Android's denial semantics.
class AndroidNotificationPermissions {
  AndroidNotificationPermissions(this.plugin);

  final AndroidFlutterLocalNotificationsPlugin plugin;
  static const channelId = 'mainChannel';
  static const _settings = MethodChannel(
    'com.bromiapps.simplywaterplant/notification_settings',
  );

  Future<bool> isGranted() async {
    if (await plugin.areNotificationsEnabled() != true) return false;
    return !await _channelBlocked();
  }

  Future<bool> _channelBlocked() async {
    final channels = await plugin.getNotificationChannels();
    return channels?.any(
          (channel) =>
              channel.id == channelId && channel.importance == Importance.none,
        ) ??
        false;
  }

  Future<NotificationPermissionState> read() async {
    if (await plugin.areNotificationsEnabled() == true) {
      return await _channelBlocked()
          ? NotificationPermissionState.channelBlocked
          : NotificationPermissionState.enabled;
    }
    final sdk = await _settings.invokeMethod<int>('sdkVersion');
    final status = await Permission.notification.status;
    return sdk != null && sdk >= 33 && !status.isPermanentlyDenied
        ? NotificationPermissionState.requestable
        : NotificationPermissionState.settingsRequired;
  }

  Future<bool> request() async {
    if (await read() == NotificationPermissionState.requestable) {
      // Use the same plugin for status and requests so permanent denial tracking
      // stays consistent. The notification delivery plugin still owns alarms.
      await Permission.notification.request();
    }
    return isGranted();
  }

  Future<bool> openSettings() async =>
      await _settings.invokeMethod<bool>('openSettings') ?? false;
}
