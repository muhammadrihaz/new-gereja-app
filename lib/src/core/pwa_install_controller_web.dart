import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';

@JS('window.__pwa.canInstall')
external bool get _jsCanInstall;

@JS('window.__pwa.installed')
external bool get _jsInstalled;

@JS('window.__pwa.isIOS')
external bool get _jsIsIOS;

@JS('window.pwaPollChanged')
external JSFunction get _pwaPollChangedRaw;

@JS('window.pwaPromptInstall')
external JSFunction get _pwaPromptInstallRaw;

class PwaInstallController extends ChangeNotifier {
  bool _isInitialized = false;
  Timer? _pollTimer;

  bool get canInstall => _jsCanInstall && !_jsInstalled;

  bool get isIOS => _jsIsIOS;

  bool get isInstalled => _jsInstalled;

  bool get shouldShowIOSGuide => _jsIsIOS && !_jsInstalled;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    _startPolling();
    notifyListeners();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_pollChanged()) {
        notifyListeners();
      }
    });
  }

  bool _pollChanged() {
    final result = _pwaPollChangedRaw.callAsFunction();
    return (result as JSBoolean?)?.toDart ?? false;
  }

  Future<void> promptInstall() async {
    _pwaPromptInstallRaw.callAsFunction();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
