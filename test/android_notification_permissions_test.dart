import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_water_tracker/src/services/android_notification_permissions.dart';

class _AndroidPlugin extends AndroidFlutterLocalNotificationsPlugin {
  bool enabled = false;
  bool blocked = false;

  @override
  Future<bool?> areNotificationsEnabled() async => enabled;

  @override
  Future<List<AndroidNotificationChannel>?> getNotificationChannels() async => [
    AndroidNotificationChannel(
      AndroidNotificationPermissions.channelId,
      'Watering',
      importance: blocked ? Importance.none : Importance.high,
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _AndroidPlugin plugin;
  late AndroidNotificationPermissions permissions;
  var sdk = 33;
  var deniedStatus = 0;
  var requests = 0;

  setUp(() {
    plugin = _AndroidPlugin();
    permissions = AndroidNotificationPermissions(plugin);
    sdk = 33;
    deniedStatus = 0;
    requests = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(
            'com.bromiapps.simplywaterplant/notification_settings',
          ),
          (call) async => call.method == 'sdkVersion' ? sdk : true,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (call) async {
            if (call.method == 'requestPermissions') {
              requests++;
              plugin.enabled = true;
              return {17: 1};
            }
            return deniedStatus;
          },
        );
  });

  test(
    'Android 13 permission can be requested and OS state is reread',
    () async {
      expect(await permissions.read(), NotificationPermissionState.requestable);
      expect(await permissions.request(), isTrue);
      expect(requests, 1);
      expect(await permissions.read(), NotificationPermissionState.enabled);
    },
  );

  test('permanent denial routes to settings without another prompt', () async {
    deniedStatus = 4;
    expect(
      await permissions.read(),
      NotificationPermissionState.settingsRequired,
    );
    expect(await permissions.request(), isFalse);
    expect(requests, 0);
    expect(await permissions.openSettings(), isTrue);
  });

  test('pre-Android 13 disabled notifications require settings', () async {
    sdk = 32;
    expect(
      await permissions.read(),
      NotificationPermissionState.settingsRequired,
    );
    expect(await permissions.request(), isFalse);
    expect(requests, 0);
  });

  test('channel blocking is distinct from app permission', () async {
    plugin.enabled = true;
    plugin.blocked = true;
    expect(
      await permissions.read(),
      NotificationPermissionState.channelBlocked,
    );
    expect(await permissions.isGranted(), isFalse);
    expect(await permissions.request(), isFalse);
    expect(requests, 0);
    plugin.blocked = false;
    expect(await permissions.isGranted(), isTrue);
  });
}
