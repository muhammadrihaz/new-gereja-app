// TODO: Google Sign In Backend Integration Guide
// This file outlines the steps needed to fully implement Google Sign In

/\*

- PHASE 1: Flutter/Frontend Setup
- Status: ✅ COMPLETE
-
- ✅ Created Environment configuration (lib/src/core/environment.dart)
- ✅ Added Google Sign In button to UI (lib/src/pages/login_page.dart)
- ✅ Setup local/production environment detection
- ✅ Added placeholder \_handleGoogleSignIn() function
- ✅ Implemented quick credential buttons for testing (local only)
-
- Location: lib/src/pages/login_page.dart (~line 430+)
- UI Button: "Atau lanjutkan dengan Google" (Or continue with Google)
- Current: Shows SnackBar "Coming Soon!" on tap
  \*/

/\*

- PHASE 2: Mobile SDK Setup & Dependency Installation
- Status: ⏳ PENDING
-
- Step 2.1: Add Google Sign In Package
- ─────────────────────────────────────────
-
- Option A: google_sign_in (Official, simpler for mobile)
- - Add to pubspec.yaml:
-     dependencies:
-       google_sign_in: ^6.1.0
-
- Option B: firebase_auth (More features, built-in Google provider)
- - Add to pubspec.yaml:
-     dependencies:
-       firebase_auth: ^4.0.0
-       firebase_core: ^2.0.0
-
- For this project, recommend: google_sign_in (simpler, no Firebase overhead)
-
-
- Step 2.2: Android Configuration
- ─────────────────────────────────────────
- For google_sign_in package:
-
- 1.  Get SHA-256 fingerprint:
- cd android/
- ./gradlew signingReport
-
- 2.  Go to Google Cloud Console:
- - Create/select project
- - Enable Google+ API
- - Create OAuth 2.0 credential (Android type)
- - Add package name: com.gpi.gereja_app_2
- - Add SHA-256 fingerprint from step 1
-
- 3.  Get Android Client ID from credentials
-
- 4.  Add to lib/src/core/environment.dart:
- static const String googleAndroidClientId = 'YOUR_ANDROID_CLIENT_ID';
-
- 5.  No additional Android code needed (google_sign_in handles it)
-
-
- Step 2.3: iOS Configuration
- ─────────────────────────────────────────
-
- 1.  Go to Google Cloud Console:
- - Create OAuth 2.0 credential (iOS type)
- - Bundle ID: com.gpi.gereja-app-2
- - Get iOS Client ID
- - Download GoogleService-Info.plist
-
- 2.  Add to Xcode:
- - Open ios/Runner.xcworkspace (NOT Runner.xcodeproj)
- - Drag GoogleService-Info.plist to Runner folder
- - Check "Copy items if needed" and "Runner" target
-
- 3.  Add URL Scheme:
- - Xcode: Runner > Info > URL Types
- - Add new URL Type
- - Identifier: com.googleusercontent.apps.[CLIENT_ID_PREFIX]
- - URL Schemes: com.googleusercontent.apps.[CLIENT_ID_PREFIX]
-
- 4.  Update Info.plist:
- <dict>
-      <key>CFBundleURLTypes</key>
-      <array>
-        <dict>
-          <key>CFBundleTypeRole</key>
-          <string>Editor</string>
-          <key>CFBundleURLSchemes</key>
-          <array>
-            <string>com.googleusercontent.apps.[CLIENT_ID_PREFIX]</string>
-          </array>
-        </dict>
-      </array>
- </dict>
-
- 5.  Add to lib/src/core/environment.dart:
- static const String googleIosClientId = 'YOUR_IOS_CLIENT_ID';
-
-
- Step 2.4: Web Configuration
- ─────────────────────────────────────────
-
- 1.  Go to Google Cloud Console:
- - Create OAuth 2.0 credential (Web type)
- - Authorized JavaScript origins:
-      http://localhost:3000
-      http://localhost:3001
-      https://your-production-domain.com
- - Authorized redirect URIs:
-      http://localhost:3000/
-      https://your-production-domain.com/
-
- 2.  Get Web Client ID
-
- 3.  Add to index.html (web/index.html):
- <meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
-
- Also add script before closing </head>:
- <script src="https://accounts.google.com/gsi/client" async defer></script>
-
- 4.  Add to lib/src/core/environment.dart:
- static const String googleWebClientId = 'YOUR_WEB_CLIENT_ID';
- \*/

/\*

- PHASE 3: Backend API Implementation
- Status: ⏳ PENDING
-
- Step 3.1: Create Google Sign In Controller
- ─────────────────────────────────────────
-
- File: api/app/Http/Controllers/GoogleAuthController.php
-
- ```php

  ```
