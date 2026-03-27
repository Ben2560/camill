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

  // ════════════════════════════════════════════════════════════
  // ── フラットテーマ ──────────────────────────────────────────
  // ════════════════════════════════════════════════════════════

  // ─── Sakura Light (桜→春空) ───────────────────────────────
  static const _sakuraLight = CamillColors(
    background:    Color(0xFFFFF3F6),
    surface:       Color(0xFFFFFBFC),
    surfaceBorder: Color(0x10C06882),
    primary:       Color(0xFFC06882),
    primaryLight:  Color(0x14C06882),
    textPrimary:   Color(0xFF2A0F17),
    textSecondary: Color(0x992A0F17),
    textMuted:     Color(0x592A0F17),
    navBackground: Color(0xF2FFF3F6),
    navActive:     Color(0xFFC06882),
    navInactive:   Color(0x592A0F17),
    fabBackground: Color(0xFFC06882),
    fabIcon:       Color(0xFFFFFFFF),
    danger:        Color(0xFFE53935),
    success:       Color(0xFF558B2F),
    accent:        Color(0xFF7BA7D4),
    accentLight:   Color(0x147BA7D4),
    isDark:        false,
  );

  // ─── Sakura Dark (夜桜) ───────────────────────────────────
  static const _sakuraDark = CamillColors(
    background:    Color(0xFF170A0D),
    surface:       Color(0xFF25101A),
    surfaceBorder: Color(0x14FFFFFF),
    primary:       Color(0xFFFFAEC9),
    primaryLight:  Color(0x1AFFAEC9),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0x99FFFFFF),
    textMuted:     Color(0x59FFFFFF),
    navBackground: Color(0xF2170A0D),
    navActive:     Color(0xFFFFAEC9),
    navInactive:   Color(0x59FFFFFF),
    fabBackground: Color(0xFFFFAEC9),
    fabIcon:       Color(0xFF170A0D),
    danger:        Color(0xFFFF6B6B),
    success:       Color(0xFF8BC34A),
    accent:        Color(0xFF90CAF9),
    accentLight:   Color(0x1A90CAF9),
    isDark:        true,
  );

  // ─── Natural Light (既存 Natural Soft) ────────────────────
  static const _naturalLight = CamillColors(
    background:    Color(0xFFF5F0E8),
    surface:       Color(0xFFFCFAF8),
    surfaceBorder: Color(0x33B4A08C),
    primary:       Color(0xFF6AA864),
    primaryLight:  Color(0x266AA864),
    textPrimary:   Color(0xFF2D2420),
    textSecondary: Color(0x992D2420),
    textMuted:     Color(0x592D2420),
    navBackground: Color(0xF2F5F0E8),
    navActive:     Color(0xFF5A9E54),
    navInactive:   Color(0x592D2420),
    fabBackground: Color(0xFF6AA864),
    fabIcon:       Color(0xFFFFFFFF),
    danger:        Color(0xFFFF6B6B),
    success:       Color(0xFF4CAF50),
    accent:        Color(0xFFE8A735),
    accentLight:   Color(0x26E8A735),
    isDark:        false,
  );

  // ─── Natural Dark (夜間バリアント) ────────────────────────
  static const _naturalDark = CamillColors(
    background:    Color(0xFF181E16),
    surface:       Color(0xFF1F2A1D),
    surfaceBorder: Color(0x12FFFFFF),
    primary:       Color(0xFF7BB568),
    primaryLight:  Color(0x267BB568),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0x99FFFFFF),
    textMuted:     Color(0x59FFFFFF),
    navBackground: Color(0xF2181E16),
    navActive:     Color(0xFF7BB568),
    navInactive:   Color(0x59FFFFFF),
    fabBackground: Color(0xFF7BB568),
    fabIcon:       Color(0xFF181E16),
    danger:        Color(0xFFFF6B6B),
    success:       Color(0xFF66BB6A),
    accent:        Color(0xFFFFCA28),
    accentLight:   Color(0x26FFCA28),
    isDark:        true,
  );

  // ─── Classic Light (既存 Classic White) ───────────────────
  static const _classicLight = CamillColors(
    background:    Color(0xFFFFFFFF),
    surface:       Color(0xFFF8FAFF),
    surfaceBorder: Color(0x0F1A1A2E),
    primary:       Color(0xFF2E6DA4),
    primaryLight:  Color(0x142E6DA4),
    textPrimary:   Color(0xFF1A1A2E),
    textSecondary: Color(0x991A1A2E),
    textMuted:     Color(0x591A1A2E),
    navBackground: Color(0xF5FFFFFF),
    navActive:     Color(0xFF2E6DA4),
    navInactive:   Color(0x591A1A2E),
    fabBackground: Color(0xFF2E6DA4),
    fabIcon:       Color(0xFFFFFFFF),
    danger:        Color(0xFFFF6B6B),
    success:       Color(0xFF4CAF50),
    accent:        Color(0xFFFF9800),
    accentLight:   Color(0x14FF9800),
    isDark:        false,
  );

  // ─── Classic Dark (夜間バリアント, iOS dark風) ──────────────
  static const _classicDark = CamillColors(
    background:    Color(0xFF1C1C1E),
    surface:       Color(0xFF2C2C2E),
    surfaceBorder: Color(0x14FFFFFF),
    primary:       Color(0xFF5E9DD6),
    primaryLight:  Color(0x1A5E9DD6),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0x99FFFFFF),
    textMuted:     Color(0x59FFFFFF),
    navBackground: Color(0xF21C1C1E),
    navActive:     Color(0xFF5E9DD6),
    navInactive:   Color(0x59FFFFFF),
    fabBackground: Color(0xFF5E9DD6),
    fabIcon:       Color(0xFF1C1C1E),
    danger:        Color(0xFFFF453A),
    success:       Color(0xFF32D74B),
    accent:        Color(0xFFFF9F0A),
    accentLight:   Color(0x14FF9F0A),
    isDark:        true,
  );

  // ─── Deep Ocean Light ────────────────────────────────────
  static const _deepOceanLight = CamillColors(
    background:    Color(0xFFEEF4FB),
    surface:       Color(0xFFF8FBFF),
    surfaceBorder: Color(0x101A3A6E),
    primary:       Color(0xFF1565C0),
    primaryLight:  Color(0x141565C0),
    textPrimary:   Color(0xFF0D1B2E),
    textSecondary: Color(0x990D1B2E),
    textMuted:     Color(0x590D1B2E),
    navBackground: Color(0xF2EEF4FB),
    navActive:     Color(0xFF1565C0),
    navInactive:   Color(0x590D1B2E),
    fabBackground: Color(0xFF1565C0),
    fabIcon:       Color(0xFFFFFFFF),
    danger:        Color(0xFFE53935),
    success:       Color(0xFF43A047),
    accent:        Color(0xFF00ACC1),
    accentLight:   Color(0x1400ACC1),
    isDark:        false,
  );

  // ─── Deep Ocean Dark ─────────────────────────────────────
  static const _deepOceanDark = CamillColors(
    background:    Color(0xFF060D1C),
    surface:       Color(0xFF0D1A30),
    surfaceBorder: Color(0x12FFFFFF),
    primary:       Color(0xFF4FC3F7),
    primaryLight:  Color(0x264FC3F7),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0x99FFFFFF),
    textMuted:     Color(0x59FFFFFF),
    navBackground: Color(0xF2060D1C),
    navActive:     Color(0xFF4FC3F7),
    navInactive:   Color(0x59FFFFFF),
    fabBackground: Color(0xFF4FC3F7),
    fabIcon:       Color(0xFF060D1C),
    danger:        Color(0xFFFF6B6B),
    success:       Color(0xFF4CAF50),
    accent:        Color(0xFF00BCD4),
    accentLight:   Color(0x1400BCD4),
    isDark:        true,
  );

  // ─── Warm Sand Light ─────────────────────────────────────
  static const _warmSandLight = CamillColors(
    background:    Color(0xFFFAF6EF),
    surface:       Color(0xFFFFFDF8),
    surfaceBorder: Color(0x18C4A068),
    primary:       Color(0xFFBF8040),
    primaryLight:  Color(0x14BF8040),
    textPrimary:   Color(0xFF362918),
    textSecondary: Color(0x99362918),
    textMuted:     Color(0x59362918),
    navBackground: Color(0xF2FAF6EF),
    navActive:     Color(0xFFBF8040),
    navInactive:   Color(0x59362918),
    fabBackground: Color(0xFFBF8040),
    fabIcon:       Color(0xFFFFFFFF),
    danger:        Color(0xFFE53935),
    success:       Color(0xFF558B2F),
    accent:        Color(0xFFE65100),
    accentLight:   Color(0x14E65100),
    isDark:        false,
  );

  // ─── Warm Sand Dark ──────────────────────────────────────
  static const _warmSandDark = CamillColors(
    background:    Color(0xFF1A140C),
    surface:       Color(0xFF241D13),
    surfaceBorder: Color(0x12FFFFFF),
    primary:       Color(0xFFDDA85A),
    primaryLight:  Color(0x26DDA85A),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0x99FFFFFF),
    textMuted:     Color(0x59FFFFFF),
    navBackground: Color(0xF21A140C),
    navActive:     Color(0xFFDDA85A),
    navInactive:   Color(0x59FFFFFF),
    fabBackground: Color(0xFFDDA85A),
    fabIcon:       Color(0xFF1A140C),
    danger:        Color(0xFFFF6B6B),
    success:       Color(0xFF8BC34A),
    accent:        Color(0xFFFF9800),
    accentLight:   Color(0x14FF9800),
    isDark:        true,
  );

  // ─── Nordic Slate Light ──────────────────────────────────
  static const _nordicSlateLight = CamillColors(
    background:    Color(0xFFF0F2F5),
    surface:       Color(0xFFFAFAFC),
    surfaceBorder: Color(0x128B97C0),
    primary:       Color(0xFF5C6BC0),
    primaryLight:  Color(0x145C6BC0),
    textPrimary:   Color(0xFF1A1D2E),
    textSecondary: Color(0x991A1D2E),
    textMuted:     Color(0x591A1D2E),
    navBackground: Color(0xF2F0F2F5),
    navActive:     Color(0xFF5C6BC0),
    navInactive:   Color(0x591A1D2E),
    fabBackground: Color(0xFF5C6BC0),
    fabIcon:       Color(0xFFFFFFFF),
    danger:        Color(0xFFE53935),
    success:       Color(0xFF43A047),
    accent:        Color(0xFF00897B),
    accentLight:   Color(0x1400897B),
    isDark:        false,
  );

  // ─── Nordic Slate Dark ───────────────────────────────────
  static const _nordicSlateDark = CamillColors(
    background:    Color(0xFF111318),
    surface:       Color(0xFF1C1F26),
    surfaceBorder: Color(0x14FFFFFF),
    primary:       Color(0xFF7986CB),
    primaryLight:  Color(0x1A7986CB),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0x99FFFFFF),
    textMuted:     Color(0x59FFFFFF),
    navBackground: Color(0xF2111318),
    navActive:     Color(0xFF7986CB),
    navInactive:   Color(0x59FFFFFF),
    fabBackground: Color(0xFF7986CB),
    fabIcon:       Color(0xFF111318),
    danger:        Color(0xFFFF6B6B),
    success:       Color(0xFF66BB6A),
    accent:        Color(0xFF26C6DA),
    accentLight:   Color(0x1426C6DA),
    isDark:        true,
  );

  // ════════════════════════════════════════════════════════════
  // ── グラデーションテーマ ────────────────────────────────────
  // ════════════════════════════════════════════════════════════

  // ─── Aurora Light ────────────────────────────────────────
  static const _auroraLight = CamillColors(
    background:    Color(0xFFF8F5FF),
    surface:       Color(0xFFFCFAFF),
    surfaceBorder: Color(0x10B39DDB),
    primary:       Color(0xFF7C4DCA),
    primaryLight:  Color(0x147C4DCA),
    textPrimary:   Color(0xFF1A0D38),
    textSecondary: Color(0x991A0D38),
    textMuted:     Color(0x591A0D38),
    navBackground: Color(0xF2F8F5FF),
    navActive:     Color(0xFF7C4DCA),
    navInactive:   Color(0x591A0D38),
    fabBackground: Color(0xFF7C4DCA),
    fabIcon:       Color(0xFFFFFFFF),
    danger:        Color(0xFFE53935),
    success:       Color(0xFF43A047),
    accent:        Color(0xFF00BCD4),
    accentLight:   Color(0x1400BCD4),
    isDark:        false,
  );

  // ─── Aurora Dark ─────────────────────────────────────────
  static const _auroraDark = CamillColors(
    background:    Color(0xFF0A0714),
    surface:       Color(0xFF14102A),
    surfaceBorder: Color(0x14FFFFFF),
    primary:       Color(0xFFB39DDB),
    primaryLight:  Color(0x1AB39DDB),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0x99FFFFFF),
    textMuted:     Color(0x59FFFFFF),
    navBackground: Color(0xF20A0714),
    navActive:     Color(0xFFB39DDB),
    navInactive:   Color(0x59FFFFFF),
    fabBackground: Color(0xFFB39DDB),
    fabIcon:       Color(0xFF0A0714),
    danger:        Color(0xFFFF6B6B),
    success:       Color(0xFF66BB6A),
    accent:        Color(0xFF4DD0E1),
    accentLight:   Color(0x1A4DD0E1),
    isDark:        true,
  );

  // ─── Sunset Light ────────────────────────────────────────
  static const _sunsetLight = CamillColors(
    background:    Color(0xFFFFF9F5),
    surface:       Color(0xFFFFFCF8),
    surfaceBorder: Color(0x10FF8A65),
    primary:       Color(0xFFE64A19),
    primaryLight:  Color(0x14E64A19),
    textPrimary:   Color(0xFF2D1008),
    textSecondary: Color(0x992D1008),
    textMuted:     Color(0x592D1008),
    navBackground: Color(0xF2FFF9F5),
    navActive:     Color(0xFFE64A19),
    navInactive:   Color(0x592D1008),
    fabBackground: Color(0xFFE64A19),
    fabIcon:       Color(0xFFFFFFFF),
    danger:        Color(0xFFE53935),
    success:       Color(0xFF558B2F),
    accent:        Color(0xFFFF9800),
    accentLight:   Color(0x14FF9800),
    isDark:        false,
  );

  // ─── Sunset Dark ─────────────────────────────────────────
  static const _sunsetDark = CamillColors(
    background:    Color(0xFF130800),
    surface:       Color(0xFF220D00),
    surfaceBorder: Color(0x14FFFFFF),
    primary:       Color(0xFFFF8A65),
    primaryLight:  Color(0x1AFF8A65),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0x99FFFFFF),
    textMuted:     Color(0x59FFFFFF),
    navBackground: Color(0xF2130800),
    navActive:     Color(0xFFFF8A65),
    navInactive:   Color(0x59FFFFFF),
    fabBackground: Color(0xFFFF8A65),
    fabIcon:       Color(0xFF130800),
    danger:        Color(0xFFFF6B6B),
    success:       Color(0xFF8BC34A),
    accent:        Color(0xFFFFCA28),
    accentLight:   Color(0x26FFCA28),
    isDark:        true,
  );

  // ─── Ocean Wave Light (ティール) ─────────────────────────
  static const _oceanWaveLight = CamillColors(
    background:    Color(0xFFEFF8F8),
    surface:       Color(0xFFF7FCFC),
    surfaceBorder: Color(0x1200838F),
    primary:       Color(0xFF00838F),
    primaryLight:  Color(0x1400838F),
    textPrimary:   Color(0xFF012426),
    textSecondary: Color(0x99012426),
    textMuted:     Color(0x59012426),
    navBackground: Color(0xF2EFF8F8),
    navActive:     Color(0xFF00838F),
    navInactive:   Color(0x59012426),
    fabBackground: Color(0xFF00838F),
    fabIcon:       Color(0xFFFFFFFF),
    danger:        Color(0xFFE53935),
    success:       Color(0xFF43A047),
    accent:        Color(0xFFFF7043),
    accentLight:   Color(0x14FF7043),
    isDark:        false,
  );

  // ─── Ocean Wave Dark (ティール) ──────────────────────────
  static const _oceanWaveDark = CamillColors(
    background:    Color(0xFF001A1C),
    surface:       Color(0xFF002A2D),
    surfaceBorder: Color(0x14FFFFFF),
    primary:       Color(0xFF4DB6AC),
    primaryLight:  Color(0x1A4DB6AC),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0x99FFFFFF),
    textMuted:     Color(0x59FFFFFF),
    navBackground: Color(0xF2001A1C),
    navActive:     Color(0xFF4DB6AC),
    navInactive:   Color(0x59FFFFFF),
    fabBackground: Color(0xFF4DB6AC),
    fabIcon:       Color(0xFF001A1C),
    danger:        Color(0xFFFF6B6B),
    success:       Color(0xFF4CAF50),
    accent:        Color(0xFFFFB300),
    accentLight:   Color(0x26FFB300),
    isDark:        true,
  );

  // ─── Cherry Light (Apple Health風, ピンク→白) ─────────────
  static const _cherryLight = CamillColors(
    background:    Color(0xFFFFF5F8),
    surface:       Color(0xFFFFFAFC),
    surfaceBorder: Color(0x0FFF6B9D),
    primary:       Color(0xFFD81B60),
    primaryLight:  Color(0x14D81B60),
    textPrimary:   Color(0xFF25081A),
    textSecondary: Color(0x9925081A),
    textMuted:     Color(0x5925081A),
    navBackground: Color(0xF2FFF5F8),
    navActive:     Color(0xFFD81B60),
    navInactive:   Color(0x5925081A),
    fabBackground: Color(0xFFD81B60),
    fabIcon:       Color(0xFFFFFFFF),
    danger:        Color(0xFFE53935),
    success:       Color(0xFF43A047),
    accent:        Color(0xFFAB47BC),
    accentLight:   Color(0x14AB47BC),
    isDark:        false,
  );

  // ─── Cherry Dark ─────────────────────────────────────────
  static const _cherryDark = CamillColors(
    background:    Color(0xFF150109),
    surface:       Color(0xFF250315),
    surfaceBorder: Color(0x14FFFFFF),
    primary:       Color(0xFFFF80AB),
    primaryLight:  Color(0x1AFF80AB),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0x99FFFFFF),
    textMuted:     Color(0x59FFFFFF),
    navBackground: Color(0xF2150109),
    navActive:     Color(0xFFFF80AB),
    navInactive:   Color(0x59FFFFFF),
    fabBackground: Color(0xFFFF80AB),
    fabIcon:       Color(0xFF150109),
    danger:        Color(0xFFFF6B6B),
    success:       Color(0xFF66BB6A),
    accent:        Color(0xFFCE93D8),
    accentLight:   Color(0x1ACE93D8),
    isDark:        true,
  );

  // ─── Twilight Light ──────────────────────────────────────
  static const _twilightLight = CamillColors(
    background:    Color(0xFFF9F5FF),
    surface:       Color(0xFFFCFAFF),
    surfaceBorder: Color(0x10CE93D8),
    primary:       Color(0xFF8E24AA),
    primaryLight:  Color(0x148E24AA),
    textPrimary:   Color(0xFF180A24),
    textSecondary: Color(0x99180A24),
    textMuted:     Color(0x59180A24),
    navBackground: Color(0xF2F9F5FF),
    navActive:     Color(0xFF8E24AA),
    navInactive:   Color(0x59180A24),
    fabBackground: Color(0xFF8E24AA),
    fabIcon:       Color(0xFFFFFFFF),
    danger:        Color(0xFFE53935),
    success:       Color(0xFF43A047),
    accent:        Color(0xFFFF6E40),
    accentLight:   Color(0x14FF6E40),
    isDark:        false,
  );

  // ─── Twilight Dark ───────────────────────────────────────
  static const _twilightDark = CamillColors(
    background:    Color(0xFF0A0412),
    surface:       Color(0xFF170A24),
    surfaceBorder: Color(0x14FFFFFF),
    primary:       Color(0xFFCE93D8),
    primaryLight:  Color(0x1ACE93D8),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0x99FFFFFF),
    textMuted:     Color(0x59FFFFFF),
    navBackground: Color(0xF20A0412),
    navActive:     Color(0xFFCE93D8),
    navInactive:   Color(0x59FFFFFF),
    fabBackground: Color(0xFFCE93D8),
    fabIcon:       Color(0xFF0A0412),
    danger:        Color(0xFFFF6B6B),
    success:       Color(0xFF66BB6A),
    accent:        Color(0xFFFFAB40),
    accentLight:   Color(0x1AFFAB40),
    isDark:        true,
  );

  // ─── Emerald Light ───────────────────────────────────────
  static const _emeraldLight = CamillColors(
    background:    Color(0xFFF0FAF4),
    surface:       Color(0xFFF8FDFB),
    surfaceBorder: Color(0x1043A047),
    primary:       Color(0xFF2E7D32),
    primaryLight:  Color(0x142E7D32),
    textPrimary:   Color(0xFF071A0E),
    textSecondary: Color(0x99071A0E),
    textMuted:     Color(0x59071A0E),
    navBackground: Color(0xF2F0FAF4),
    navActive:     Color(0xFF2E7D32),
    navInactive:   Color(0x59071A0E),
    fabBackground: Color(0xFF2E7D32),
    fabIcon:       Color(0xFFFFFFFF),
    danger:        Color(0xFFE53935),
    success:       Color(0xFF43A047),
    accent:        Color(0xFF00838F),
    accentLight:   Color(0x1400838F),
    isDark:        false,
  );

  // ─── Emerald Dark ────────────────────────────────────────
  static const _emeraldDark = CamillColors(
    background:    Color(0xFF020F06),
    surface:       Color(0xFF071A0D),
    surfaceBorder: Color(0x14FFFFFF),
    primary:       Color(0xFF69F0AE),
    primaryLight:  Color(0x1A69F0AE),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0x99FFFFFF),
    textMuted:     Color(0x59FFFFFF),
    navBackground: Color(0xF2020F06),
    navActive:     Color(0xFF69F0AE),
    navInactive:   Color(0x59FFFFFF),
    fabBackground: Color(0xFF69F0AE),
    fabIcon:       Color(0xFF020F06),
    danger:        Color(0xFFFF6B6B),
    success:       Color(0xFF66BB6A),
    accent:        Color(0xFF26C6DA),
    accentLight:   Color(0x1A26C6DA),
    isDark:        true,
  );

  // ════════════════════════════════════════════════════════════
  // ── ファクトリ ──────────────────────────────────────────────
  // ════════════════════════════════════════════════════════════

  /// ベーステーマと日中/夜間フラグからカラーセットを返す
  static CamillColors fromBase(CamillThemeMode mode, {required bool isDark}) {
    switch (mode) {
      case CamillThemeMode.cherry:
        return isDark ? _cherryDark      : _cherryLight;
      case CamillThemeMode.sunset:
        return isDark ? _sunsetDark      : _sunsetLight;
      case CamillThemeMode.warmSand:
        return isDark ? _warmSandDark    : _warmSandLight;
      case CamillThemeMode.natural:
        return isDark ? _naturalDark     : _naturalLight;
      case CamillThemeMode.emerald:
        return isDark ? _emeraldDark     : _emeraldLight;
      case CamillThemeMode.sakura:
        return isDark ? _sakuraDark      : _sakuraLight;
      case CamillThemeMode.oceanWave:
        return isDark ? _oceanWaveDark   : _oceanWaveLight;
      case CamillThemeMode.classic:
        return isDark ? _classicDark     : _classicLight;
      case CamillThemeMode.deepOcean:
        return isDark ? _deepOceanDark   : _deepOceanLight;
      case CamillThemeMode.nordicSlate:
        return isDark ? _nordicSlateDark : _nordicSlateLight;
      case CamillThemeMode.aurora:
        return isDark ? _auroraDark      : _auroraLight;
      case CamillThemeMode.twilight:
        return isDark ? _twilightDark    : _twilightLight;
    }
  }

  /// auth画面用: Natural Soft ライトバリアント
  static CamillColors get naturalLight => _naturalLight;

  // ════════════════════════════════════════════════════════════
  // ── ThemeExtension boilerplate ─────────────────────────────
  // ════════════════════════════════════════════════════════════

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
        background:    background    ?? this.background,
        surface:       surface       ?? this.surface,
        surfaceBorder: surfaceBorder ?? this.surfaceBorder,
        primary:       primary       ?? this.primary,
        primaryLight:  primaryLight  ?? this.primaryLight,
        textPrimary:   textPrimary   ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted:     textMuted     ?? this.textMuted,
        navBackground: navBackground ?? this.navBackground,
        navActive:     navActive     ?? this.navActive,
        navInactive:   navInactive   ?? this.navInactive,
        fabBackground: fabBackground ?? this.fabBackground,
        fabIcon:       fabIcon       ?? this.fabIcon,
        danger:        danger        ?? this.danger,
        success:       success       ?? this.success,
        accent:        accent        ?? this.accent,
        accentLight:   accentLight   ?? this.accentLight,
        isDark:        isDark        ?? this.isDark,
      );

  @override
  CamillColors lerp(CamillColors? other, double t) {
    if (other == null) return this;
    return CamillColors(
      background:    Color.lerp(background,    other.background,    t)!,
      surface:       Color.lerp(surface,       other.surface,       t)!,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t)!,
      primary:       Color.lerp(primary,       other.primary,       t)!,
      primaryLight:  Color.lerp(primaryLight,  other.primaryLight,  t)!,
      textPrimary:   Color.lerp(textPrimary,   other.textPrimary,   t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted:     Color.lerp(textMuted,     other.textMuted,     t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      navActive:     Color.lerp(navActive,     other.navActive,     t)!,
      navInactive:   Color.lerp(navInactive,   other.navInactive,   t)!,
      fabBackground: Color.lerp(fabBackground, other.fabBackground, t)!,
      fabIcon:       Color.lerp(fabIcon,       other.fabIcon,       t)!,
      danger:        Color.lerp(danger,        other.danger,        t)!,
      success:       Color.lerp(success,       other.success,       t)!,
      accent:        Color.lerp(accent,        other.accent,        t)!,
      accentLight:   Color.lerp(accentLight,   other.accentLight,   t)!,
      isDark:        t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// BuildContext拡張 - context.colors でどこからでも取得可能
extension CamillThemeX on BuildContext {
  CamillColors get colors => Theme.of(this).extension<CamillColors>()!;
}
