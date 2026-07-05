import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'src/core/app_colors.dart';
import 'src/core/api_client.dart';
import 'src/core/notification_badge_controller.dart';
import 'src/core/session_controller.dart';
import 'src/pages/home_router_page.dart';
import 'src/pages/login_page.dart';
import 'src/widgets/pwa_install_fab.dart';
import 'src/services/firebase_message_handler.dart' show setupFirebaseMessaging;

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  // Setup Firebase messaging handlers for push notifications
  setupFirebaseMessaging();
  runApp(const GerejaApp());
}

class GerejaApp extends StatefulWidget {
  const GerejaApp({super.key});

  @override
  State<GerejaApp> createState() => _GerejaAppState();
}

class _GerejaAppState extends State<GerejaApp> {
  late final SessionController _session;
  late final NotificationBadgeController _notificationBadge;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    const envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    final baseUrl = _resolveBaseUrl(envBaseUrl);
    final apiClient = ApiClient(baseUrl: baseUrl);
    _session = SessionController(apiClient: apiClient);
    _notificationBadge = NotificationBadgeController(apiClient: apiClient);
    // Keep the badge controller in sync with the session token.
    _session.addListener(_syncBadgeToken);
    _session.bootstrap();
    _loadThemePref();
  }

  void _syncBadgeToken() {
    _notificationBadge.setToken(_session.token);
  }

  Future<void> _loadThemePref() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDark = prefs.getBool('theme_dark');
    if (mounted && savedDark != null) {
      setState(() {
        _themeMode = savedDark ? ThemeMode.dark : ThemeMode.light;
      });
    }
  }

  String _resolveBaseUrl(String envBaseUrl) {
    final trimmed = envBaseUrl.trim();
    if (trimmed.isNotEmpty) return trimmed;

    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      final isLocalHost =
          host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0';

      if (isLocalHost) {
        return 'http://localhost:8081/api/v1';
      }

      // ✅ Production web → pakai subdomain API yang benar
      return 'http://116.212.73.88:8081/api/v1';
    }

    // Mobile/desktop emulator setup
    // Untuk testing di emulator lokal (BlueStacks dll), gunakan IP LAN Host tempat Docker berjalan
    // Pastikan mengganti kembali ke https://api.gereja-gpiyehuda.my.id/api/v1 jika mau production!
    return 'http://116.212.73.88:8081/api/v1';
  }

  @override
  void dispose() {
    _session.removeListener(_syncBadgeToken);
    _notificationBadge.dispose();
    _session.dispose();
    super.dispose();
  }

  void _setDarkMode(bool darkMode) async {
    setState(() {
      _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_dark', darkMode);
  }

  @override
  Widget build(BuildContext context) {
    final goldAccent = const Color(0xFFC9A84C);
    final goldAccentLight = const Color(0xFFF5EBCB);

    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0D3D3A),
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFFFFCF8),
      surfaceContainerLow: const Color(0xFFF8F5F0),
      surfaceContainer: const Color(0xFFF2EFEA),
      surfaceContainerHigh: const Color(0xFFEBE8E2),
      outlineVariant: const Color(0xFFDDD7CD),
      primary: const Color(0xFF0D3D3A),
      onPrimary: Colors.white,
      secondary: const Color(0xFF5C6B65),
      tertiary: goldAccent,
      surfaceTint: Colors.transparent,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0D3D3A),
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF1A1A1A),
      surfaceContainerLow: const Color(0xFF222222),
      surfaceContainer: const Color(0xFF2A2A2A),
      surfaceContainerHigh: const Color(0xFF333333),
      outlineVariant: const Color(0xFF3D3D3D),
      primary: const Color(0xFF8BBBB7),
      onPrimary: const Color(0xFF003734),
      tertiary: goldAccent,
      surfaceTint: Colors.transparent,
    );

    final outerRadius = BorderRadius.circular(20);
    final innerRadius = BorderRadius.circular(12);
    final cardShape = RoundedRectangleBorder(borderRadius: outerRadius);
    final inputBorderLight = OutlineInputBorder(
      borderRadius: innerRadius,
      borderSide: BorderSide(color: lightScheme.outlineVariant),
    );
    final inputBorderDark = OutlineInputBorder(
      borderRadius: innerRadius,
      borderSide: BorderSide(color: darkScheme.outlineVariant),
    );

    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'GPI Yehuda',
          themeMode: _themeMode,
          builder: (context, child) {
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                const PwaInstallFab(),
              ],
            );
          },
          theme: ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true,
            fontFamily: 'Poppins',
            scaffoldBackgroundColor: const Color(0xFFF8F5F0),
            extensions: const [
              AppColors(
                success: Color(0xFF059669),
                danger: Color(0xFFDC2626),
                warning: Color(0xFFD97706),
                info: Color(0xFF2563EB),
                secondary: Color(0xFF5C6B65),
                gold: Color(0xFFC9A84C),
                warmSurface: Color(0xFFF8F5F0),
              ),
            ],
            splashFactory: InkSparkle.splashFactory,
            appBarTheme: AppBarTheme(
              centerTitle: false,
              backgroundColor: lightScheme.surface,
              foregroundColor: lightScheme.onSurface,
              elevation: 0,
              scrolledUnderElevation: 1,
            ),
            dividerTheme: DividerThemeData(
              color: lightScheme.outlineVariant,
              thickness: 0.5,
              space: 0,
            ),
            cardTheme: CardThemeData(
              color: lightScheme.surface,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.06),
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: cardShape,
              clipBehavior: Clip.antiAlias,
            ),
            listTileTheme: ListTileThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              iconColor: lightScheme.primary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: lightScheme.surface,
              indicatorColor: Color.lerp(
                lightScheme.primaryContainer,
                goldAccentLight,
                0.3,
              ),
              surfaceTintColor: Colors.transparent,
              elevation: 2,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            ),
            drawerTheme: DrawerThemeData(
              backgroundColor: lightScheme.surface,
              shape: const RoundedRectangleBorder(),
              elevation: 2,
            ),
            dataTableTheme: DataTableThemeData(
              headingRowColor: WidgetStatePropertyAll(
                lightScheme.surfaceContainerHigh,
              ),
              headingTextStyle: TextStyle(
                color: lightScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              dividerThickness: 0.5,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 52,
              headingRowHeight: 48,
              horizontalMargin: 14,
              columnSpacing: 20,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: lightScheme.surface,
              border: inputBorderLight,
              enabledBorder: inputBorderLight,
              focusedBorder: OutlineInputBorder(
                borderRadius: innerRadius,
                borderSide: BorderSide(
                  color: lightScheme.primary,
                  width: 1.6,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              labelStyle: TextStyle(
                color: lightScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            iconButtonTheme: IconButtonThemeData(
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(borderRadius: innerRadius),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(borderRadius: innerRadius),
                side: BorderSide(color: lightScheme.outlineVariant),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            useMaterial3: true,
            fontFamily: 'Poppins',
            scaffoldBackgroundColor: const Color(0xFF1A1A1A),
            extensions: const [
              AppColors(
                success: Color(0xFF10B981),
                danger: Color(0xFFEF4444),
                warning: Color(0xFFF59E0B),
                info: Color(0xFF3B82F6),
                secondary: Color(0xFF64748B),
                gold: Color(0xFFC9A84C),
                warmSurface: Color(0xFF222222),
              ),
            ],
            splashFactory: InkSparkle.splashFactory,
            appBarTheme: AppBarTheme(
              centerTitle: false,
              backgroundColor: darkScheme.surface,
              foregroundColor: darkScheme.onSurface,
              elevation: 0,
              scrolledUnderElevation: 1,
            ),
            dividerTheme: DividerThemeData(
              color: darkScheme.outlineVariant,
              thickness: 0.5,
              space: 0,
            ),
            cardTheme: CardThemeData(
              color: darkScheme.surfaceContainerLow,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: cardShape,
              clipBehavior: Clip.antiAlias,
            ),
            listTileTheme: ListTileThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: darkScheme.surfaceContainerLow,
              selectedTileColor: darkScheme.surfaceContainerHigh,
              iconColor: darkScheme.primary,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: darkScheme.surface,
              indicatorColor: darkScheme.surfaceContainerHigh,
              surfaceTintColor: Colors.transparent,
              elevation: 2,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            ),
            drawerTheme: DrawerThemeData(
              backgroundColor: darkScheme.surface,
              shape: const RoundedRectangleBorder(),
              elevation: 2,
            ),
            dataTableTheme: DataTableThemeData(
              headingRowColor: const WidgetStatePropertyAll(Color(0xFF2A2A2A)),
              headingTextStyle: TextStyle(
                color: darkScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              dividerThickness: 0.5,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 52,
              headingRowHeight: 48,
              horizontalMargin: 14,
              columnSpacing: 20,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: darkScheme.surface,
              border: inputBorderDark,
              enabledBorder: inputBorderDark,
              focusedBorder: OutlineInputBorder(
                borderRadius: innerRadius,
                borderSide: BorderSide(
                  color: darkScheme.primary,
                  width: 1.6,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              labelStyle: TextStyle(
                color: darkScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            iconButtonTheme: IconButtonThemeData(
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(borderRadius: innerRadius),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(borderRadius: innerRadius),
                side: BorderSide(color: darkScheme.outlineVariant),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          home: _session.initializing
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : _session.isAuthenticated
              ? HomeRouterPage(
                  session: _session,
                  darkMode: _themeMode == ThemeMode.dark,
                  onThemeChanged: _setDarkMode,
                  notificationBadge: _notificationBadge,
                )
              : LoginPage(session: _session),
        );
      },
    );
  }
}
