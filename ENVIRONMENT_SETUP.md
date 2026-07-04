# Environment Configuration & Google Sign In Setup

## Overview

This document outlines the environment configuration system and Google Sign In integration for the Gereja App. The app supports Local and Production environments with different credentials for testing purposes.

## Environment Setup

### Local Environment

**When**: Debug mode on your local machine  
**Credentials**: Auto-filled for easy testing

**Login Tab** - Auto-filled credentials:

- Email: `admin@example.com`
- Password: `password123`
- Role: Admin

**Quick Switch Buttons** (Local only):

- Click "Admin" button to switch to admin credentials
- Click "Jemaat" button to switch to jemaat credentials (will be used for member testing)

### Production Environment

**When**: Release/production builds  
**Features**: No auto-fill, all normal authentication flows

## How It Works

### Environment Detection

The app automatically detects environment based on build mode:

```dart
// In lib/src/core/environment.dart
static AppEnvironment get current {
  if (kDebugMode) {
    return AppEnvironment.local;
  }
  return AppEnvironment.production;
}
```

- **Debug Mode** → Local Environment (auto-fill enabled)
- **Release Mode** → Production Environment (auto-fill disabled)

### Local Development Credentials

Located in `lib/src/core/environment.dart`:

```dart
static const String localAdminEmail = 'admin@example.com';
static const String localAdminPassword = 'password123';
static const String localJemaatEmail = 'jemaat@example.com';
static const String localJemaatPassword = 'password123';
```

These credentials are **ONLY** visible and used in local development. They are completely stripped out in production builds.

## Google Sign In Integration

### Current Status

- ✅ UI Button Added
- ⏳ API Integration: Pending
- ⏳ Mobile SDKs Setup: Pending

### UI Implementation

**Location**: `lib/src/pages/login_page.dart` - "Atau lanjutkan dengan" section

**Button Features**:

- Shows "Atau lanjutkan dengan" (Or continue with) header
- Google sign-in button with Google icon
- Currently shows "Coming Soon" SnackBar on tap
- Placeholder for future implementation

### Placeholder Function

```dart
Future<void> _handleGoogleSignIn() async {
  // TODO: Implement Google Sign In logic
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Google Sign In - Coming Soon!'),
      duration: Duration(seconds: 2),
    ),
  );
}
```

### Future Implementation Steps

1. **Add Google Sign In Package** (to pubspec.yaml):
   - `google_sign_in: ^6.1.0` (for mobile/web)
   - Alternatively: `firebase_auth: ^4.0.0` with Google provider

2. **Web Setup**:
   - Register OAuth 2.0 credentials at Google Cloud Console
   - Add Web Client ID to `environment.dart`
   - Configure authorized redirect URIs

3. **Android Setup**:
   - Upload app SHA-256 fingerprint to Google Cloud Console
   - Add Android Client ID to `environment.dart`

4. **iOS Setup**:
   - Download `GoogleService-Info.plist` from Firebase
   - Add to Xcode project

5. **Implementation**:
   - Call Google Sign In when button pressed
   - Exchange Google ID token for custom auth token from backend
   - Store token in SessionController
   - Redirect to appropriate dashboard

6. **Backend API** (Optional):
   - Create `/api/v1/auth/google-signin` endpoint
   - Validate Google ID token
   - Create or link user account
   - Return app authentication token

## Project Structure

```
lib/src/core/
├── environment.dart        ← Environment configuration
├── session_controller.dart ← Auth state management
└── api_client.dart         ← API communication

lib/src/pages/
└── login_page.dart         ← Google Sign In UI button
```

## Quick Reference

### Adding New Local Dev Features

Edit `lib/src/core/environment.dart`:

```dart
class Environment {
  // Add new credential pairs for testing
  static const String localTestEmail = 'test@example.com';
  static const String localTestPassword = 'test123';
}
```

Then add quick button in `login_page.dart` if needed.

### Building for Production

```bash
# Create production build (auto-fill disabled)
flutter build apk --release
flutter build ios --release
flutter build web --release
```

Auto-fill will NOT appear in release builds due to `kDebugMode` check.

### Checking Current Environment

Add this debug widget to any page:

```dart
Container(
  color: Environment.isLocal ? Colors.yellow : Colors.green,
  child: Text(Environment.isLocal ? 'LOCAL' : 'PRODUCTION'),
)
```

## Security Notes

✅ **Safe**:

- Local credentials only visible in debug mode
- Environment constants are compile-time constants
- No secrets hardcoded for production

⚠️ **Remember**:

- Never use these test credentials in real accounts
- Always use strong passwords in production
- Rotate Google OAuth credentials annually
- Use environment variables for production at deployment

## Next Steps

1. [ ] Add `google_sign_in` package to `pubspec.yaml`
2. [ ] Register Google OAuth credentials in Google Cloud Console
3. [ ] Implement `_handleGoogleSignIn()` function
4. [ ] Create backend endpoint `/api/v1/auth/google-signin`
5. [ ] Test on web (easiest), then mobile
6. [ ] Test on production credentials
7. [ ] Update this document with final implementation details

---

**Last Updated**: March 28, 2026  
**Status**: UI & Environment Setup Complete ✅ • API Pending ⏳
