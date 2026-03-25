import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'camill_colors.dart';
import 'camill_theme_mode.dart';

// ── 状態 ──────────────────────────────────────────────────────────────────────

class ThemeState {
  final CamillThemeMode selectedBase;
  final bool isDarkNow;
  final int nightStartHour;   // 夜間開始時刻 (default 22)
  final int morningStartHour; // 朝の開始時刻 (default 6)

  const ThemeState({
    required this.selectedBase,
    required this.isDarkNow,
    this.nightStartHour   = 22,
    this.morningStartHour = 6,
  });

  ThemeState copyWith({
    CamillThemeMode? selectedBase,
    bool? isDarkNow,
    int? nightStartHour,
    int? morningStartHour,
  }) =>
      ThemeState(
        selectedBase:    selectedBase    ?? this.selectedBase,
        isDarkNow:       isDarkNow       ?? this.isDarkNow,
        nightStartHour:  nightStartHour  ?? this.nightStartHour,
        morningStartHour: morningStartHour ?? this.morningStartHour,
      );

  /// 現在の状態から実効カラーセットを返す
  CamillColors get colors =>
      CamillColors.fromBase(selectedBase, isDark: isDarkNow);

  /// 時刻から夜間かどうかを計算する
  static bool computeIsDark(int nightStart, int morningStart) {
    final hour = DateTime.now().hour;
    return hour >= nightStart || hour < morningStart;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class ThemeNotifier extends StateNotifier<ThemeState> {
  Timer? _timer;

  ThemeNotifier()
      : super(ThemeState(
          selectedBase: CamillThemeMode.midnight,
          isDarkNow:    ThemeState.computeIsDark(22, 6),
        )) {
    _loadTheme();
  }

  ThemeNotifier.withInitial(super.initial) {
    _scheduleNextSwitch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── 公開メソッド ──────────────────────────────────────────────────────────

  Future<void> setBase(CamillThemeMode base) async {
    state = state.copyWith(selectedBase: base);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('camill_theme_base', base.name);
  }

  Future<void> setNightStartHour(int hour) async {
    final isDark = ThemeState.computeIsDark(hour, state.morningStartHour);
    state = state.copyWith(nightStartHour: hour, isDarkNow: isDark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('camill_night_start', hour);
    _scheduleNextSwitch();
  }

  Future<void> setMorningStartHour(int hour) async {
    final isDark = ThemeState.computeIsDark(state.nightStartHour, hour);
    state = state.copyWith(morningStartHour: hour, isDarkNow: isDark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('camill_morning_start', hour);
    _scheduleNextSwitch();
  }

  // ── 内部処理 ──────────────────────────────────────────────────────────────

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // 旧キー (camill_theme) との後方互換
    final baseName = prefs.getString('camill_theme_base')
        ?? prefs.getString('camill_theme');
    final nightStart   = prefs.getInt('camill_night_start')   ?? 22;
    final morningStart = prefs.getInt('camill_morning_start') ?? 6;

    CamillThemeMode base = CamillThemeMode.midnight;
    if (baseName != null) {
      try {
        base = CamillThemeMode.values.byName(baseName);
      } catch (_) {}
    }

    final isDark = ThemeState.computeIsDark(nightStart, morningStart);
    state = ThemeState(
      selectedBase:    base,
      isDarkNow:       isDark,
      nightStartHour:  nightStart,
      morningStartHour: morningStart,
    );
    _scheduleNextSwitch();
  }

  /// 次の日中/夜間切り替え時刻まで Timer をセット
  void _scheduleNextSwitch() {
    _timer?.cancel();
    final now         = DateTime.now();
    final hour        = now.hour;
    final nightStart  = state.nightStartHour;
    final mornStart   = state.morningStartHour;

    DateTime nextSwitch;
    if (hour >= nightStart || hour < mornStart) {
      // 現在: 夜間 → 次の切り替えは朝
      nextSwitch = DateTime(now.year, now.month, now.day, mornStart);
      if (!nextSwitch.isAfter(now)) {
        nextSwitch = nextSwitch.add(const Duration(days: 1));
      }
    } else {
      // 現在: 日中 → 次の切り替えは夜
      nextSwitch = DateTime(now.year, now.month, now.day, nightStart);
      if (!nextSwitch.isAfter(now)) {
        nextSwitch = nextSwitch.add(const Duration(days: 1));
      }
    }

    final delay = nextSwitch.difference(DateTime.now());
    _timer = Timer(delay, () {
      final isDark =
          ThemeState.computeIsDark(state.nightStartHour, state.morningStartHour);
      state = state.copyWith(isDarkNow: isDark);
      _scheduleNextSwitch();
    });
  }
}
