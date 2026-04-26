// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Coupon _$CouponFromJson(Map<String, dynamic> json) => _Coupon(
  couponId: json['coupon_id'] as String,
  storeName: json['store_name'] as String,
  description: json['description'] as String,
  discountAmount: (json['discount_amount'] as num).toInt(),
  validFrom: json['valid_from'] == null
      ? null
      : DateTime.parse(json['valid_from'] as String),
  validUntil: json['valid_until'] == null
      ? null
      : DateTime.parse(json['valid_until'] as String),
  isUsed: json['is_used'] as bool,
  isFromOcr: json['is_from_ocr'] as bool,
  isUncertain: json['is_uncertain'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String),
  availableDays: (json['available_days'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  requiresSurvey: json['requires_survey'] as bool? ?? false,
  surveyUrl: json['survey_url'] as String?,
  surveyAnswered: json['survey_answered'] as bool? ?? false,
  isCommunityShared: json['is_community_shared'] as bool? ?? false,
  communityStatus: json['community_status'] as String? ?? 'none',
  communityPublishAt: json['community_publish_at'] == null
      ? null
      : DateTime.parse(json['community_publish_at'] as String),
);

Map<String, dynamic> _$CouponToJson(_Coupon instance) => <String, dynamic>{
  'coupon_id': instance.couponId,
  'store_name': instance.storeName,
  'description': instance.description,
  'discount_amount': instance.discountAmount,
  'valid_from': instance.validFrom?.toIso8601String(),
  'valid_until': instance.validUntil?.toIso8601String(),
  'is_used': instance.isUsed,
  'is_from_ocr': instance.isFromOcr,
  'is_uncertain': instance.isUncertain,
  'created_at': instance.createdAt.toIso8601String(),
  'available_days': instance.availableDays,
  'requires_survey': instance.requiresSurvey,
  'survey_url': instance.surveyUrl,
  'survey_answered': instance.surveyAnswered,
  'is_community_shared': instance.isCommunityShared,
  'community_status': instance.communityStatus,
  'community_publish_at': instance.communityPublishAt?.toIso8601String(),
};
