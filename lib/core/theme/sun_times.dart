import 'dart:math';

/// 緯度・経度・日付から日の出・日の入り時刻を計算するユーティリティ
/// NOAA Solar Calculator アルゴリズムを簡略化して実装
class SunTimes {
  /// [latitude]  緯度 (degrees)
  /// [longitude] 経度 (degrees)
  /// [date]      計算対象の日付 (local time)
  ///
  /// 返り値は local time の DateTime。
  /// 白夜・極夜など計算不能な場合は null。
  static ({DateTime? sunrise, DateTime? sunset}) calculate({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) {
    final jd = _julianDay(date);
    final sr = _calcTime(latitude, longitude, jd, sunrise: true);
    final ss = _calcTime(latitude, longitude, jd, sunrise: false);
    return (sunrise: sr, sunset: ss);
  }

  // ── 内部計算 ───────────────────────────────────────────────────────────────

  static double _toRad(double deg) => deg * pi / 180;
  static double _toDeg(double rad) => rad * 180 / pi;

  static double _julianDay(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day;
    final a = (14 - m) ~/ 12;
    final yr = y + 4800 - a;
    final mo = m + 12 * a - 3;
    return d +
        (153 * mo + 2) ~/ 5 +
        365 * yr +
        yr ~/ 4 -
        yr ~/ 100 +
        yr ~/ 400 -
        32045.0;
  }

  /// sunrise=true で日の出、false で日の入りの local DateTime を返す
  static DateTime? _calcTime(
    double lat,
    double lng,
    double jd, {
    required bool sunrise,
  }) {
    // ユリウス世紀
    final t = (jd - 2451545.0) / 36525.0;

    // 幾何平均黄経 (degrees)
    final l0 = (280.46646 + t * (36000.76983 + t * 0.0003032)) % 360;

    // 平均近点角 (degrees)
    final m = 357.52911 + t * (35999.05029 - 0.0001537 * t);

    // 黄道離心率
    final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);

    // 太陽の方程式
    final mRad = _toRad(m);
    final c = sin(mRad) * (1.9146 - t * (0.004817 + 0.000014 * t)) +
        sin(2 * mRad) * (0.019993 - 0.000101 * t) +
        sin(3 * mRad) * 0.00029;

    // 太陽の真黄経
    final sunLon = l0 + c;

    // 太陽の視黄経 (補正)
    final omega = 125.04 - 1934.136 * t;
    final lambda = sunLon - 0.00569 - 0.00478 * sin(_toRad(omega));

    // 黄道傾斜角
    final eps0 = 23.0 +
        (26.0 +
                (21.448 -
                        t * (46.8150 + t * (0.00059 - t * 0.001813))) /
                    60.0) /
            60.0;
    final eps = eps0 + 0.00256 * cos(_toRad(omega));

    // 太陽赤緯
    final decl = asin(sin(_toRad(eps)) * sin(_toRad(lambda)));

    // 均時差 (minutes)
    final y2 = pow(tan(_toRad(eps / 2)), 2).toDouble();
    final l0Rad = _toRad(l0);
    final eot = 4 *
        _toDeg(y2 * sin(2 * l0Rad) -
            2 * e * sin(mRad) +
            4 * e * y2 * sin(mRad) * cos(2 * l0Rad) -
            0.5 * y2 * y2 * sin(4 * l0Rad) -
            1.25 * e * e * sin(2 * mRad));

    // 太陽の時角 (degrees)
    const zenith = 90.833; // 大気屈折補正込みの地平線
    final cosHA = (cos(_toRad(zenith)) /
            (cos(_toRad(lat)) * cos(decl)) -
        tan(_toRad(lat)) * tan(decl));

    // 白夜 / 極夜 判定
    if (cosHA < -1 || cosHA > 1) return null;

    final ha = _toDeg(acos(cosHA));

    // 正午の真太陽時 → UTC (minutes)
    final solarNoonUtc = 720 - 4 * lng - eot;
    final eventUtcMin =
        sunrise ? solarNoonUtc - ha * 4 : solarNoonUtc + ha * 4;

    // UTC → local
    final base = DateTime.utc(
        _dateFromJd(jd).year, _dateFromJd(jd).month, _dateFromJd(jd).day);
    final utcEvent = base.add(Duration(seconds: (eventUtcMin * 60).round()));
    return utcEvent.toLocal();
  }

  static DateTime _dateFromJd(double jd) {
    final jdi = jd.floor() + 1;
    final a = jdi + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - 146097 * b ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - 1461 * d ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + m ~/ 10;
    return DateTime(year, month, day);
  }
}
