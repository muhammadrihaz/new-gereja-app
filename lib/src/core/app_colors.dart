import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color success;
  final Color danger;
  final Color warning;
  final Color info;
  final Color secondary;
  final Color gold;
  final Color warmSurface;

  const AppColors({
    required this.success,
    required this.danger,
    required this.warning,
    required this.info,
    required this.secondary,
    required this.gold,
    required this.warmSurface,
  });

  @override
  AppColors copyWith({
    Color? success,
    Color? danger,
    Color? warning,
    Color? info,
    Color? secondary,
    Color? gold,
    Color? warmSurface,
  }) {
    return AppColors(
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      secondary: secondary ?? this.secondary,
      gold: gold ?? this.gold,
      warmSurface: warmSurface ?? this.warmSurface,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      warmSurface: Color.lerp(warmSurface, other.warmSurface, t)!,
    );
  }
}
