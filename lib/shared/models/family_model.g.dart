// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FamilyMember _$FamilyMemberFromJson(Map<String, dynamic> json) =>
    _FamilyMember(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );

Map<String, dynamic> _$FamilyMemberToJson(_FamilyMember instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'display_name': instance.displayName,
      'role': instance.role,
      'joined_at': instance.joinedAt.toIso8601String(),
    };

_Family _$FamilyFromJson(Map<String, dynamic> json) => _Family(
  familyId: json['family_id'] as String,
  name: json['name'] as String,
  ownerUid: json['owner_uid'] as String,
  maxMembers: (json['max_members'] as num).toInt(),
  members: (json['members'] as List<dynamic>)
      .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$FamilyToJson(_Family instance) => <String, dynamic>{
  'family_id': instance.familyId,
  'name': instance.name,
  'owner_uid': instance.ownerUid,
  'max_members': instance.maxMembers,
  'members': instance.members.map((e) => e.toJson()).toList(),
  'created_at': instance.createdAt.toIso8601String(),
};

_FamilyInvite _$FamilyInviteFromJson(Map<String, dynamic> json) =>
    _FamilyInvite(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      role: json['role'] as String,
    );

Map<String, dynamic> _$FamilyInviteToJson(_FamilyInvite instance) =>
    <String, dynamic>{
      'token': instance.token,
      'expires_at': instance.expiresAt.toIso8601String(),
      'role': instance.role,
    };

_FamilyPermission _$FamilyPermissionFromJson(Map<String, dynamic> json) =>
    _FamilyPermission(
      permissionId: json['permission_id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      viewLevel: json['view_level'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$FamilyPermissionToJson(_FamilyPermission instance) =>
    <String, dynamic>{
      'permission_id': instance.permissionId,
      'from_user_id': instance.fromUserId,
      'to_user_id': instance.toUserId,
      'view_level': instance.viewLevel,
      'created_at': instance.createdAt.toIso8601String(),
    };
