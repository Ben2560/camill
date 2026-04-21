import 'package:flutter_test/flutter_test.dart';
import 'package:camill/shared/models/community_model.dart';

void main() {
  final now = DateTime.now();

  group('SharedCoupon.fromJson', () {
    test('必須フィールドをパースする', () {
      final c = SharedCoupon.fromJson({
        'coupon_id': 'sc1',
        'store_name': 'スーパー',
        'description': '100円引き',
        'discount_amount': 100,
      });
      expect(c.couponId, 'sc1');
      expect(c.discountAmount, 100);
      expect(c.isExpired, false);
    });

    test('isFree: discountAmount が 0 のとき true', () {
      final c = SharedCoupon(
        couponId: 'x',
        storeName: 's',
        description: 'd',
        discountAmount: 0,
      );
      expect(c.isFree, isTrue);
    });

    test('daysUntilExpiry: validUntil が null のとき null', () {
      final c = SharedCoupon(
        couponId: 'x',
        storeName: 's',
        description: 'd',
        discountAmount: 100,
      );
      expect(c.daysUntilExpiry, isNull);
    });

    test('isExpiringSoon: 3日以内は true', () {
      final c = SharedCoupon(
        couponId: 'x',
        storeName: 's',
        description: 'd',
        discountAmount: 100,
        validUntil: now.add(const Duration(days: 2)),
      );
      expect(c.isExpiringSoon, isTrue);
    });

    test('isExpiringSoon: 10日後は false', () {
      final c = SharedCoupon(
        couponId: 'x',
        storeName: 's',
        description: 'd',
        discountAmount: 100,
        validUntil: now.add(const Duration(days: 10)),
      );
      expect(c.isExpiringSoon, isFalse);
    });
  });

  group('CommunityStore.fromJson', () {
    test('coupons リストをパースする', () {
      final store = CommunityStore.fromJson({
        'store_id': 's1',
        'store_name': 'マルエツ',
        'latitude': 35.6,
        'longitude': 139.7,
        'coupon_count': 2,
        'coupons': [
          {
            'coupon_id': 'c1',
            'store_name': 'マルエツ',
            'description': '割引',
            'discount_amount': 50,
          },
        ],
      });
      expect(store.storeName, 'マルエツ');
      expect(store.coupons.length, 1);
      expect(store.isFeatured, false);
      expect(store.isLocked, false);
    });

    test('coupons が省略されるとき空リスト', () {
      final store = CommunityStore.fromJson({
        'store_id': 's1',
        'store_name': 's',
        'latitude': 0.0,
        'longitude': 0.0,
        'coupon_count': 0,
      });
      expect(store.coupons, isEmpty);
    });
  });

  group('CommunitySettings', () {
    test('fromJson でデフォルト値を適用する', () {
      final settings = CommunitySettings.fromJson({});
      expect(settings.shareEnabled, true);
      expect(settings.notifyAll, true);
      expect(settings.selectedStoreIds, isEmpty);
      expect(settings.remainingChanges, 3);
    });

    test('fromJson でサーバー値を反映する', () {
      final settings = CommunitySettings.fromJson({
        'share_enabled': false,
        'notify_all': false,
        'selected_store_ids': ['s1', 's2'],
        'remaining_changes': 1,
        'is_premium': true,
      });
      expect(settings.shareEnabled, false);
      expect(settings.selectedStoreIds, ['s1', 's2']);
      expect(settings.remainingChanges, 1);
      expect(settings.isPremium, true);
    });

    test('toJson に remainingChanges/nextResetDate/isPremium を含まない', () {
      final settings = CommunitySettings(
        shareEnabled: true,
        notifyAll: false,
        remainingChanges: 2,
        isPremium: true,
      );
      final json = settings.toJson();
      expect(json.containsKey('remaining_changes'), isFalse);
      expect(json.containsKey('next_reset_date'), isFalse);
      expect(json.containsKey('is_premium'), isFalse);
      expect(json['share_enabled'], true);
      expect(json['notify_all'], false);
    });
  });
}
