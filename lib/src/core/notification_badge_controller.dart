import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Small ValueNotifier-backed controller that polls the unread notification
/// count for the current user and exposes it to the Bottom Navigation.
///
/// - Automatically pauses polling when the app has no auth token.
/// - Coalesces rapid `refresh()` calls to avoid hammering the API.
/// - Failures are silent (badge simply stops updating) to keep the UI stable.
class NotificationBadgeController extends ChangeNotifier {
  NotificationBadgeController({
    required this.apiClient,
    this.pollInterval = const Duration(seconds: 60),
  });

  final ApiClient apiClient;
  final Duration pollInterval;

  int _count = 0;
  String? _token;
  Timer? _timer;
  bool _fetching = false;

  int get count => _count;

  void setToken(String? token) {
    if (_token == token) return;
    _token = token;
    if (token == null || token.isEmpty) {
      _count = 0;
      _stopTimer();
      notifyListeners();
      return;
    }
    // First refresh immediately; subsequent every pollInterval.
    refresh();
    _startTimer();
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(pollInterval, (_) => refresh());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Force refresh (e.g. after user opens the notification page).
  Future<void> refresh() async {
    final token = _token;
    if (token == null || token.isEmpty || _fetching) return;
    _fetching = true;
    try {
      final n = await apiClient.notificationUnreadCount(token: token);
      if (n != _count) {
        _count = n;
        notifyListeners();
      }
    } catch (_) {
      // Silent failure; badge simply won't update this cycle.
    } finally {
      _fetching = false;
    }
  }

  /// Locally clear the badge (optimistic update after mark-all-read).
  void clearLocally() {
    if (_count != 0) {
      _count = 0;
      notifyListeners();
    }
  }

  /// Decrement by 1 (optimistic update after mark-one-read).
  void decrement() {
    if (_count > 0) {
      _count = _count - 1;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
