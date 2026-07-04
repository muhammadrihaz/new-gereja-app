import 'package:flutter/material.dart';

class ChurchLogo extends StatelessWidget {
  const ChurchLogo({
    super.key,
    this.logo,
    required this.isDark,
    this.height = 88,
  });

  final Map<String, dynamic>? logo;
  final bool isDark;
  final double height;

  @override
  Widget build(BuildContext context) {
    final logoUrl = (logo?['url'] as String?)?.trim();

    if (logoUrl != null && logoUrl.isNotEmpty) {
      return Image.network(
        logoUrl,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _fallbackImage(),
      );
    }

    return _fallbackImage();
  }

  Widget _fallbackImage() {
    return Image.asset(
      isDark ? 'assets/image/logo_2.png' : 'assets/image/logo_1.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
