import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/notification_badge_controller.dart';
import '../core/session_controller.dart';
import 'admin_dashboard_page.dart';
import 'jemaat_dashboard_page.dart';

class HomeRouterPage extends StatelessWidget {
  const HomeRouterPage({
    super.key,
    required this.session,
    required this.darkMode,
    required this.onThemeChanged,
    required this.notificationBadge,
  });

  final SessionController session;
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;
  final NotificationBadgeController notificationBadge;

  @override
  Widget build(BuildContext context) {
    if (session.role == UserRole.admin) {
      return AdminDashboardPage(
        session: session,
        darkMode: darkMode,
        onThemeChanged: onThemeChanged,
      );
    }

    return JemaatDashboardPage(
      session: session,
      darkMode: darkMode,
      onThemeChanged: onThemeChanged,
      notificationBadge: notificationBadge,
    );
  }
}
