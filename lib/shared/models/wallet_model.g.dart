// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Wallet _$WalletFromJson(Map<String, dynamic> json) => _Wallet(
  walletId: json['wallet_id'] as String,
  ownerUid: json['owner_uid'] as String,
  guardianUid: json['guardian_uid'] as String?,
  walletType: json['wallet_type'] as String,
  name: json['name'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$WalletToJson(_Wallet instance) => <String, dynamic>{
  'wallet_id': instance.walletId,
  'owner_uid': instance.ownerUid,
  'guardian_uid': instance.guardianUid,
  'wallet_type': instance.walletType,
  'name': instance.name,
  'created_at': instance.createdAt.toIso8601String(),
};

_WalletRule _$WalletRuleFromJson(Map<String, dynamic> json) => _WalletRule(
  ruleId: json['rule_id'] as String,
  matchType: json['match_type'] as String,
  matchValue: json['match_value'] as String,
  walletId: json['wallet_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$WalletRuleToJson(_WalletRule instance) =>
    <String, dynamic>{
      'rule_id': instance.ruleId,
      'match_type': instance.matchType,
      'match_value': instance.matchValue,
      'wallet_id': instance.walletId,
      'created_at': instance.createdAt.toIso8601String(),
    };
