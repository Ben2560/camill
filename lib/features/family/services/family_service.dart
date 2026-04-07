import '../../../shared/models/family_model.dart';
import '../../../shared/services/api_service.dart';

class FamilyService {
  final ApiService _api;
  FamilyService({ApiService? api}) : _api = api ?? ApiService();

  Future<Family?> fetchMyFamily() async {
    final data = await _api.getAny('/families');
    if (data == null) return null;
    return Family.fromJson(data as Map<String, dynamic>);
  }

  Future<Family> createFamily(String name) async {
    final data = await _api.postAny('/families', body: {'name': name});
    return Family.fromJson(data as Map<String, dynamic>);
  }

  Future<Family> getFamily(String familyId) async {
    final data = await _api.getAny('/families/$familyId');
    return Family.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteFamily(String familyId) async {
    await _api.delete('/families/$familyId');
  }

  // ─── メンバー ──────────────────────────────────────────────────────────────

  Future<FamilyInvite> inviteMember(String familyId, String role) async {
    final data = await _api.postAny(
      '/families/$familyId/members/invite',
      body: {'role': role},
    );
    return FamilyInvite.fromJson(data as Map<String, dynamic>);
  }

  Future<Family> joinFamily(String familyId, String token) async {
    final data = await _api.postAny(
      '/families/$familyId/members/join',
      body: {'token': token},
    );
    return Family.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createChildAccount(
      String familyId, String displayName) async {
    final data = await _api.postAny(
      '/families/$familyId/members/create-child',
      body: {'display_name': displayName},
    );
    return data as Map<String, dynamic>;
  }

  Future<void> leaveFamilyMember(String familyId, String userId) async {
    await _api.delete('/families/$familyId/members/$userId');
  }

  // ─── 権限 ──────────────────────────────────────────────────────────────────

  Future<FamilyPermission> createPermission(
    String familyId,
    String toUserId,
    String viewLevel,
  ) async {
    final data = await _api.postAny(
      '/families/$familyId/permissions',
      body: {'to_user_id': toUserId, 'view_level': viewLevel},
    );
    return FamilyPermission.fromJson(data as Map<String, dynamic>);
  }

  Future<FamilyPermission> updatePermission(
    String familyId,
    String permissionId,
    String viewLevel,
  ) async {
    final data = await _api.patch(
      '/families/$familyId/permissions/$permissionId',
      body: {'view_level': viewLevel},
    );
    return FamilyPermission.fromJson(data);
  }

  Future<void> revokePermission(String familyId, String permissionId) async {
    await _api.delete('/families/$familyId/permissions/$permissionId');
  }
}
