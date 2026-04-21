import 'package:freezed_annotation/freezed_annotation.dart';

part 'community_model.freezed.dart';
part 'community_model.g.dart';

@freezed
sealed class CommunityStore with _$CommunityStore {
  const CommunityStore._();

  const factory CommunityStore({
    required String storeId,
    required String storeName,
    required double latitude,
    required double longitude,
    String? storeAddress,
    String? storePhone,
    @Default(0) int couponCount,
    @Default(false) bool isFeatured,
    @Default(false) bool isLocked,
    @Default([]) List<SharedCoupon> coupons,
  }) = _CommunityStore;

  factory CommunityStore.fromJson(Map<String, dynamic> json) =>
      _$CommunityStoreFromJson(json);
}

@freezed
sealed class SharedCoupon with _$SharedCoupon {
  const SharedCoupon._();

  const factory SharedCoupon({
    required String couponId,
    required String storeName,
    required String description,
    required int discountAmount,
    int? discountPercent,
    DateTime? validFrom,
    DateTime? validUntil,
    DateTime? sharedAt,
    @Default(false) bool isExpired,
  }) = _SharedCoupon;

  factory SharedCoupon.fromJson(Map<String, dynamic> json) =>
      _$SharedCouponFromJson(json);

  bool get isFree => discountAmount == 0;

  int? get daysUntilExpiry {
    if (validUntil == null) return null;
    return validUntil!.difference(DateTime.now()).inDays;
  }

  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days <= 3 && days >= 0;
  }
}

@freezed
sealed class CommunitySettings with _$CommunitySettings {
  const factory CommunitySettings({
    @Default(true) bool shareEnabled,
    @Default(true) bool notifyAll,
    @Default([]) List<String> selectedStoreIds,
    @Default([]) List<String> notifiedStoreIds,
    @JsonKey(includeToJson: false) @Default(3) int remainingChanges,
    @JsonKey(includeToJson: false) DateTime? nextResetDate,
    @JsonKey(includeToJson: false) @Default(false) bool isPremium,
  }) = _CommunitySettings;

  factory CommunitySettings.fromJson(Map<String, dynamic> json) =>
      _$CommunitySettingsFromJson(json);
}
