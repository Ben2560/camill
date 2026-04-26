import '../../../shared/models/community_model.dart';
import '../../../shared/services/api_service.dart';

class CommunityService {
  final ApiService _api;
  CommunityService({ApiService? api}) : _api = api ?? ApiService();

  /// 指定エリア内のクーポン付き店舗を取得
  Future<List<CommunityStore>> fetchStores({
    required double latitude,
    required double longitude,
    int radiusM = 1250,
  }) async {
    try {
      final data = await _api.getAny(
        '/community/stores',
        query: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'radius_m': radiusM.toString(),
        },
      );
      final list = data as List? ?? [];
      return list
          .map((e) => CommunityStore.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    }
  }

  /// コミュニティ設定を取得
  Future<CommunitySettings> fetchSettings() async {
    final data = await _api.get('/community/settings');
    return CommunitySettings.fromJson(data);
  }

  /// コミュニティ設定を更新
  Future<CommunitySettings> updateSettings({
    bool? shareEnabled,
    bool? notifyAll,
    List<String>? notifiedStoreIds,
  }) async {
    final body = <String, dynamic>{};
    if (shareEnabled != null) body['share_enabled'] = shareEnabled;
    if (notifyAll != null) body['notify_all'] = notifyAll;
    if (notifiedStoreIds != null) body['notified_store_ids'] = notifiedStoreIds;
    final data = await _api.patch('/community/settings', body: body);
    return CommunitySettings.fromJson(data);
  }

  /// 無料ユーザーの店舗選択を更新
  Future<CommunitySettings> selectStores(List<String> storeIds) async {
    final data = await _api.post(
      '/community/select-stores',
      body: {'store_ids': storeIds},
    );
    return CommunitySettings.fromJson(data);
  }

  /// コミュニティクーポンを通報
  Future<void> reportCoupon(String couponId) async {
    await _api.post('/coupons/$couponId/report', body: {});
  }
}
