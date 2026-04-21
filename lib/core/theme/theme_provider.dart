import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/services/user_prefs.dart';
import 'camill_colors.dart';
import 'camill_theme_mode.dart';
import 'sun_times.dart';

// ── フォールバック座標 (東京) ──────────────────────────────────────────────────
const _defaultLat = 35.6812;
const _defaultLng = 139.7671;

// ── 状態 ──────────────────────────────────────────────────────────────────────

class ThemeState {
  final CamillThemeMode selectedBase;
  final bool isDarkNow;
  final bool autoSwitch;

  const ThemeState({
    required this.selectedBase,
    required this.isDarkNow,
    this.autoSwitch = true,
  });

  ThemeState copyWith({
    CamillThemeMode? selectedBase,
    bool? isDarkNow,
    bool? autoSwitch,
  }) => ThemeState(
    selectedBase: selectedBase ?? this.selectedBase,
    isDarkNow: isDarkNow ?? this.isDarkNow,
    autoSwitch: autoSwitch ?? this.autoSwitch,
  );

  /// 現在の状態から実効カラーセットを返す
  CamillColors get colors =>
      CamillColors.fromBase(selectedBase, isDark: isDarkNow);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class ThemeNotifier extends StateNotifier<ThemeState>
    with WidgetsBindingObserver {
  Timer? _timer;

  ThemeNotifier()
    : super(
        ThemeState(
          selectedBase: CamillThemeMode.sakura,
          isDarkNow: _guessIsDarkByHour(),
        ),
      ) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  ThemeNotifier.withInitial(ThemeState initial) : super(initial) {
    WidgetsBinding.instance.addObserver(this);
    if (initial.autoSwitch) _scheduleFromSunTimes();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && this.state.autoSwitch) {
      _scheduleFromSunTimes();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  // ── 公開メソッド ──────────────────────────────────────────────────────────

  Future<void> setBase(CamillThemeMode base) async {
    state = state.copyWith(selectedBase: base);
    final prefs = await SharedPreferences.getInstance();
    await UserPrefs.setString(prefs, 'camill_theme_base', base.name);
  }

  Future<void> setAutoSwitch(bool value) async {
    state = state.copyWith(autoSwitch: value);
    final prefs = await SharedPreferences.getInstance();
    await UserPrefs.setBool(prefs, 'camill_auto_switch', value);
    if (value) {
      await _scheduleFromSunTimes();
    } else {
      _timer?.cancel();
    }
  }

  Future<void> setDarkNow(bool value) async {
    if (state.autoSwitch) return; // 自動モード中は手動変更不可
    state = state.copyWith(isDarkNow: value);
  }

  // ── 初期化 ────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    await _loadPrefs();
    if (state.autoSwitch) {
      await _scheduleFromSunTimes();
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // UID付きキーを優先し、なければ旧キー（後方互換）にフォールバック
    final name =
        await UserPrefs.getString(prefs, 'camill_theme_base') ??
        prefs.getString('camill_theme');
    final auto = await UserPrefs.getBool(prefs, 'camill_auto_switch') ?? true;
    CamillThemeMode? base;
    if (name != null) {
      try {
        base = CamillThemeMode.values.byName(name);
      } catch (_) {}
    }
    state = state.copyWith(selectedBase: base, autoSwitch: auto);
  }

  // ── 日の出・日の入りベースのスケジューリング ──────────────────────────────

  Future<void> _scheduleFromSunTimes() async {
    _timer?.cancel();

    final pos = await _getPosition();
    final lat = pos?.latitude ?? _defaultLat;
    final lng = pos?.longitude ?? _defaultLng;
    final now = DateTime.now();
    final times = SunTimes.calculate(latitude: lat, longitude: lng, date: now);

    final sunrise = times.sunrise;
    final sunset = times.sunset;

    // 日の出・日の入りが取れない場合は時刻ベースフォールバック
    if (sunrise == null || sunset == null) {
      _fallbackSchedule();
      return;
    }

    // 現在が日中か夜間かを判定
    final isDark = now.isBefore(sunrise) || now.isAfter(sunset);
    if (isDark != state.isDarkNow) {
      state = state.copyWith(isDarkNow: isDark);
    }

    // 次の切り替え時刻を計算
    DateTime nextSwitch;
    if (isDark) {
      // 夜間中 → 次は日の出
      nextSwitch = now.isBefore(sunrise)
          ? sunrise
          : SunTimes.calculate(
                  latitude: lat,
                  longitude: lng,
                  date: now.add(const Duration(days: 1)),
                ).sunrise ??
                now.add(const Duration(hours: 12));
    } else {
      // 日中 → 次は日の入り
      nextSwitch = sunset;
    }

    final delay = nextSwitch.difference(DateTime.now());
    _timer = Timer(delay.isNegative ? Duration.zero : delay, () {
      state = state.copyWith(isDarkNow: !state.isDarkNow);
      // 翌日の sun times で再スケジュール
      _scheduleFromSunTimes();
    });
  }

  // 位置情報が取れない時用: 6時/22時の固定フォールバック
  void _fallbackSchedule() {
    final isDark = _guessIsDarkByHour();
    if (isDark != state.isDarkNow) {
      state = state.copyWith(isDarkNow: isDark);
    }
    final now = DateTime.now();
    final hour = now.hour;
    DateTime next;
    if (hour >= 22 || hour < 6) {
      next = DateTime(now.year, now.month, now.day, 6);
      if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    } else {
      next = DateTime(now.year, now.month, now.day, 22);
    }
    _timer = Timer(next.difference(DateTime.now()), () {
      state = state.copyWith(isDarkNow: !state.isDarkNow);
      _fallbackSchedule();
    });
  }

  // ── 位置情報取得 ──────────────────────────────────────────────────────────

  static Future<Position?> _getPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      // まず最終既知位置を使う（高速）
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      // なければ現在地を取得
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// 起動直後の暫定判定 (sun times 取得前)
  static bool _guessIsDarkByHour() {
    final h = DateTime.now().hour;
    return h >= 22 || h < 6;
  }
}
