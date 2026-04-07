class Wallet {
  final String walletId;
  final String ownerUid;
  final String? guardianUid;
  final String walletType;
  final String name;
  final DateTime createdAt;

  Wallet({
    required this.walletId,
    required this.ownerUid,
    this.guardianUid,
    required this.walletType,
    required this.name,
    required this.createdAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        walletId: json['wallet_id'] as String,
        ownerUid: json['owner_uid'] as String,
        guardianUid: json['guardian_uid'] as String?,
        walletType: json['wallet_type'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class WalletRule {
  final String ruleId;
  final String matchType; // store | keyword | item
  final String matchValue;
  final String walletId;
  final DateTime createdAt;

  WalletRule({
    required this.ruleId,
    required this.matchType,
    required this.matchValue,
    required this.walletId,
    required this.createdAt,
  });

  factory WalletRule.fromJson(Map<String, dynamic> json) => WalletRule(
        ruleId: json['rule_id'] as String,
        matchType: json['match_type'] as String,
        matchValue: json['match_value'] as String,
        walletId: json['wallet_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
