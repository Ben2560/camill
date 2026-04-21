import '../../../shared/models/wallet_model.dart';
import '../../../shared/services/api_service.dart';

class WalletService {
  final ApiService _api;
  WalletService({ApiService? api}) : _api = api ?? ApiService();

  Future<List<Wallet>> fetchWallets() async {
    final data = await _api.getAny('/wallets');
    final list = data as List? ?? [];
    return list.map((e) => Wallet.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Wallet> createWallet({
    required String name,
    String? ownerUid,
    String? guardianUid,
  }) async {
    final data = await _api.postAny(
      '/wallets',
      body: {
        'name': name,
        'owner_uid': ?ownerUid,
        'guardian_uid': ?guardianUid,
      },
    );
    return Wallet.fromJson(data as Map<String, dynamic>);
  }

  Future<void> transferWallet(String walletId) async {
    await _api.patch('/wallets/$walletId/transfer', body: {});
  }

  // ─── WalletRules ──────────────────────────────────────────────────────────

  Future<List<WalletRule>> fetchRules() async {
    final data = await _api.getAny('/wallet-rules');
    final list = data as List? ?? [];
    return list
        .map((e) => WalletRule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WalletRule> createRule({
    required String matchType,
    required String matchValue,
    required String walletId,
  }) async {
    final data = await _api.postAny(
      '/wallet-rules',
      body: {
        'match_type': matchType,
        'match_value': matchValue,
        'wallet_id': walletId,
      },
    );
    return WalletRule.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteRule(String ruleId) async {
    await _api.delete('/wallet-rules/$ruleId');
  }
}
