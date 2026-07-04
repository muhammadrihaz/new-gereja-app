import 'package:flutter/foundation.dart';

enum AppEnvironment { local, production }

class Environment {
  static AppEnvironment get current {
    // In debug mode, assume local environment unless explicitly set to production
    if (kDebugMode) {
      return AppEnvironment.local;
    }
    return AppEnvironment.production;
  }

  static bool get isLocal => current == AppEnvironment.local;
  static bool get isProduction => current == AppEnvironment.production;

  // Local development credentials for autofill
  static const String localAdminEmail = 'admin@example.com';
  static const String localAdminPassword = 'password123';
  static const String localJemaatEmail = 'jemaat@example.com';
  static const String localJemaatPassword = 'password123';

  // Google OAuth credentials (setup later)
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
  static const String googleWebClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID';
}
