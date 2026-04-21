import 'package:freezed_annotation/freezed_annotation.dart';

part 'family_model.freezed.dart';
part 'family_model.g.dart';

@freezed
sealed class FamilyMember with _$FamilyMember {
  const factory FamilyMember({
    required String userId,
    required String displayName,
    required String role,
    required DateTime joinedAt,
  }) = _FamilyMember;

  factory FamilyMember.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberFromJson(json);
}

@freezed
sealed class Family with _$Family {
  const factory Family({
    required String familyId,
    required String name,
    required String ownerUid,
    required int maxMembers,
    required List<FamilyMember> members,
    required DateTime createdAt,
  }) = _Family;

  factory Family.fromJson(Map<String, dynamic> json) => _$FamilyFromJson(json);
}

@freezed
sealed class FamilyInvite with _$FamilyInvite {
  const factory FamilyInvite({
    required String token,
    required DateTime expiresAt,
    required String role,
  }) = _FamilyInvite;

  factory FamilyInvite.fromJson(Map<String, dynamic> json) =>
      _$FamilyInviteFromJson(json);
}

@freezed
sealed class FamilyPermission with _$FamilyPermission {
  const factory FamilyPermission({
    required String permissionId,
    required String fromUserId,
    required String toUserId,
    required String viewLevel,
    required DateTime createdAt,
  }) = _FamilyPermission;

  factory FamilyPermission.fromJson(Map<String, dynamic> json) =>
      _$FamilyPermissionFromJson(json);
}
