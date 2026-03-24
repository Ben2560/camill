enum CamillThemeMode {
  midnight,
  natural,
  classic;

  String get displayName {
    switch (this) {
      case CamillThemeMode.midnight:
        return 'Midnight';
      case CamillThemeMode.natural:
        return 'Natural Soft';
      case CamillThemeMode.classic:
        return 'Classic White';
    }
  }

  bool get isDark => this == CamillThemeMode.midnight;
}