- namespace App\Http\Controllers;
-
- use App\Models\User;
- use App\Models\UserDevice;
- use App\Support\ApiResponse;
- use Firebase\JWT\JWT;
- use Firebase\JWT\Key;
- use Illuminate\Http\JsonResponse;
- use Illuminate\Http\Request;
-
- class GoogleAuthController extends Controller
- {
-     use ApiResponse;
-
-     public function signIn(Request $request): JsonResponse
-     {
-         $token = $request->string('id_token')->toString();
-
-         try {
-             // Validate Google ID token
-             $client = new \Google\Client();
-             $client->setClientId(config('services.google.client_id'));
-             $ticket = $client->verifyIdToken($token);
-
-             if (!$ticket) {
-                 return $this->errorResponse(
-                     'Token Google tidak valid',
-                     'INVALID_GOOGLE_TOKEN',
-                     401
-                 );
-             }
-
-             $payload = $ticket->getPayload();
-             $googleId = $payload['sub'];
-             $email = $payload['email'];
-             $name = $payload['name'] ?? $email;
-
-             // Find or create user
-             $user = User::query()
-                 ->where('email', $email)
-                 ->orWhere('google_id', $googleId)
-                 ->first();
-
-             if (!$user) {
-                 // Create new user with JUST email (no KK required for Google)
-                 $user = User::query()->create([
-                     'name' => $name,
-                     'email' => $email,
-                     'google_id' => $googleId,
-                     'password' => bcrypt(Str::random()),
-                     'role' => 'jemaat',
-                     'status' => 'active',
-                 ]);
-             } else {
-                 // Link Google ID if not already linked
-                 if (!$user->google_id) {
-                     $user->update(['google_id' => $googleId]);
-                 }
-             }
-
-             // Store FCM token
-             UserDevice::query()->updateOrCreate(
-                 ['fcm_token' => $request->string('fcm_token')->toString()],
-                 [
-                     'user_id' => $user->id,
-                     'device_name' => $request->userAgent() ?? 'Unknown',
-                     'device_type' => 'mobile',
-                     'last_active' => now(),
-                 ]
-             );
-
-             $token = $user->createToken('google-auth-token')->plainTextToken;
-
-             return $this->successResponse([
-                 'token' => $token,
-                 'role' => $user->role,
-                 'user' => [
-                     'id' => $user->id,
-                     'name' => $user->name,
-                     'email' => $user->email,
-                 ],
-             ], 'Login Google berhasil', 200);
-         } catch (\Exception $e) {
-             return $this->errorResponse(
-                 'Autentikasi Google gagal',
-                 'GOOGLE_AUTH_ERROR',
-                 401
-             );
-         }
-     }
- }
- ```

  ```
-
- Step 3.2: Add Database Column
- ─────────────────────────────────────────
-
- File: api/database/migrations/YYYY_MM_DD_XXXXXX_add_google_id_to_users.php
-
- ```php

  ```
- public function up(): void
- {
-     Schema::table('users', function (Blueprint $table) {
-         $table->string('google_id')->nullable()->unique();
-     });
- }
-
- public function down(): void
- {
-     Schema::table('users', function (Blueprint $table) {
-         $table->dropColumn('google_id');
-     });
- }
- ```

  ```
-
- Step 3.3: Add Route
- ─────────────────────────────────────────
-
- File: api/routes/api.php
-
- ```php

  ```
- Route::post('/auth/google-signin', [GoogleAuthController::class, 'signIn']);
- ```

  ```
-
- Step 3.4: Add Config
- ─────────────────────────────────────────
-
- File: api/config/services.php (add to return array):
-
- ```php

  ```
- 'google' => [
-     'client_id' => env('GOOGLE_CLIENT_ID'),
-     'client_secret' => env('GOOGLE_CLIENT_SECRET'),
- ],
- ```

  ```
-
- Add to .env:
- ```

  ```
- GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID
- GOOGLE_CLIENT_SECRET=YOUR_GOOGLE_CLIENT_SECRET
- ```
  */
  ```

/\*

- PHASE 4: Flutter Implementation
- Status: ⏳ PENDING
-
- Step 4.1: Update \_handleGoogleSignIn() function
- ─────────────────────────────────────────
-
- Location: lib/src/pages/login_page.dart (~line 115)
-
- ```dart

  ```
- Future<void> \_handleGoogleSignIn() async {
- try {
-     final GoogleSignIn googleSignIn = GoogleSignIn(
-       clientId: kIsWeb ? Environment.googleWebClientId : null,
-       scopes: ['email', 'profile'],
-     );
-
-     final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
-
-     if (googleUser == null) {
-       return; // User cancelled sign-in
-     }
-
-     final GoogleSignInAuthentication googleAuth =
-         await googleUser.authentication;
-
-     // Send to backend
-     await widget.session.signInWithGoogle(
-       idToken: googleAuth.idToken!,
-       fcmToken: '<get from somewhere>',
-     );
-
- } catch (e) {
-     setState(() {
-       _error = 'Google Sign In gagal: ${e.toString()}';
-     });
- }
- }
- ```

  ```
