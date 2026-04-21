import 'package:flutter_test/flutter_test.dart';
import 'package:camill/core/constants.dart';

void main() {
  group('AppConstants.categoryLabels', () {
    test('food → 食費', () {
      expect(AppConstants.categoryLabels['food'], '食費');
    });

    test('medical → 医療', () {
      expect(AppConstants.categoryLabels['medical'], '医療');
    });

    test('other → その他', () {
      expect(AppConstants.categoryLabels['other'], 'その他');
    });

    test('全カテゴリが13件ある', () {
      expect(AppConstants.categoryLabels.length, 13);
    });
  });

  group('AppConstants.categoryColors', () {
    test('全カテゴリに対応する色が存在する', () {
      for (final key in AppConstants.categoryLabels.keys) {
        expect(AppConstants.categoryColors.containsKey(key), isTrue,
            reason: 'missing color for $key');
      }
    });
  });

  group('AppConstants.paymentLabels', () {
    test('cash → 現金', () {
      expect(AppConstants.paymentLabels['cash'], '現金');
    });

    test('credit が存在する', () {
      expect(AppConstants.paymentLabels.containsKey('credit'), isTrue);
    });

    test('空でない', () {
      expect(AppConstants.paymentLabels.isNotEmpty, isTrue);
    });
  });

  group('AppConstants.fixedCategories', () {
    test('fixed カテゴリセットが空でない', () {
      expect(AppConstants.fixedCategories.isNotEmpty, isTrue);
    });

    test('utility が含まれる', () {
      expect(AppConstants.fixedCategories.contains('utility'), isTrue);
    });

    test('subscription が含まれる', () {
      expect(AppConstants.fixedCategories.contains('subscription'), isTrue);
    });
  });
}
