import 'package:flutter_test/flutter_test.dart';
import 'package:camill/shared/models/wallet_model.dart';

void main() {
  final now = DateTime.now();

  group('Wallet.fromJson', () {
    test('必須フィールドをパースする', () {
      final wallet = Wallet.fromJson({
        'wallet_id': 'w1',
        'owner_uid': 'u1',
        'wallet_type': 'personal',
        'name': '個人財布',
        'created_at': now.toIso8601String(),
      });
      expect(wallet.walletId, 'w1');
      expect(wallet.ownerUid, 'u1');
      expect(wallet.walletType, 'personal');
      expect(wallet.guardianUid, isNull);
    });

    test('guardianUid を含む場合', () {
      final wallet = Wallet.fromJson({
        'wallet_id': 'w2',
        'owner_uid': 'child1',
        'guardian_uid': 'parent1',
        'wallet_type': 'child',
        'name': '子供財布',
        'created_at': now.toIso8601String(),
      });
      expect(wallet.guardianUid, 'parent1');
    });

    test('copyWith で name を変更できる', () {
      final wallet = Wallet.fromJson({
        'wallet_id': 'w1',
        'owner_uid': 'u1',
        'wallet_type': 'personal',
        'name': '旧名前',
        'created_at': now.toIso8601String(),
      });
      final updated = wallet.copyWith(name: '新名前');
      expect(updated.name, '新名前');
      expect(updated.walletId, 'w1');
    });
  });

  group('WalletRule.fromJson', () {
    test('全フィールドをパースする', () {
      final rule = WalletRule.fromJson({
        'rule_id': 'r1',
        'match_type': 'store',
        'match_value': 'セブン',
        'wallet_id': 'w1',
        'created_at': now.toIso8601String(),
      });
      expect(rule.ruleId, 'r1');
      expect(rule.matchType, 'store');
      expect(rule.matchValue, 'セブン');
    });

    test('copyWith で matchValue を変更できる', () {
      final rule = WalletRule(
        ruleId: 'r1',
        matchType: 'keyword',
        matchValue: '古い値',
        walletId: 'w1',
        createdAt: now,
      );
      final updated = rule.copyWith(matchValue: '新しい値');
      expect(updated.matchValue, '新しい値');
      expect(updated.ruleId, 'r1');
    });
  });

  group('Freezed equality', () {
    test('同一 Wallet は等価', () {
      final a = Wallet(walletId: 'w1', ownerUid: 'u1', walletType: 't', name: 'n', createdAt: now);
      final b = Wallet(walletId: 'w1', ownerUid: 'u1', walletType: 't', name: 'n', createdAt: now);
      expect(a, equals(b));
    });
  });
}
