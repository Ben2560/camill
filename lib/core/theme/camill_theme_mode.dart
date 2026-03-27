enum CamillThemeMode {
  // ── カラーホイール順 (暖色 → 緑 → 寒色) ──────────────────
  cherry,       // Cherry    (ピンク,      H≈330°)
  sakura,       // Sakura    (桜→春空,     H≈342°)
  sunset,       // Sunset    (珊瑚→琥珀,   H≈15°)
  warmSand,     // WarmSand  (琥珀→砂,     H≈30°)
  natural,      // Natural   (緑,          H≈120°)
  emerald,      // Emerald   (深緑→ティール, H≈125°)
  oceanWave,    // OceanWave (ティール→オレンジ, H≈180°)
  classic,      // Classic   (青,          H≈210°)
  deepOcean,    // DeepOcean (深青,        H≈215°)
  nordicSlate,  // Nordic    (藍,          H≈230°)
  aurora,       // Aurora    (紫→シアン,   H≈265°)
  twilight;     // Twilight  (紫→オレンジ, H≈290°)

  String get displayName {
    switch (this) {
      case CamillThemeMode.cherry:      return 'Cherry';
      case CamillThemeMode.sakura:      return 'Sakura';
      case CamillThemeMode.sunset:      return 'Sunset';
      case CamillThemeMode.warmSand:    return 'Warm Sand';
      case CamillThemeMode.natural:     return 'Natural Soft';
      case CamillThemeMode.emerald:     return 'Emerald';
      case CamillThemeMode.oceanWave:   return 'Ocean Wave';
      case CamillThemeMode.classic:     return 'Classic White';
      case CamillThemeMode.deepOcean:   return 'Deep Ocean';
      case CamillThemeMode.nordicSlate: return 'Nordic Slate';
      case CamillThemeMode.aurora:      return 'Aurora';
      case CamillThemeMode.twilight:    return 'Twilight';
    }
  }

  bool get hasGradient {
    switch (this) {
      case CamillThemeMode.sakura:
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
