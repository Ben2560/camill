enum CamillThemeMode {
  // ── フラットテーマ ──────────────────────────────────────────
  midnight,     // Midnight (既存ダーク)
  natural,      // Natural Soft (既存ライト)
  classic,      // Classic White (既存ライト)
  deepOcean,    // Deep Ocean
  warmSand,     // Warm Sand
  nordicSlate,  // Nordic Slate
  // ── グラデーションヘッダーテーマ ────────────────────────────
  aurora,       // Aurora (紫→青)
  sunset,       // Sunset (珊瑚→琥珀)
  oceanWave,    // Ocean Wave (青→シアン)
  cherry,       // Cherry (ピンク→白, Apple Health風)
  twilight,     // Twilight (ラベンダー→紫)
  emerald;      // Emerald (緑→ティール)

  String get displayName {
    switch (this) {
      case CamillThemeMode.midnight:   return 'Midnight';
      case CamillThemeMode.natural:    return 'Natural Soft';
      case CamillThemeMode.classic:    return 'Classic White';
      case CamillThemeMode.deepOcean:  return 'Deep Ocean';
      case CamillThemeMode.warmSand:   return 'Warm Sand';
      case CamillThemeMode.nordicSlate: return 'Nordic Slate';
      case CamillThemeMode.aurora:     return 'Aurora';
      case CamillThemeMode.sunset:     return 'Sunset';
      case CamillThemeMode.oceanWave:  return 'Ocean Wave';
      case CamillThemeMode.cherry:     return 'Cherry';
      case CamillThemeMode.twilight:   return 'Twilight';
      case CamillThemeMode.emerald:    return 'Emerald';
    }
  }

  bool get hasGradient {
    switch (this) {
      case CamillThemeMode.aurora:
      case CamillThemeMode.sunset:
      case CamillThemeMode.oceanWave:
      case CamillThemeMode.cherry:
      case CamillThemeMode.twilight:
      case CamillThemeMode.emerald:
        return true;
      default:
        return false;
    }
  }
}
