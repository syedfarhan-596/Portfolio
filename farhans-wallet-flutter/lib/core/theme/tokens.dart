import 'package:flutter/material.dart';

/// ───────────────────────── Spacing (8pt grid) ─────────────────────────
class Insets {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 44;
}

/// ───────────────────────── Corner radius scale ────────────────────────
class Corners {
  static const double xs = 10;
  static const double sm = 14;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 30;
  static const double pill = 999;

  static BorderRadius br(double r) => BorderRadius.circular(r);
}

/// ───────────────────────── Blur (glass) tokens ────────────────────────
class Blurs {
  static const double subtle = 8;
  static const double card = 18;
  static const double heavy = 28;
  static const double nav = 24;
}

/// ───────────────────────── Motion tokens ──────────────────────────────
class Motion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 460);
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve spring = Curves.easeOutCubic;
}

/// ───────────────────────── Icon sizing ────────────────────────────────
class IconSizes {
  static const double sm = 18;
  static const double md = 22;
  static const double lg = 26;
}

/// Custom theme tokens exposed via [ThemeExtension] so nothing is hardcoded.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final Color bgTop;
  final Color bgBottom;
  final Color blobA;
  final Color blobB;
  final Color blobC;

  final Color glassFill;
  final Color glassFillStrong;
  final Color glassBorder;
  final Color glassHighlight;

  final Color textHigh;
  final Color textMid;
  final Color textLow;

  final Color accentA; // primary gradient start
  final Color accentB; // primary gradient end
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  final List<BoxShadow> softShadow;
  final List<BoxShadow> liftedShadow;

  const AppTokens({
    required this.bgTop,
    required this.bgBottom,
    required this.blobA,
    required this.blobB,
    required this.blobC,
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassBorder,
    required this.glassHighlight,
    required this.textHigh,
    required this.textMid,
    required this.textLow,
    required this.accentA,
    required this.accentB,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.softShadow,
    required this.liftedShadow,
  });

  LinearGradient get accentGradient => LinearGradient(
        colors: [accentA, accentB],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static const AppTokens dark = AppTokens(
    bgTop: Color(0xFF0B0B14),
    bgBottom: Color(0xFF101019),
    blobA: Color(0xFF6C5CE7),
    blobB: Color(0xFF1FB6A6),
    blobC: Color(0xFFE0568B),
    // Solid surface colors, not translucent — these used to be a thin white
    // wash meant to be diffused by a backdrop blur. With the blur gone (it
    // was costing real frame time on lower-end devices), a near-transparent
    // fill just let the background blobs show through and fight with text.
    glassFill: Color(0xFF201F30),
    glassFillStrong: Color(0xFF272638),
    glassBorder: Color(0x26FFFFFF),
    glassHighlight: Color(0x33FFFFFF),
    textHigh: Color(0xFFF3F3FA),
    textMid: Color(0xFFAEAEC6),
    textLow: Color(0xFF73738C),
    accentA: Color(0xFF8B7BFF),
    accentB: Color(0xFF6C5CE7),
    success: Color(0xFF31D9A6),
    warning: Color(0xFFFFC65C),
    danger: Color(0xFFFF6B6B),
    info: Color(0xFF5AA9FF),
    softShadow: [
      BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 12)),
    ],
    liftedShadow: [
      BoxShadow(color: Color(0x59000000), blurRadius: 40, offset: Offset(0, 20)),
    ],
  );

  static const AppTokens light = AppTokens(
    bgTop: Color(0xFFF6F7FC),
    bgBottom: Color(0xFFEEF0F8),
    blobA: Color(0xFF8B7BFF),
    blobB: Color(0xFF5BD6C2),
    blobC: Color(0xFFFF9BC0),
    // Solid, not translucent — same reasoning as the dark palette above.
    glassFill: Color(0xFFFFFFFF),
    glassFillStrong: Color(0xFFFFFFFF),
    glassBorder: Color(0x33FFFFFF),
    glassHighlight: Color(0x80FFFFFF),
    textHigh: Color(0xFF16161F),
    textMid: Color(0xFF5A5A6E),
    textLow: Color(0xFF8E8EA3),
    accentA: Color(0xFF7C5CFC),
    accentB: Color(0xFF6240E0),
    success: Color(0xFF12B886),
    warning: Color(0xFFE8A317),
    danger: Color(0xFFE5484D),
    info: Color(0xFF2F7DEB),
    softShadow: [
      BoxShadow(color: Color(0x14101038), blurRadius: 24, offset: Offset(0, 12)),
    ],
    liftedShadow: [
      BoxShadow(color: Color(0x1F101038), blurRadius: 36, offset: Offset(0, 18)),
    ],
  );

  @override
  AppTokens copyWith({
    Color? bgTop,
    Color? bgBottom,
    Color? blobA,
    Color? blobB,
    Color? blobC,
    Color? glassFill,
    Color? glassFillStrong,
    Color? glassBorder,
    Color? glassHighlight,
    Color? textHigh,
    Color? textMid,
    Color? textLow,
    Color? accentA,
    Color? accentB,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    List<BoxShadow>? softShadow,
    List<BoxShadow>? liftedShadow,
  }) {
    return AppTokens(
      bgTop: bgTop ?? this.bgTop,
      bgBottom: bgBottom ?? this.bgBottom,
      blobA: blobA ?? this.blobA,
      blobB: blobB ?? this.blobB,
      blobC: blobC ?? this.blobC,
      glassFill: glassFill ?? this.glassFill,
      glassFillStrong: glassFillStrong ?? this.glassFillStrong,
      glassBorder: glassBorder ?? this.glassBorder,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      textHigh: textHigh ?? this.textHigh,
      textMid: textMid ?? this.textMid,
      textLow: textLow ?? this.textLow,
      accentA: accentA ?? this.accentA,
      accentB: accentB ?? this.accentB,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      softShadow: softShadow ?? this.softShadow,
      liftedShadow: liftedShadow ?? this.liftedShadow,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      bgTop: Color.lerp(bgTop, other.bgTop, t)!,
      bgBottom: Color.lerp(bgBottom, other.bgBottom, t)!,
      blobA: Color.lerp(blobA, other.blobA, t)!,
      blobB: Color.lerp(blobB, other.blobB, t)!,
      blobC: Color.lerp(blobC, other.blobC, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassFillStrong: Color.lerp(glassFillStrong, other.glassFillStrong, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      textHigh: Color.lerp(textHigh, other.textHigh, t)!,
      textMid: Color.lerp(textMid, other.textMid, t)!,
      textLow: Color.lerp(textLow, other.textLow, t)!,
      accentA: Color.lerp(accentA, other.accentA, t)!,
      accentB: Color.lerp(accentB, other.accentB, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      softShadow: t < 0.5 ? softShadow : other.softShadow,
      liftedShadow: t < 0.5 ? liftedShadow : other.liftedShadow,
    );
  }
}

extension TokenContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get scheme => Theme.of(this).colorScheme;
}
