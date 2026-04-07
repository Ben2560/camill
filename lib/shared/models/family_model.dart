class FamilyMember {
  final String userId;
  final String displayName;
  final String role; // owner | parent | child
  final DateTime joinedAt;

  FamilyMember({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        role: json['role'] as String,
        joinedAt: DateTime.parse(json['joined_at'] as String),
      );
}

class Family {
  final String familyId;
  final String name;
  final String ownerUid;
  final int maxMembers;
  final List<FamilyMember> members;
  final DateTime createdAt;

  Family({
    required this.familyId,
    required this.name,
    required this.ownerUid,
    required this.maxMembers,
    required this.members,
    required this.createdAt,
  });

  factory Family.fromJson(Map<String, dynamic> json) => Family(
        familyId: json['family_id'] as String,
        name: json['name'] as String,
        ownerUid: json['owner_uid'] as String,
        maxMembers: (json['max_members'] as num).toInt(),
        members: (json['members'] as List<dynamic>)
            .map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class FamilyInvite {
  final String token;
  final DateTime expiresAt;
  final String role;

  FamilyInvite({
    required this.token,
    required this.expiresAt,
    required this.role,
  });

  factory FamilyInvite.fromJson(Map<String, dynamic> json) => FamilyInvite(
        token: json['token'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        role: json['role'] as String,
      );
}

class FamilyPermission {
  final String permissionId;
  final String fromUserId;
  final String toUserId;
  final String viewLevel; // category_amount | none
  final DateTime createdAt;

  FamilyPermission({
    required this.permissionId,
    required this.fromUserId,
    required this.toUserId,
    required this.viewLevel,
    required this.createdAt,
  });

  factory FamilyPermission.fromJson(Map<String, dynamic> json) =>
      FamilyPermission(
        permissionId: json['permission_id'] as String,
        fromUserId: json['from_user_id'] as String,
        toUserId: json['to_user_id'] as String,
        viewLevel: json['view_level'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
