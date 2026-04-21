// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReceiptItem _$ReceiptItemFromJson(Map<String, dynamic> json) => _ReceiptItem(
  itemName: json['item_name'] as String,
  itemNameRaw: json['item_name_raw'] as String? ?? '',
  category: json['category'] as String? ?? 'other',
  unitPrice: (json['unit_price'] as num).toInt(),
  quantity: (json['quantity'] as num).toInt(),
  amount: (json['amount'] as num).toInt(),
  points: (json['points'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ReceiptItemToJson(_ReceiptItem instance) =>
    <String, dynamic>{
      'item_name': instance.itemName,
      'item_name_raw': instance.itemNameRaw,
      'category': instance.category,
      'unit_price': instance.unitPrice,
      'quantity': instance.quantity,
      'amount': instance.amount,
      'points': instance.points,
    };

_CouponDetected _$CouponDetectedFromJson(Map<String, dynamic> json) =>
    _CouponDetected(
      description: json['description'] as String,
      discountAmount: (json['discount_amount'] as num).toInt(),
      discountUnit: json['discount_unit'] as String? ?? 'yen',
      validFrom: json['valid_from'] as String?,
      validUntil: json['valid_until'] as String?,
      storageLocation: json['storage_location'] as String?,
      requiresSurvey: json['requires_survey'] as bool? ?? false,
      surveyUrl: json['survey_url'] as String?,
    );

Map<String, dynamic> _$CouponDetectedToJson(_CouponDetected instance) =>
    <String, dynamic>{
      'description': instance.description,
      'discount_amount': instance.discountAmount,
      'discount_unit': instance.discountUnit,
      'valid_from': instance.validFrom,
      'valid_until': instance.validUntil,
      'storage_location': instance.storageLocation,
      'requires_survey': instance.requiresSurvey,
      'survey_url': instance.surveyUrl,
    };

_LinePromotion _$LinePromotionFromJson(Map<String, dynamic> json) =>
    _LinePromotion(
      description: json['description'] as String,
      lineUrl: json['line_url'] as String?,
    );

Map<String, dynamic> _$LinePromotionToJson(_LinePromotion instance) =>
    <String, dynamic>{
      'description': instance.description,
      'line_url': instance.lineUrl,
    };

_ReceiptDiscount _$ReceiptDiscountFromJson(Map<String, dynamic> json) =>
    _ReceiptDiscount(
      description: json['description'] as String,
      discountAmount: (json['discount_amount'] as num).toInt(),
    );

Map<String, dynamic> _$ReceiptDiscountToJson(_ReceiptDiscount instance) =>
    <String, dynamic>{
      'description': instance.description,
      'discount_amount': instance.discountAmount,
    };

_ReceiptAnalysis _$ReceiptAnalysisFromJson(Map<String, dynamic> json) =>
    _ReceiptAnalysis(
      storeName: json['store_name'] as String,
      purchasedAt: json['purchased_at'] as String,
      totalAmount: (json['total_amount'] as num).toInt(),
      taxAmount: (json['tax_amount'] as num?)?.toInt(),
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      category: json['category'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      couponsDetected: (json['coupons_detected'] as List<dynamic>)
          .map((e) => CouponDetected.fromJson(e as Map<String, dynamic>))
          .toList(),
      linePromotions:
          (json['line_promotions'] as List<dynamic>?)
              ?.map((e) => LinePromotion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      duplicateCheckHash: json['duplicate_check_hash'] as String? ?? '',
      isMedical: json['is_medical'] as bool? ?? false,
      isUncovered: json['is_uncovered'] as bool? ?? false,
      totalPoints: (json['total_points'] as num?)?.toInt(),
      burdenRate: (json['burden_rate'] as num?)?.toDouble(),
      memo: json['memo'] as String?,
      isBill: json['is_bill'] as bool? ?? false,
      billDueDate: json['bill_due_date'] == null
          ? null
          : DateTime.parse(json['bill_due_date'] as String),
      billStatus: json['bill_status'] as String? ?? 'unpaid',
      billPaidDate: json['bill_paid_date'] == null
          ? null
          : DateTime.parse(json['bill_paid_date'] as String),
      billIsTaxExempt: json['bill_is_tax_exempt'] as bool? ?? false,
      savingsAmount: (json['savings_amount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ReceiptAnalysisToJson(
  _ReceiptAnalysis instance,
) => <String, dynamic>{
  'store_name': instance.storeName,
  'purchased_at': instance.purchasedAt,
  'total_amount': instance.totalAmount,
  'tax_amount': ?instance.taxAmount,
  'payment_method': instance.paymentMethod,
  'category': ?instance.category,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'coupons_detected': instance.couponsDetected.map((e) => e.toJson()).toList(),
  'line_promotions': instance.linePromotions.map((e) => e.toJson()).toList(),
  'duplicate_check_hash': instance.duplicateCheckHash,
  'is_medical': instance.isMedical,
  'is_uncovered': instance.isUncovered,
  'total_points': ?instance.totalPoints,
  'burden_rate': ?instance.burdenRate,
  'memo': ?instance.memo,
  'is_bill': instance.isBill,
  'bill_due_date': ?instance.billDueDate?.toIso8601String(),
  'bill_status': instance.billStatus,
  'bill_paid_date': ?instance.billPaidDate?.toIso8601String(),
  'bill_is_tax_exempt': instance.billIsTaxExempt,
  'savings_amount': instance.savingsAmount,
};

_Receipt _$ReceiptFromJson(Map<String, dynamic> json) => _Receipt(
  receiptId: json['receipt_id'] as String,
  storeName: json['store_name'] as String,
  totalAmount: (json['total_amount'] as num).toInt(),
  purchasedAt: json['purchased_at'] as String,
  paymentMethod: json['payment_method'] as String? ?? 'cash',
  items: (json['items'] as List<dynamic>)
      .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  discounts:
      (json['discounts'] as List<dynamic>?)
          ?.map((e) => ReceiptDiscount.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  memo: json['memo'] as String?,
  savingsAmount: (json['savings_amount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ReceiptToJson(_Receipt instance) => <String, dynamic>{
  'receipt_id': instance.receiptId,
  'store_name': instance.storeName,
  'total_amount': instance.totalAmount,
  'purchased_at': instance.purchasedAt,
  'payment_method': instance.paymentMethod,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'discounts': instance.discounts.map((e) => e.toJson()).toList(),
  'memo': instance.memo,
  'savings_amount': instance.savingsAmount,
};
