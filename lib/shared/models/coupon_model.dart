class Coupon {
  final String couponId;
  final String storeName;
  final String description;
  final int discountAmount;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool isUsed;
  final bool isFromOcr;
  final DateTime createdAt;
  // 0=月, 1=火, 2=水, 3=木, 4=金, 5=土, 6=日 (null = 毎日)
  final List<int>? availableDays;
  final bool requiresSurvey;
  final String? surveyUrl;
  final bool surveyAnswered;
  final bool isCommunityShared;

  Coupon({
    required this.couponId,
    required this.storeName,
    required this.description,
    required this.discountAmount,
    this.validFrom,
    this.validUntil,
    required this.isUsed,
    required this.isFromOcr,
    required this.createdAt,
    this.availableDays,
    this.requiresSurvey = false,
    this.surveyUrl,
    this.surveyAnswered = false,
    this.isCommunityShared = false,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
        couponId: json['coupon_id'] as String,
        storeName: json['store_name'] as String,
        description: json['description'] as String,
        discountAmount: (json['discount_amount'] as num).toInt(),
        validFrom: json['valid_from'] != null
            ? DateTime.parse(json['valid_from'] as String)
            : null,
        validUntil: json['valid_until'] != null
            ? DateTime.parse(json['valid_until'] as String)
            : null,
        isUsed: json['is_used'] as bool? ?? false,
        isFromOcr: json['is_from_ocr'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        availableDays: (json['available_days'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList(),
        requiresSurvey: json['requires_survey'] as bool? ?? false,
        surveyUrl: json['survey_url'] as String?,
        surveyAnswered: json['survey_answered'] as bool? ?? false,
        isCommunityShared: json['is_community_shared'] as bool? ?? false,
      );

  bool get isFree => discountAmount == 0;

  // DateTime.weekday: 月=1, 火=2, ..., 土=6, 日=7 → index: 月=0 ... 日=6
  bool get isUsableToday {
    if (availableDays == null || availableDays!.isEmpty) return true;
    final dayIdx = DateTime.now().weekday - 1; // 月=0 ... 日=6
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
