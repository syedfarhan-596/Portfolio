import 'package:flutter/material.dart';
import 'tokens.dart';

class AppTheme {
  static ThemeData _base(Brightness brightness, AppTokens tokens) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: tokens.accentB,
      brightness: brightness,
    ).copyWith(
      surface: tokens.bgBottom,
      error: tokens.danger,
    );

    final base = isDark ? ThemeData.dark() : ThemeData.light();

    TextStyle h(double size, FontWeight w, {double ls = -0.2, double? height}) =>
        TextStyle(
          fontSize: size,
          fontWeight: w,
          letterSpacing: ls,
          height: height,
          color: tokens.textHigh,
        );

    final textTheme = base.textTheme
        .copyWith(
          displayLarge: h(40, FontWeight.w800, ls: -1),
          displayMedium: h(34, FontWeight.w800, ls: -0.8),
          headlineLarge: h(28, FontWeight.w700, ls: -0.6),
          headlineMedium: h(24, FontWeight.w700, ls: -0.4),
          headlineSmall: h(20, FontWeight.w700, ls: -0.3),
          titleLarge: h(18, FontWeight.w600),
          titleMedium: h(16, FontWeight.w600),
          titleSmall: h(14, FontWeight.w600),
          bodyLarge: h(15, FontWeight.w500, ls: 0, height: 1.4),
          bodyMedium: h(14, FontWeight.w400, ls: 0, height: 1.45),
          bodySmall: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: tokens.textMid, height: 1.4),
          labelLarge: h(14, FontWeight.w600, ls: 0.1),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textMid, letterSpacing: 0.2),
        )
        .apply(displayColor: tokens.textHigh, bodyColor: tokens.textHigh);

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: scheme,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      extensions: [tokens],
      iconTheme: IconThemeData(color: tokens.textHigh, size: IconSizes.md),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get dark => _base(Brightness.dark, AppTokens.dark);
  static ThemeData get light => _base(Brightness.light, AppTokens.light);
}
