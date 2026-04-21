import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_model.freezed.dart';
part 'wallet_model.g.dart';

@freezed
sealed class Wallet with _$Wallet {
  const factory Wallet({
    required String walletId,
    required String ownerUid,
    String? guardianUid,
    required String walletType,
    required String name,
    required DateTime createdAt,
  }) = _Wallet;

  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);
}

@freezed
sealed class WalletRule with _$WalletRule {
  const factory WalletRule({
    required String ruleId,
    required String matchType,
    required String matchValue,
    required String walletId,
    required DateTime createdAt,
  }) = _WalletRule;

  factory WalletRule.fromJson(Map<String, dynamic> json) =>
      _$WalletRuleFromJson(json);
}
