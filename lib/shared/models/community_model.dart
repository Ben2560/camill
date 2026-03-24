class CommunityStore {
  final String storeId;
  final String storeName;
  final double latitude;
  final double longitude;
  final String? storeAddress;
  final String? storePhone;
  final int couponCount;
  final bool isFeatured; // 注目ピン
  final bool isLocked; // 無料ユーザーの鍵アイコン
  final List<SharedCoupon> coupons;

  CommunityStore({
    required this.storeId,
    required this.storeName,
    required this.latitude,
    required this.longitude,
    this.storeAddress,
    this.storePhone,
    required this.couponCount,
    this.isFeatured = false,
    this.isLocked = false,
    this.coupons = const [],
  });

  factory CommunityStore.fromJson(Map<String, dynamic> json) => CommunityStore(
        storeId: json['store_id'] as String,
        storeName: json['store_name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        storeAddress: json['store_address'] as String?,
        storePhone: json['store_phone'] as String?,
        couponCount: (json['coupon_count'] as num?)?.toInt() ?? 0,
        isFeatured: json['is_featured'] as bool? ?? false,
        isLocked: json['is_locked'] as bool? ?? false,
        coupons: (json['coupons'] as List?)
                ?.map((e) => SharedCoupon.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class SharedCoupon {
  final String couponId;
  final String storeName;
  final String description;
  final int discountAmount;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? sharedAt;
  final bool isExpired;

  SharedCoupon({
    required this.couponId,
    required this.storeName,
    required this.description,
    required this.discountAmount,
    this.validFrom,
    this.validUntil,
    this.sharedAt,
    this.isExpired = false,
  });

  factory SharedCoupon.fromJson(Map<String, dynamic> json) => SharedCoupon(
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
        sharedAt: json['shared_at'] != null
            ? DateTime.parse(json['shared_at'] as String)
            : null,
        isExpired: json['is_expired'] as bool? ?? false,
      );

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

class CommunitySettings {
  final bool shareEnabled;
  final bool notifyAll;
  final List<String> selectedStoreIds; // 無料ユーザーの選択店舗（最大2）
  final int remainingChanges; // 残り変更回数
  final DateTime? nextResetDate; // 次のリセット日

  CommunitySettings({
    this.shareEnabled = true,
    this.notifyAll = true,
    this.selectedStoreIds = const [],
    this.remainingChanges = 3,
    this.nextResetDate,
  });

  factory CommunitySettings.fromJson(Map<String, dynamic> json) =>
      CommunitySettings(
        shareEnabled: json['share_enabled'] as bool? ?? true,
        notifyAll: json['notify_all'] as bool? ?? true,
        selectedStoreIds: (json['selected_store_ids'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        remainingChanges: (json['remaining_changes'] as num?)?.toInt() ?? 3,
        nextResetDate: json['next_reset_date'] != null
            ? DateTime.parse(json['next_reset_date'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'share_enabled': shareEnabled,
        'notify_all': notifyAll,
        'selected_store_ids': selectedStoreIds,
      };
}
