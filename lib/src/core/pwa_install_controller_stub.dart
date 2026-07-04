import 'package:flutter/foundation.dart';

class PwaInstallController extends ChangeNotifier {
  bool get canInstall => false;

  bool get isIOS => false;

  bool get isInstalled => false;

  bool get shouldShowIOSGuide => false;

  Future<void> initialize() async {}

  Future<void> promptInstall() async {}
}
