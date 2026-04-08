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

  Map<String, dynamic> toJson() => {
        'wallet_id': walletId,
        'owner_uid': ownerUid,
        if (guardianUid != null) 'guardian_uid': guardianUid,
        'wallet_type': walletType,
        'name': name,
        'created_at': createdAt.toIso8601String(),
      };

  Wallet copyWith({
    String? walletId,
    String? ownerUid,
    String? guardianUid,
    String? walletType,
    String? name,
    DateTime? createdAt,
  }) =>
      Wallet(
        walletId: walletId ?? this.walletId,
        ownerUid: ownerUid ?? this.ownerUid,
        guardianUid: guardianUid ?? this.guardianUid,
        walletType: walletType ?? this.walletType,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
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

  Map<String, dynamic> toJson() => {
        'rule_id': ruleId,
        'match_type': matchType,
        'match_value': matchValue,
        'wallet_id': walletId,
        'created_at': createdAt.toIso8601String(),
      };

  WalletRule copyWith({
    String? ruleId,
    String? matchType,
    String? matchValue,
    String? walletId,
    DateTime? createdAt,
  }) =>
      WalletRule(
        ruleId: ruleId ?? this.ruleId,
        matchType: matchType ?? this.matchType,
        matchValue: matchValue ?? this.matchValue,
        walletId: walletId ?? this.walletId,
        createdAt: createdAt ?? this.createdAt,
      );
}
