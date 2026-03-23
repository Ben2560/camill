import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'camill_theme_mode.dart';

final themeProvider =
    StateNotifierProvider<ThemeNotifier, CamillThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<CamillThemeMode> {
  ThemeNotifier() : super(CamillThemeMode.midnight) {
    _loadTheme();
  }

  ThemeNotifier.withInitial(super.initial);

  Future<void> setTheme(CamillThemeMode mode) async {
    if (mode.hasCat) return; // v2.0まで猫テーマは選択不可
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('camill_theme', mode.name);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('camill_theme');
    if (saved != null) {
      try {
        final mode = CamillThemeMode.values.byName(saved);
        if (!mode.hasCat) state = mode;
      } catch (_) {}
    }
  }
}
