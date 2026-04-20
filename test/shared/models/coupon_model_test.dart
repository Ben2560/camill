import 'package:flutter_test/flutter_test.dart';
import 'package:camill/shared/models/coupon_model.dart';

void main() {
  final now = DateTime.now();

  Coupon makeCoupon({
    DateTime? validUntil,
    List<int>? availableDays,
    int discountAmount = 500,
  }) =>
      Coupon(
        couponId: 'c1',
        storeName: 'テスト店',
        description: '500円引き',
        discountAmount: discountAmount,
        isUsed: false,
        isFromOcr: true,
        createdAt: now,
        validUntil: validUntil,
        availableDays: availableDays,
      );

  group('Coupon.fromJson', () {
    test('必須フィールドを正しくパースする', () {
      final json = {
        'coupon_id': 'abc123',
        'store_name': 'スーパー',
        'description': '10%オフ',
        'discount_amount': 300,
        'is_used': false,
        'is_from_ocr': true,
        'created_at': now.toIso8601String(),
      };
      final coupon = Coupon.fromJson(json);
      expect(coupon.couponId, 'abc123');
      expect(coupon.storeName, 'スーパー');
      expect(coupon.discountAmount, 300);
      expect(coupon.requiresSurvey, false);
      expect(coupon.isCommunityShared, false);
    });

    test('available_days を正しくパースする', () {
      final json = {
        'coupon_id': 'x',
        'store_name': 's',
        'description': 'd',
        'discount_amount': 100,
        'is_used': false,
        'is_from_ocr': false,
        'created_at': now.toIso8601String(),
        'available_days': [0, 6],
      };
      final coupon = Coupon.fromJson(json);
      expect(coupon.availableDays, [0, 6]);
    });
  });

  group('isFree', () {
    test('discountAmount が 0 のとき true', () {
      expect(makeCoupon(discountAmount: 0).isFree, isTrue);
    });
    test('discountAmount が 0 より大きいとき false', () {
      expect(makeCoupon(discountAmount: 1).isFree, isFalse);
    });
  });

  group('isExpired / isExpiringSoon / daysUntilExpiry', () {
    test('validUntil が null のとき daysUntilExpiry は null', () {
      expect(makeCoupon().daysUntilExpiry, isNull);
    });

    test('昨日が期限のとき isExpired = true', () {
      final coupon = makeCoupon(validUntil: now.subtract(const Duration(days: 1)));
      expect(coupon.isExpired, isTrue);
      expect(coupon.isExpiringSoon, isFalse);
    });

    test('3日後が期限のとき isExpiringSoon = true', () {
      final coupon = makeCoupon(validUntil: now.add(const Duration(days: 3)));
      expect(coupon.isExpiringSoon, isTrue);
      expect(coupon.isExpired, isFalse);
    });

    test('10日後が期限のとき isExpiringSoon = false', () {
      final coupon = makeCoupon(validUntil: now.add(const Duration(days: 10)));
      expect(coupon.isExpiringSoon, isFalse);
    });
  });

  group('isUsableToday', () {
    test('availableDays が null のとき true（毎日使える）', () {
      expect(makeCoupon().isUsableToday, isTrue);
    });

    test('availableDays が空のとき true', () {
      expect(makeCoupon(availableDays: []).isUsableToday, isTrue);
    });

    test('今日の曜日インデックスが含まれるとき true', () {
      final todayIdx = now.weekday - 1; // 月=0 ... 日=6
      expect(makeCoupon(availableDays: [todayIdx]).isUsableToday, isTrue);
    });

    test('今日の曜日インデックスが含まれないとき false', () {
      final otherIdx = (now.weekday) % 7; // 今日以外の曜日
      expect(makeCoupon(availableDays: [otherIdx]).isUsableToday, isFalse);
    });
  });

  group('copyWith', () {
    test('指定フィールドだけ変更される', () {
      final original = makeCoupon();
      final updated = original.copyWith(storeName: '新しい店');
      expect(updated.storeName, '新しい店');
      expect(updated.couponId, original.couponId);
      expect(updated.discountAmount, original.discountAmount);
    });
  });
}
