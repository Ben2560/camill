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

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'display_name': displayName,
        'role': role,
        'joined_at': joinedAt.toIso8601String(),
      };

  FamilyMember copyWith({
    String? userId,
    String? displayName,
    String? role,
    DateTime? joinedAt,
  }) =>
      FamilyMember(
        userId: userId ?? this.userId,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        joinedAt: joinedAt ?? this.joinedAt,
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

  Map<String, dynamic> toJson() => {
        'family_id': familyId,
        'name': name,
        'owner_uid': ownerUid,
        'max_members': maxMembers,
        'members': members.map((m) => m.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
      };

  Family copyWith({
    String? familyId,
    String? name,
    String? ownerUid,
    int? maxMembers,
    List<FamilyMember>? members,
    DateTime? createdAt,
  }) =>
      Family(
        familyId: familyId ?? this.familyId,
        name: name ?? this.name,
        ownerUid: ownerUid ?? this.ownerUid,
        maxMembers: maxMembers ?? this.maxMembers,
        members: members ?? this.members,
        createdAt: createdAt ?? this.createdAt,
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

  Map<String, dynamic> toJson() => {
        'token': token,
        'expires_at': expiresAt.toIso8601String(),
        'role': role,
      };

  FamilyInvite copyWith({
    String? token,
    DateTime? expiresAt,
    String? role,
  }) =>
      FamilyInvite(
        token: token ?? this.token,
        expiresAt: expiresAt ?? this.expiresAt,
        role: role ?? this.role,
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

  Map<String, dynamic> toJson() => {
        'permission_id': permissionId,
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'view_level': viewLevel,
        'created_at': createdAt.toIso8601String(),
      };

  FamilyPermission copyWith({
    String? permissionId,
    String? fromUserId,
    String? toUserId,
    String? viewLevel,
    DateTime? createdAt,
  }) =>
      FamilyPermission(
        permissionId: permissionId ?? this.permissionId,
        fromUserId: fromUserId ?? this.fromUserId,
        toUserId: toUserId ?? this.toUserId,
        viewLevel: viewLevel ?? this.viewLevel,
        createdAt: createdAt ?? this.createdAt,
      );
}
