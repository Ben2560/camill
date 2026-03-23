enum CamillThemeMode {
  midnightCat, // v2.0実装予定（猫Riveアニメーション）
  midnight,
  naturalCat, // v2.0実装予定
  natural,
  classicCat, // v2.0実装予定
  classic;

  String get displayName {
    switch (this) {
      case CamillThemeMode.midnightCat:
        return 'Midnight + 白猫';
      case CamillThemeMode.midnight:
        return 'Midnight';
      case CamillThemeMode.naturalCat:
        return 'Natural + 茶トラ';
      case CamillThemeMode.natural:
        return 'Natural Soft';
      case CamillThemeMode.classicCat:
        return 'Classic + 黒猫';
      case CamillThemeMode.classic:
        return 'Classic White';
    }
  }

  bool get hasCat =>
      this == CamillThemeMode.midnightCat ||
      this == CamillThemeMode.naturalCat ||
      this == CamillThemeMode.classicCat;

  bool get isDark =>
      this == CamillThemeMode.midnight || this == CamillThemeMode.midnightCat;
}
