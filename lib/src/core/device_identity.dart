import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdentity {
  DeviceIdentity._();

  static const String _deviceTokenKey = 'device_token';

  static Future<String> getDeviceToken({String? preferred}) async {
    if (preferred != null && preferred.trim().length >= 20) {
      return preferred.trim();
    }

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceTokenKey);
    if (existing != null && existing.length >= 20) {
      return existing;
    }

    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final value = List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
    final token = 'dev-$value';
    await prefs.setString(_deviceTokenKey, token);
    return token;
  }

  static String get deviceType {
    if (kIsWeb) {
      return 'web';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'web';
    }
  }
}
