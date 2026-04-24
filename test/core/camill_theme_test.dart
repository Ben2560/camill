import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camill/core/theme/camill_theme_mode.dart';
import 'package:camill/core/theme/camill_colors.dart';
import 'package:camill/core/theme/camill_theme.dart';

// GoogleFonts のフォントファイル未取得エラーをテスト内で無視する
bool _isFontLoadError(Object e) =>
    e.toString().contains('GoogleFonts') ||
    e.toString().contains('google_fonts') ||
    e.toString().contains('Failed to load font');

Future<void> _run(Future<void> Function() fn) =>
    runZonedGuarded(fn, (e, _) {
      if (!_isFontLoadError(e)) throw e;
    })!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─────────────────────────────────────────
  // CamillThemeData.build()
  // ─────────────────────────────────────────
  group('CamillThemeData.build()', () {
    test('非 null の ThemeData を返す', () async {
      await _run(() async {
        final colors =
            CamillColors.fromBase(CamillThemeMode.sakura, isDark: false);
        expect(CamillThemeData.build(colors), isA<ThemeData>());
      });
    });

    test('scaffoldBackgroundColor が colors.background と一致', () async {
      await _run(() async {
        final colors =
            CamillColors.fromBase(CamillThemeMode.classic, isDark: false);
        final theme = CamillThemeData.build(colors);
        expect(theme.scaffoldBackgroundColor, colors.background);
      });
    });

    test('CamillColors extension が登録されている', () async {
      await _run(() async {
        final colors =
            CamillColors.fromBase(CamillThemeMode.aurora, isDark: false);
        final theme = CamillThemeData.build(colors);
        final ext = theme.extensions[CamillColors];
        expect(ext, isNotNull);
      });
    });

    test('colorScheme.primary が colors.primary と一致', () async {
      await _run(() async {
        final colors =
            CamillColors.fromBase(CamillThemeMode.emerald, isDark: false);
        final theme = CamillThemeData.build(colors);
        expect(theme.colorScheme.primary, colors.primary);
      });
    });

    test('colorScheme.surface が colors.surface と一致', () async {
      await _run(() async {
        final colors =
            CamillColors.fromBase(CamillThemeMode.deepOcean, isDark: true);
        final theme = CamillThemeData.build(colors);
        expect(theme.colorScheme.surface, colors.surface);
      });
    });

    test('colorScheme.error が colors.danger と一致', () async {
      await _run(() async {
        final colors =
            CamillColors.fromBase(CamillThemeMode.natural, isDark: false);
        final theme = CamillThemeData.build(colors);
        expect(theme.colorScheme.error, colors.danger);
      });
    });

    test('dividerColor が colors.surfaceBorder と一致', () async {
      await _run(() async {
        final colors =
            CamillColors.fromBase(CamillThemeMode.nordicSlate, isDark: false);
        final theme = CamillThemeData.build(colors);
        expect(theme.dividerColor, colors.surfaceBorder);
      });
    });

    test('isDark=true で Brightness.dark', () async {
      await _run(() async {
        final colors =
            CamillColors.fromBase(CamillThemeMode.deepOcean, isDark: true);
        final theme = CamillThemeData.build(colors);
        expect(theme.brightness, Brightness.dark);
      });
    });

    test('isDark=false で Brightness.light', () async {
      await _run(() async {
        final colors =
            CamillColors.fromBase(CamillThemeMode.sakura, isDark: false);
        final theme = CamillThemeData.build(colors);
        expect(theme.brightness, Brightness.light);
      });
    });

    test('appBarTheme.backgroundColor が colors.background と一致', () async {
      await _run(() async {
        final colors =
            CamillColors.fromBase(CamillThemeMode.twilight, isDark: false);
        final theme = CamillThemeData.build(colors);
        expect(theme.appBarTheme.backgroundColor, colors.background);
      });
    });

    test('tabBarTheme.labelColor が colors.primary と一致', () async {
      await _run(() async {
        final colors =
            CamillColors.fromBase(CamillThemeMode.cherry, isDark: false);
        final theme = CamillThemeData.build(colors);
        expect(theme.tabBarTheme.labelColor, colors.primary);
      });
    });
  });

  // ─────────────────────────────────────────
  // camillAmountStyle / camillHeadingStyle / camillBodyStyle
  // ─────────────────────────────────────────
  group('camillAmountStyle', () {
    test('fontSize が設定される', () async {
      await _run(() async {
        final style = camillAmountStyle(24, Colors.black);
        expect(style.fontSize, 24);
      });
    });

    test('FontWeight.w700 が設定される', () async {
      await _run(() async {
        final style = camillAmountStyle(16, Colors.red);
        expect(style.fontWeight, FontWeight.w700);
      });
    });

    test('color が設定される', () async {
      await _run(() async {
        final style = camillAmountStyle(12, Colors.blue);
        expect(style.color, Colors.blue);
      });
    });
  });

  group('camillHeadingStyle', () {
    test('fontSize が設定される', () async {
      await _run(() async {
        final style = camillHeadingStyle(18, Colors.black);
        expect(style.fontSize, 18);
      });
    });

    test('FontWeight.w700 が設定される', () async {
      await _run(() async {
        final style = camillHeadingStyle(20, Colors.black);
        expect(style.fontWeight, FontWeight.w700);
      });
    });
  });

  group('camillBodyStyle', () {
    test('デフォルトは FontWeight.w400', () async {
      await _run(() async {
        final style = camillBodyStyle(14, Colors.black);
        expect(style.fontWeight, FontWeight.w400);
      });
    });

    test('weight を上書きできる', () async {
      await _run(() async {
        final style =
            camillBodyStyle(14, Colors.black, weight: FontWeight.w600);
        expect(style.fontWeight, FontWeight.w600);
      });
    });

    test('fontSize が設定される', () async {
      await _run(() async {
        final style = camillBodyStyle(13, Colors.grey);
        expect(style.fontSize, 13);
      });
    });
  });
}
