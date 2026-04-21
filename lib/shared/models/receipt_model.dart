import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_model.freezed.dart';
part 'receipt_model.g.dart';

@freezed
sealed class ReceiptItem with _$ReceiptItem {
  const factory ReceiptItem({
    required String itemName,
    @Default('') String itemNameRaw,
    @Default('other') String category,
    required int unitPrice,
    required int quantity,
    required int amount,
    @Default(0) int points,
  }) = _ReceiptItem;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) =>
      _$ReceiptItemFromJson(json);
}

@freezed
sealed class CouponDetected with _$CouponDetected {
  const factory CouponDetected({
    required String description,
    required int discountAmount,
    @Default('yen') String? discountUnit,
    String? validFrom,
    String? validUntil,
    String? storageLocation,
    @Default(false) bool requiresSurvey,
    String? surveyUrl,
  }) = _CouponDetected;

  factory CouponDetected.fromJson(Map<String, dynamic> json) =>
      _$CouponDetectedFromJson(json);
}

@freezed
sealed class LinePromotion with _$LinePromotion {
  const factory LinePromotion({
    required String description,
    String? lineUrl,
  }) = _LinePromotion;

  factory LinePromotion.fromJson(Map<String, dynamic> json) =>
      _$LinePromotionFromJson(json);
}

@freezed
sealed class ReceiptDiscount with _$ReceiptDiscount {
  const factory ReceiptDiscount({
    required String description,
    required int discountAmount,
  }) = _ReceiptDiscount;

  factory ReceiptDiscount.fromJson(Map<String, dynamic> json) =>
      _$ReceiptDiscountFromJson(json);
}

@freezed
sealed class ReceiptAnalysis with _$ReceiptAnalysis {
  const factory ReceiptAnalysis({
    required String storeName,
    required String purchasedAt,
    required int totalAmount,
    @JsonKey(includeIfNull: false) int? taxAmount,
    @Default('cash') String paymentMethod,
    @JsonKey(includeIfNull: false) String? category,
    required List<ReceiptItem> items,
    required List<CouponDetected> couponsDetected,
    @Default([]) List<LinePromotion> linePromotions,
    @Default('') String duplicateCheckHash,
    @Default(false) bool isMedical,
    @Default(false) bool isUncovered,
    @JsonKey(includeIfNull: false) int? totalPoints,
    @JsonKey(includeIfNull: false) double? burdenRate,
    @JsonKey(includeIfNull: false) String? memo,
    @Default(false) bool isBill,
    @JsonKey(includeIfNull: false) DateTime? billDueDate,
    @Default('unpaid') String billStatus,
    @JsonKey(includeIfNull: false) DateTime? billPaidDate,
    @Default(false) bool billIsTaxExempt,
    @Default(0) int savingsAmount,
  }) = _ReceiptAnalysis;

  factory ReceiptAnalysis.fromJson(Map<String, dynamic> json) =>
      _$ReceiptAnalysisFromJson(json);
}

@freezed
sealed class Receipt with _$Receipt {
  const factory Receipt({
    required String receiptId,
    required String storeName,
    required int totalAmount,
    required String purchasedAt,
    @Default('cash') String paymentMethod,
    required List<ReceiptItem> items,
    @Default([]) List<ReceiptDiscount> discounts,
    String? memo,
    @Default(0) int savingsAmount,
  }) = _Receipt;

  factory Receipt.fromJson(Map<String, dynamic> json) =>
      _$ReceiptFromJson(json);
}
