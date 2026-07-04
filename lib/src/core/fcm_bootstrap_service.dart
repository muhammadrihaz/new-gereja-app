import 'device_identity.dart';

class FcmBootstrapResult {
  const FcmBootstrapResult({
    required this.token,
    required this.isDummy,
    required this.source,
  });

  final String token;
  final bool isDummy;
  final String source;
}

class FcmBootstrapService {
  Future<FcmBootstrapResult> resolveToken({String? preferredToken}) async {
    if (preferredToken != null && preferredToken.trim().length >= 20) {
      return FcmBootstrapResult(
        token: preferredToken.trim(),
        isDummy: false,
        source: 'manual_override',
      );
    }

    final token = await DeviceIdentity.getDeviceToken();
    return FcmBootstrapResult(
      token: token,
      isDummy: true,
      source: 'dummy_device_identity',
    );
  }
}
