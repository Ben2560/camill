import 'package:flutter_test/flutter_test.dart';
import 'package:camill/shared/models/family_model.dart';

void main() {
  final now = DateTime.now();

  Map<String, dynamic> memberJson({String role = 'parent'}) => {
        'user_id': 'u1',
        'display_name': '渡邉',
        'role': role,
        'joined_at': now.toIso8601String(),
      };

  group('FamilyMember.fromJson', () {
    test('全フィールドをパースする', () {
      final m = FamilyMember.fromJson(memberJson());
      expect(m.userId, 'u1');
      expect(m.displayName, '渡邉');
      expect(m.role, 'parent');
    });

    test('copyWith で displayName を変更できる', () {
      final m = FamilyMember.fromJson(memberJson());
      final updated = m.copyWith(displayName: '新名前');
      expect(updated.displayName, '新名前');
      expect(updated.userId, m.userId);
    });
  });

  group('Family.fromJson', () {
    test('members リストをパースする', () {
      final json = {
        'family_id': 'f1',
        'name': '渡邉家',
        'owner_uid': 'u1',
        'max_members': 4,
        'members': [memberJson(), memberJson(role: 'child')],
        'created_at': now.toIso8601String(),
      };
      final family = Family.fromJson(json);
      expect(family.familyId, 'f1');
      expect(family.members.length, 2);
      expect(family.members.first.role, 'parent');
      expect(family.members.last.role, 'child');
    });

    test('copyWith で members を更新できる', () {
      final family = Family(
        familyId: 'f1',
        name: 'テスト家',
        ownerUid: 'u1',
        maxMembers: 2,
        members: const [],
        createdAt: DateTime.now(),
      );
      final member = FamilyMember.fromJson(memberJson());
      final updated = family.copyWith(members: [member]);
      expect(updated.members.length, 1);
    });
  });

  group('FamilyInvite.fromJson', () {
    test('トークンと期限をパースする', () {
      final invite = FamilyInvite.fromJson({
        'token': 'tok-abc',
        'expires_at': now.add(const Duration(hours: 24)).toIso8601String(),
        'role': 'child',
      });
      expect(invite.token, 'tok-abc');
      expect(invite.role, 'child');
    });
  });

  group('FamilyPermission.fromJson', () {
    test('全フィールドをパースする', () {
      final perm = FamilyPermission.fromJson({
        'permission_id': 'p1',
        'from_user_id': 'u1',
        'to_user_id': 'u2',
        'view_level': 'category_amount',
        'created_at': now.toIso8601String(),
      });
      expect(perm.permissionId, 'p1');
      expect(perm.viewLevel, 'category_amount');
    });
  });

  group('Freezed equality', () {
    test('同じ FamilyMember は等価', () {
      final a = FamilyMember.fromJson(memberJson());
      final b = FamilyMember.fromJson(memberJson());
      expect(a, equals(b));
    });
  });
}
