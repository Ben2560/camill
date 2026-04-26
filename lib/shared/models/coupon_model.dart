import 'package:freezed_annotation/freezed_annotation.dart';

part 'coupon_model.freezed.dart';
part 'coupon_model.g.dart';

@freezed
sealed class Coupon with _$Coupon {
  const Coupon._();

  const factory Coupon({
    required String couponId,
    required String storeName,
    required String description,
    required int discountAmount,
    DateTime? validFrom,
    DateTime? validUntil,
    required bool isUsed,
    required bool isFromOcr,
    @Default(false) bool isUncertain,
    required DateTime createdAt,
    // 0=月, 1=火, 2=水, 3=木, 4=金, 5=土, 6=日 (null = 毎日)
    List<int>? availableDays,
    @Default(false) bool requiresSurvey,
    String? surveyUrl,
    @Default(false) bool surveyAnswered,
    @Default(false) bool isCommunityShared,
    @Default('none')
    String communityStatus, // none / pending / published / rejected
    DateTime? communityPublishAt,
  }) = _Coupon;

  factory Coupon.fromJson(Map<String, dynamic> json) => _$CouponFromJson(json);

  bool get isFree => discountAmount == 0;

  // DateTime.weekday: 月=1, 火=2, ..., 土=6, 日=7 → index: 月=0 ... 日=6
  bool get isUsableToday {
    if (availableDays == null || availableDays!.isEmpty) return true;
    final dayIdx = DateTime.now().weekday - 1;
    return availableDays!.contains(dayIdx);
  }

  int? get daysUntilExpiry {
    if (validUntil == null) return null;
    return validUntil!.difference(DateTime.now()).inDays;
  }

  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days <= 3 && days >= 0;
  }

  bool get isExpired {
    final days = daysUntilExpiry;
    return days != null && days < 0;
  }
}