-
- Step 4.2: Update SessionController
- ─────────────────────────────────────────
-
- File: lib/src/core/session_controller.dart
-
- Add new method:
- ```dart

  ```
- Future<void> signInWithGoogle({
- required String idToken,
- required String fcmToken,
- }) async {
- final response = await \_apiClient.post(
-     '/auth/google-signin',
-     body: {
-       'id_token': idToken,
-       'fcm_token': fcmToken,
-     },
- );
-
- // Handle response and save token/user data
- }
- ```

  ```
-
- Step 4.3: Add ApiClient method
- ─────────────────────────────────────────
-
- File: lib/src/core/api_client.dart
-
- The method already exists, just ensure it's available
  \*/

/\*

- PHASE 5: Testing
- Status: ⏳ PENDING
-
- Test Cases:
- 1.  ✅ UI: Google button visible and clickable
- 2.  ✅ UI: "Coming Soon" message on tap (current)
- 3.  ⏳ Backend: /api/v1/auth/google-signin endpoint exists
- 4.  ⏳ Backend: Validates Google ID token correctly
- 5.  ⏳ Backend: Creates user on first sign-in
- 6.  ⏳ Backend: Links existing user on subsequent sign-in
- 7.  ⏳ Backend: Returns valid authentication token
- 8.  ⏳ Web: Google sign-in works on web
- 9.  ⏳ Android: Google sign-in works on Android
- 10. ⏳ iOS: Google sign-in works on iOS
-
- Testing Command:
- ```bash

  ```
- # Test backend endpoint (after implementation)
- curl -X POST http://localhost:8080/api/v1/auth/google-signin \
- -H "Content-Type: application/json" \
- -d '{"id_token": "GOOGLE_ID_TOKEN_HERE", "fcm_token": "dummy123"}'
- ```
  */
  ```

/\*

- SUMMARY OF CHANGES NEEDED
- ═══════════════════════════════════════
-
- Frontend (Flutter): ✅ READY
- ├── Environment setup: ✅ Done
- ├── UI button: ✅ Done
- ├── Placeholder function: ✅ Done
- ├── google_sign_in package: ⏳ Install pubspec.yaml
- └── Implement \_handleGoogleSignIn(): ⏳ After backend ready
-
- Mobile SDKs: ⏳ PENDING
- ├── Android: Need SHA-256 fingerprint
- ├── iOS: Need GoogleService-Info.plist
- └── Web: Add meta tags & script to index.html
-
- Backend (Laravel): ⏳ PENDING
- ├── GoogleAuthController: ⏳ Create new file
- ├── Migration (google_id column): ⏳ Create
- ├── Route: ⏳ Add to api.php
- ├── Config: ⏳ Add to services.php & .env
- └── Tests: ⏳ Create test cases
-
- Integration: ⏳ PENDING
- ├── Frontend ↔ Backend: ⏳ Connect
- └── E2E Testing: ⏳ Validate all platforms
-
-
- RECOMMENDED NEXT STEPS
- ═══════════════════════════════════════
-
- 1.  Create Google Cloud Project and OAuth credentials
- Time: ~15 minutes
- Complexity: Low
-
- 2.  Add google_sign_in package to pubspec.yaml
- Time: ~5 minutes
- Complexity: Very Low
-
- 3.  Configure Android & iOS apps with Google credentials
- Time: ~30 minutes
- Complexity: Medium (certificates & configurations)
-
- 4.  Implement backend GoogleAuthController
- Time: ~45 minutes
- Complexity: Medium
-
- 5.  Create database migration
- Time: ~10 minutes
- Complexity: Low
-
- 6.  Implement Flutter \_handleGoogleSignIn()
- Time: ~20 minutes
- Complexity: Medium
-
- 7.  E2E Testing on all platforms
- Time: ~60 minutes
- Complexity: High (device/platform specific issues)
-
- TOTAL ESTIMATED TIME: ~3 hours
-
-
- REFERENCES & DOCUMENTATION
- ═══════════════════════════════════════
-
- - google_sign_in package:
- https://pub.dev/packages/google_sign_in
-
- - Google Cloud Console:
- https://console.cloud.google.com
-
- - Google Sign In for Flutter:
- https://developers.google.com/identity/protocols/oauth2
-
- - Firebase Admin SDK (for token validation):
- https://firebase.google.com/docs/auth/admin-sdk
-
- - Laravel Google Client:
- https://github.com/googleapis/google-api-php-client
  \*/
