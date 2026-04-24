import 'package:flutter_test/flutter_test.dart';
import 'package:camill/core/theme/sun_times.dart';

void main() {
  group('SunTimes.calculate', () {
    // 東京 (35.68°N, 139.69°E) — JST = UTC+9
    const tokyoLat = 35.6762;
    const tokyoLng = 139.6503;

    test('東京・4月15日: sunrise < sunset', () {
      final result = SunTimes.calculate(
        latitude: tokyoLat,
        longitude: tokyoLng,
        date: DateTime(2026, 4, 15),
      );
      expect(result.sunrise, isNotNull);
      expect(result.sunset, isNotNull);
      expect(result.sunrise!.isBefore(result.sunset!), isTrue);
    });

    test('東京・4月15日: 日の出は午前4〜7時', () {
      final result = SunTimes.calculate(
        latitude: tokyoLat,
        longitude: tokyoLng,
        date: DateTime(2026, 4, 15),
      );
      final sr = result.sunrise!.toLocal();
      expect(sr.hour >= 4 && sr.hour < 7, isTrue,
          reason: '日の出は ${sr.hour}:${sr.minute.toString().padLeft(2, '0')}');
    });

    test('東京・4月15日: 日の入りは午後17〜20時', () {
      final result = SunTimes.calculate(
        latitude: tokyoLat,
        longitude: tokyoLng,
        date: DateTime(2026, 4, 15),
      );
      final ss = result.sunset!.toLocal();
      expect(ss.hour >= 17 && ss.hour < 20, isTrue,
          reason: '日の入りは ${ss.hour}:${ss.minute.toString().padLeft(2, '0')}');
    });

    test('東京・夏至付近: 日の出が冬至付近より早い', () {
      final summer = SunTimes.calculate(
        latitude: tokyoLat,
        longitude: tokyoLng,
        date: DateTime(2026, 6, 21),
      );
      final winter = SunTimes.calculate(
        latitude: tokyoLat,
        longitude: tokyoLng,
        date: DateTime(2026, 12, 21),
      );
      final summerSrMin =
          summer.sunrise!.hour * 60 + summer.sunrise!.minute;
      final winterSrMin =
          winter.sunrise!.hour * 60 + winter.sunrise!.minute;
      expect(summerSrMin < winterSrMin, isTrue,
          reason: '夏至の日の出(${summerSrMin}min)が冬至(${winterSrMin}min)より早いはず');
    });

    test('東京・夏至付近: 日の入りが冬至付近より遅い', () {
      final summer = SunTimes.calculate(
        latitude: tokyoLat,
        longitude: tokyoLng,
        date: DateTime(2026, 6, 21),
      );
      final winter = SunTimes.calculate(
        latitude: tokyoLat,
        longitude: tokyoLng,
        date: DateTime(2026, 12, 21),
      );
      final summerSsMin =
          summer.sunset!.hour * 60 + summer.sunset!.minute;
      final winterSsMin =
          winter.sunset!.hour * 60 + winter.sunset!.minute;
      expect(summerSsMin > winterSsMin, isTrue,
          reason: '夏至の日の入り(${summerSsMin}min)が冬至(${winterSsMin}min)より遅いはず');
    });

    test('北極点・冬 (1月15日): 極夜で sunrise/sunset が null', () {
      final result = SunTimes.calculate(
        latitude: 89.9,
        longitude: 0.0,
        date: DateTime(2026, 1, 15),
      );
      expect(result.sunrise, isNull);
      expect(result.sunset, isNull);
    });

    test('北極点・夏 (7月15日): 白夜で sunrise/sunset が null', () {
      final result = SunTimes.calculate(
        latitude: 89.9,
        longitude: 0.0,
        date: DateTime(2026, 7, 15),
      );
      expect(result.sunrise, isNull);
      expect(result.sunset, isNull);
    });

    test('赤道 (0°, 0°): sunrise と sunset が返る', () {
      final result = SunTimes.calculate(
        latitude: 0.0,
        longitude: 0.0,
        date: DateTime(2026, 3, 21),
      );
      expect(result.sunrise, isNotNull);
      expect(result.sunset, isNotNull);
    });

    test('赤道: 春分付近は sunrise が約 6 時、sunset が約 18 時 (UTC)', () {
      final result = SunTimes.calculate(
        latitude: 0.0,
        longitude: 0.0,
        date: DateTime(2026, 3, 21),
      );
      final srUtc = result.sunrise!.toUtc();
      final ssUtc = result.sunset!.toUtc();
      expect(srUtc.hour >= 5 && srUtc.hour <= 7, isTrue);
      expect(ssUtc.hour >= 17 && ssUtc.hour <= 19, isTrue);
    });

    test('東京: 異なる年でも結果が返る（クラッシュしない）', () {
      for (final year in [2020, 2024, 2030]) {
        final result = SunTimes.calculate(
          latitude: tokyoLat,
          longitude: tokyoLng,
          date: DateTime(year, 6, 1),
        );
        expect(result.sunrise, isNotNull);
        expect(result.sunset, isNotNull);
      }
    });
  });
}
