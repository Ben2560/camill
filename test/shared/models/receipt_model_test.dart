import 'package:flutter_test/flutter_test.dart';
import 'package:camill/shared/models/receipt_model.dart';

void main() {
  group('ReceiptItem.fromJson', () {
    test('必須フィールドをパースする', () {
      final item = ReceiptItem.fromJson({
        'item_name': 'コーヒー',
        'unit_price': 200,
        'quantity': 2,
        'amount': 400,
      });
      expect(item.itemName, 'コーヒー');
      expect(item.unitPrice, 200);
      expect(item.quantity, 2);
      expect(item.amount, 400);
    });

    test('デフォルト値が適用される', () {
      final item = ReceiptItem.fromJson({
        'item_name': 'x',
        'unit_price': 100,
        'quantity': 1,
        'amount': 100,
      });
      expect(item.itemNameRaw, '');
      expect(item.category, 'other');
      expect(item.points, 0);
    });

    test('item_name_raw が存在する場合はパースする', () {
      final item = ReceiptItem.fromJson({
        'item_name': '珈琲',
        'item_name_raw': 'Coffee',
        'category': 'food',
        'unit_price': 300,
        'quantity': 1,
        'amount': 300,
      });
      expect(item.itemNameRaw, 'Coffee');
      expect(item.category, 'food');
    });

    test('copyWith で itemName を変更できる', () {
      final item = ReceiptItem(
        itemName: 'A',
        unitPrice: 100,
        quantity: 1,
        amount: 100,
      );
      final updated = item.copyWith(itemName: 'B');
      expect(updated.itemName, 'B');
      expect(updated.unitPrice, 100);
    });
  });

  group('CouponDetected.fromJson', () {
    test('必須フィールドをパースする', () {
      final coupon = CouponDetected.fromJson({
        'description': '100円引き',
        'discount_amount': 100,
      });
      expect(coupon.description, '100円引き');
      expect(coupon.discountAmount, 100);
      expect(coupon.discountUnit, 'yen');
      expect(coupon.requiresSurvey, false);
    });

    test('全フィールドをパースする', () {
      final coupon = CouponDetected.fromJson({
        'description': '10%OFF',
        'discount_amount': 0,
        'discount_unit': 'percent',
        'valid_from': '2026-04-01',
        'valid_until': '2026-04-30',
        'requires_survey': true,
        'survey_url': 'https://example.com',
      });
      expect(coupon.discountUnit, 'percent');
      expect(coupon.requiresSurvey, true);
      expect(coupon.surveyUrl, 'https://example.com');
    });
  });

  group('LinePromotion.fromJson', () {
    test('description と lineUrl をパースする', () {
      final promo = LinePromotion.fromJson({
        'description': 'LINEクーポン',
        'line_url': 'https://line.me/xxx',
      });
      expect(promo.description, 'LINEクーポン');
      expect(promo.lineUrl, 'https://line.me/xxx');
    });

    test('lineUrl が null の場合', () {
      final promo = LinePromotion.fromJson({'description': 'd'});
      expect(promo.lineUrl, isNull);
    });
  });

  group('ReceiptAnalysis.fromJson', () {
    Map<String, dynamic> minimalAnalysis() => {
      'store_name': 'テスト店',
      'purchased_at': '2026-04-21T10:00:00',
      'total_amount': 1500,
      'items': [
        {'item_name': 'りんご', 'unit_price': 150, 'quantity': 2, 'amount': 300},
      ],
      'coupons_detected': [],
      'duplicate_check_hash': 'abc123',
    };

    test('必須フィールドをパースする', () {
      final analysis = ReceiptAnalysis.fromJson(minimalAnalysis());
      expect(analysis.storeName, 'テスト店');
      expect(analysis.totalAmount, 1500);
      expect(analysis.items.length, 1);
      expect(analysis.items.first.itemName, 'りんご');
    });

    test('デフォルト値が適用される', () {
      final analysis = ReceiptAnalysis.fromJson(minimalAnalysis());
      expect(analysis.paymentMethod, 'cash');
      expect(analysis.isMedical, false);
      expect(analysis.isBill, false);
      expect(analysis.billStatus, 'unpaid');
      expect(analysis.savingsAmount, 0);
      expect(analysis.linePromotions, isEmpty);
    });

    test('toJson で null フィールドを含まない', () {
      final analysis = ReceiptAnalysis.fromJson(minimalAnalysis());
      final json = analysis.toJson();
      expect(json.containsKey('tax_amount'), isFalse);
      expect(json.containsKey('category'), isFalse);
      expect(json.containsKey('total_points'), isFalse);
      expect(json.containsKey('memo'), isFalse);
      expect(json.containsKey('bill_due_date'), isFalse);
    });

    test('toJson で非 null フィールドを含む', () {
      final json = minimalAnalysis()..addAll({'tax_amount': 150, 'memo': 'メモ'});
      final analysis = ReceiptAnalysis.fromJson(json);
      final out = analysis.toJson();
      expect(out['tax_amount'], 150);
      expect(out['memo'], 'メモ');
    });
  });

  group('Receipt.fromJson', () {
    test('基本フィールドをパースする', () {
      final receipt = Receipt.fromJson({
        'receipt_id': 'r1',
        'store_name': 'スーパー',
        'total_amount': 3000,
        'purchased_at': '2026-04-21T10:00:00',
        'items': [],
      });
      expect(receipt.receiptId, 'r1');
      expect(receipt.storeName, 'スーパー');
      expect(receipt.paymentMethod, 'cash');
      expect(receipt.discounts, isEmpty);
      expect(receipt.savingsAmount, 0);
    });
  });

  group('Freezed equality', () {
    test('同一 ReceiptItem は等価', () {
      const a = ReceiptItem(
        itemName: 'x',
        unitPrice: 100,
        quantity: 1,
        amount: 100,
      );
      const b = ReceiptItem(
        itemName: 'x',
        unitPrice: 100,
        quantity: 1,
        amount: 100,
      );
      expect(a, equals(b));
    });
  });
}
