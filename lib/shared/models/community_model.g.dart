// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CommunityStore _$CommunityStoreFromJson(Map<String, dynamic> json) =>
    _CommunityStore(
      storeId: json['store_id'] as String,
      storeName: json['store_name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      storeAddress: json['store_address'] as String?,
      storePhone: json['store_phone'] as String?,
      couponCount: (json['coupon_count'] as num?)?.toInt() ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      isLocked: json['is_locked'] as bool? ?? false,
      coupons:
          (json['coupons'] as List<dynamic>?)
              ?.map((e) => SharedCoupon.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CommunityStoreToJson(_CommunityStore instance) =>
    <String, dynamic>{
      'store_id': instance.storeId,
      'store_name': instance.storeName,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'store_address': instance.storeAddress,
      'store_phone': instance.storePhone,
      'coupon_count': instance.couponCount,
      'is_featured': instance.isFeatured,
      'is_locked': instance.isLocked,
      'coupons': instance.coupons.map((e) => e.toJson()).toList(),
    };

_SharedCoupon _$SharedCouponFromJson(Map<String, dynamic> json) =>
    _SharedCoupon(
      couponId: json['coupon_id'] as String,
      storeName: json['store_name'] as String,
      description: json['description'] as String,
      discountAmount: (json['discount_amount'] as num).toInt(),
      discountPercent: (json['discount_percent'] as num?)?.toInt(),
      validFrom: json['valid_from'] == null
          ? null
          : DateTime.parse(json['valid_from'] as String),
      validUntil: json['valid_until'] == null
          ? null
          : DateTime.parse(json['valid_until'] as String),
      sharedAt: json['shared_at'] == null
          ? null
          : DateTime.parse(json['shared_at'] as String),
      isExpired: json['is_expired'] as bool? ?? false,
    );

Map<String, dynamic> _$SharedCouponToJson(_SharedCoupon instance) =>
    <String, dynamic>{
      'coupon_id': instance.couponId,
      'store_name': instance.storeName,
      'description': instance.description,
      'discount_amount': instance.discountAmount,
      'discount_percent': instance.discountPercent,
      'valid_from': instance.validFrom?.toIso8601String(),
      'valid_until': instance.validUntil?.toIso8601String(),
      'shared_at': instance.sharedAt?.toIso8601String(),
      'is_expired': instance.isExpired,
    };

_CommunitySettings _$CommunitySettingsFromJson(Map<String, dynamic> json) =>
    _CommunitySettings(
      shareEnabled: json['share_enabled'] as bool? ?? true,
      notifyAll: json['notify_all'] as bool? ?? true,
      selectedStoreIds:
          (json['selected_store_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      notifiedStoreIds:
          (json['notified_store_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      remainingChanges: (json['remaining_changes'] as num?)?.toInt() ?? 3,
      nextResetDate: json['next_reset_date'] == null
          ? null
          : DateTime.parse(json['next_reset_date'] as String),
      isPremium: json['is_premium'] as bool? ?? false,
    );

Map<String, dynamic> _$CommunitySettingsToJson(_CommunitySettings instance) =>
    <String, dynamic>{
      'share_enabled': instance.shareEnabled,
      'notify_all': instance.notifyAll,
      'selected_store_ids': instance.selectedStoreIds,
      'notified_store_ids': instance.notifiedStoreIds,
    };
