import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camill/core/theme/camill_theme_mode.dart';
import 'package:camill/core/theme/camill_colors.dart';

void main() {

  // ─────────────────────────────────────────
  // CamillThemeMode.hasGradient
  // ─────────────────────────────────────────
  group('CamillThemeMode.hasGradient', () {
    const gradientThemes = {
      CamillThemeMode.sakura,
      CamillThemeMode.aurora,
      CamillThemeMode.sunset,
      CamillThemeMode.oceanWave,
      CamillThemeMode.cherry,
      CamillThemeMode.twilight,
      CamillThemeMode.emerald,
    };

    for (final mode in CamillThemeMode.values) {
      test('${mode.name}: hasGradient == ${gradientThemes.contains(mode)}', () {
        expect(mode.hasGradient, gradientThemes.contains(mode));
      });
    }
  });

  // ─────────────────────────────────────────
  // CamillThemeMode.displayName
  // ─────────────────────────────────────────
  group('CamillThemeMode.displayName', () {
    test('全テーマで displayName が空でない', () {
      for (final mode in CamillThemeMode.values) {
        expect(mode.displayName, isNotEmpty,
            reason: '${mode.name}.displayName が空');
      }
    });

    test('displayName に重複がない', () {
      final names = CamillThemeMode.values.map((m) => m.displayName).toList();
      expect(names.toSet().length, names.length);
    });
  });

  // ─────────────────────────────────────────
  // CamillColors.fromBase
  // ─────────────────────────────────────────
  group('CamillColors.fromBase', () {
    test('全テーマ×Light/Dark で非 null を返す', () {
      for (final mode in CamillThemeMode.values) {
        expect(
          () => CamillColors.fromBase(mode, isDark: false),
          returnsNormally,
          reason: '${mode.name} light',
        );
        expect(
          () => CamillColors.fromBase(mode, isDark: true),
          returnsNormally,
          reason: '${mode.name} dark',
        );
      }
    });

    test('isDark フラグが返り値に反映される', () {
      for (final mode in CamillThemeMode.values) {
        expect(CamillColors.fromBase(mode, isDark: false).isDark, isFalse,
            reason: '${mode.name} light');
        expect(CamillColors.fromBase(mode, isDark: true).isDark, isTrue,
            reason: '${mode.name} dark');
      }
    });

    test('Light と Dark で primary が異なる', () {
      for (final mode in CamillThemeMode.values) {
        final light = CamillColors.fromBase(mode, isDark: false);
        final dark = CamillColors.fromBase(mode, isDark: true);
        expect(light.primary, isNot(equals(dark.primary)),
            reason: '${mode.name}: light/dark の primary が同じ');
      }
    });
  });

  // ─────────────────────────────────────────
  // CamillColors.naturalLight
  // ─────────────────────────────────────────
  group('CamillColors.naturalLight', () {
    test('isDark が false', () {
      expect(CamillColors.naturalLight.isDark, isFalse);
    });

    test('fromBase(natural, isDark: false) と同一インスタンス', () {
      expect(
        CamillColors.naturalLight,
        same(CamillColors.fromBase(CamillThemeMode.natural, isDark: false)),
      );
    });
  });

  // ─────────────────────────────────────────
  // CamillColors.copyWith
  // ─────────────────────────────────────────
  group('CamillColors.copyWith', () {
    late CamillColors base;

    setUp(() {
      base = CamillColors.fromBase(CamillThemeMode.sakura, isDark: false);
    });

    test('引数なしで呼ぶと全フィールドが元と同じ', () {
      final copy = base.copyWith();
      expect(copy.background, base.background);
      expect(copy.primary, base.primary);
      expect(copy.isDark, base.isDark);
    });

    test('primary だけ上書きできる', () {
      const newColor = Color(0xFF123456);
      final copy = base.copyWith(primary: newColor);
      expect(copy.primary, newColor);
      expect(copy.background, base.background);
      expect(copy.isDark, base.isDark);
    });

    test('isDark を反転できる', () {
      final copy = base.copyWith(isDark: true);
      expect(copy.isDark, isTrue);
      expect(copy.primary, base.primary);
    });

    test('複数フィールドを同時に上書きできる', () {
      const bg = Color(0xFF000001);
      const fg = Color(0xFF000002);
      final copy = base.copyWith(background: bg, textPrimary: fg);
      expect(copy.background, bg);
      expect(copy.textPrimary, fg);
      expect(copy.surface, base.surface);
    });
  });

  // ─────────────────────────────────────────
  // CamillColors.lerp
  // ─────────────────────────────────────────
  group('CamillColors.lerp', () {
    late CamillColors light;
    late CamillColors dark;

    setUp(() {
      light = CamillColors.fromBase(CamillThemeMode.classic, isDark: false);
      dark = CamillColors.fromBase(CamillThemeMode.classic, isDark: true);
    });

    test('t=0 で自分自身の primary を返す', () {
      final result = light.lerp(dark, 0.0);
      expect(result.primary, light.primary);
    });

    test('t=1 で other の primary を返す', () {
      final result = light.lerp(dark, 1.0);
      expect(result.primary, dark.primary);
    });

    test('other が null の場合 this を返す', () {
      final result = light.lerp(null, 0.5);
      expect(result.primary, light.primary);
      expect(result.isDark, light.isDark);
    });

    test('isDark は t<0.5 で this、t>=0.5 で other', () {
      expect(light.lerp(dark, 0.4).isDark, light.isDark);
      expect(light.lerp(dark, 0.5).isDark, dark.isDark);
      expect(light.lerp(dark, 0.9).isDark, dark.isDark);
    });

    test('t=0.5 で背景色が中間値になる', () {
      final result = light.lerp(dark, 0.5);
      final expected = Color.lerp(light.background, dark.background, 0.5)!;
      expect(result.background, expected);
    });
  });

}
