import 'package:flutter/material.dart';
import 'camill_theme_mode.dart';

/// テーマ固有のカラーパレット。ThemeExtensionとして全画面からアクセス可能。
class CamillColors extends ThemeExtension<CamillColors> {
  final Color background;
  final Color surface;
  final Color surfaceBorder;
  final Color primary;
  final Color primaryLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color navBackground;
  final Color navActive;
  final Color navInactive;
  final Color fabBackground;
  final Color fabIcon;
  final Color danger;
  final Color success;
  final Color accent;
  final Color accentLight;
  final bool isDark;

  const CamillColors({
    required this.background,
    required this.surface,
    required this.surfaceBorder,
    required this.primary,
    required this.primaryLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.navBackground,
    required this.navActive,
    required this.navInactive,
    required this.fabBackground,
    required this.fabIcon,
    required this.danger,
    required this.success,
    required this.accent,
    required this.accentLight,
    required this.isDark,
  });

  // ─── Midnight ────────────────────────────────────────────
  static const midnight = CamillColors(
    background: Color(0xFF0D1117),
    surface: Color(0xFF161B22),        // background に白4%を合成した不透明色
    surfaceBorder: Color(0x12FFFFFF),  // rgba(255,255,255,0.07)
    primary: Color(0xFF7EE8A2),
    primaryLight: Color(0x267EE8A2),   // rgba(126,232,162,0.15)
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0x99FFFFFF),  // rgba(255,255,255,0.6)
    textMuted: Color(0x59FFFFFF),      // rgba(255,255,255,0.35)
    navBackground: Color(0xF20D1117),  // rgba(13,17,23,0.95)
    navActive: Color(0xFF7EE8A2),
    navInactive: Color(0x59FFFFFF),
    fabBackground: Color(0xFF7EE8A2),
    fabIcon: Color(0xFF0D1117),
    danger: Color(0xFFFF6B6B),
    success: Color(0xFF4CAF50),
    accent: Color(0xFFFFB74D),
    accentLight: Color(0x26FFB74D),
    isDark: true,
  );

  // ─── Natural Soft ─────────────────────────────────────────
  static const natural = CamillColors(
    background: Color(0xFFF5F0E8),
    surface: Color(0xFFFCFAF8),        // background に白70%を合成した不透明色
    surfaceBorder: Color(0x33B4A08C),  // rgba(180,160,140,0.20)
    primary: Color(0xFF6AA864),
    primaryLight: Color(0x266AA864),   // rgba(106,168,100,0.15)
    textPrimary: Color(0xFF2D2420),
    textSecondary: Color(0x992D2420),  // rgba(45,36,32,0.60)
    textMuted: Color(0x592D2420),      // rgba(45,36,32,0.35)
    navBackground: Color(0xF2F5F0E8),  // rgba(245,240,232,0.95)
    navActive: Color(0xFF5A9E54),
    navInactive: Color(0x592D2420),
    fabBackground: Color(0xFF6AA864),
    fabIcon: Color(0xFFFFFFFF),
    danger: Color(0xFFFF6B6B),
    success: Color(0xFF4CAF50),
    accent: Color(0xFFE8A735),
    accentLight: Color(0x26E8A735),
    isDark: false,
  );

  // ─── Classic White ────────────────────────────────────────
  static const classic = CamillColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF8FAFF),
    surfaceBorder: Color(0x0F1A1A2E),  // rgba(26,26,46,0.06)
    primary: Color(0xFF2E6DA4),
    primaryLight: Color(0x142E6DA4),   // rgba(46,109,164,0.08)
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0x991A1A2E),  // rgba(26,26,46,0.60)
    textMuted: Color(0x591A1A2E),      // rgba(26,26,46,0.35)
    navBackground: Color(0xF5FFFFFF),  // rgba(255,255,255,0.96)
    navActive: Color(0xFF2E6DA4),
    navInactive: Color(0x591A1A2E),
    fabBackground: Color(0xFF2E6DA4),
    fabIcon: Color(0xFFFFFFFF),
    danger: Color(0xFFFF6B6B),
    success: Color(0xFF4CAF50),
    accent: Color(0xFFFF9800),
    accentLight: Color(0x14FF9800),
    isDark: false,
  );

  static CamillColors fromMode(CamillThemeMode mode) {
    switch (mode) {
      case CamillThemeMode.midnight:
      case CamillThemeMode.midnightCat:
        return CamillColors.midnight;
      case CamillThemeMode.natural:
      case CamillThemeMode.naturalCat:
        return CamillColors.natural;
      case CamillThemeMode.classic:
      case CamillThemeMode.classicCat:
        return CamillColors.classic;
    }
  }

  @override
  CamillColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceBorder,
    Color? primary,
    Color? primaryLight,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? navBackground,
    Color? navActive,
    Color? navInactive,
    Color? fabBackground,
    Color? fabIcon,
    Color? danger,
    Color? success,
    Color? accent,
    Color? accentLight,
    bool? isDark,
  }) =>
      CamillColors(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceBorder: surfaceBorder ?? this.surfaceBorder,
        primary: primary ?? this.primary,
        primaryLight: primaryLight ?? this.primaryLight,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
        navBackground: navBackground ?? this.navBackground,
        navActive: navActive ?? this.navActive,
        navInactive: navInactive ?? this.navInactive,
        fabBackground: fabBackground ?? this.fabBackground,
        fabIcon: fabIcon ?? this.fabIcon,
        danger: danger ?? this.danger,
        success: success ?? this.success,
        accent: accent ?? this.accent,
        accentLight: accentLight ?? this.accentLight,
        isDark: isDark ?? this.isDark,
      );

  @override
  CamillColors lerp(CamillColors? other, double t) {
    if (other == null) return this;
    return CamillColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      navActive: Color.lerp(navActive, other.navActive, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
      fabBackground: Color.lerp(fabBackground, other.fabBackground, t)!,
      fabIcon: Color.lerp(fabIcon, other.fabIcon, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// BuildContext拡張 - context.colors でどこからでも取得可能
extension CamillThemeX on BuildContext {
  CamillColors get colors => Theme.of(this).extension<CamillColors>()!;
}
