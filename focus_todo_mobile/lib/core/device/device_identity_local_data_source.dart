import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/utils/uuid_generator.dart';

class DeviceIdentityLocalDataSource {
  static const String deviceIdKey = 'focus-todo-device-id';

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);
  }

  Future<String> getOrCreateDeviceId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(deviceIdKey);
    if (existing != null && _isUuid(existing)) {
      return existing;
    }

    final deviceId = UuidGenerator.generate();
    await preferences.setString(deviceIdKey, deviceId);
    return deviceId;
  }
}
