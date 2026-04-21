import '../../../shared/models/coupon_model.dart';
import '../../../shared/services/api_service.dart';

class CouponService {
  final ApiService _api;
  CouponService({ApiService? api}) : _api = api ?? ApiService();

  Future<List<Coupon>> fetchCoupons({bool? isUsed}) async {
    final query = <String, String>{};
    if (isUsed != null) query['is_used'] = isUsed.toString();
    final data = await _api.getAny('/coupons', query: query);
    final list = data as List? ?? [];
    return list.map((e) => Coupon.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Coupon> createCoupon({
    required String storeName,
    required String description,
    required int discountAmount,
    String? validFrom,
    String? validUntil,
    List<int>? availableDays,
    bool isFromOcr = false,
    bool isUsed = false,
    String? receiptId,
    bool requiresSurvey = false,
    String? surveyUrl,
    bool surveyAnswered = false,
  }) async {
    final data = await _api.postAny(
      '/coupons',
      body: {
        'store_name': storeName,
        'description': description,
        'discount_amount': discountAmount,
        'valid_from': ?validFrom,
        'valid_until': ?validUntil,
        'available_days': ?availableDays,
        'is_from_ocr': isFromOcr,
        'is_used': isUsed,
        'receipt_id': ?receiptId,
        'requires_survey': requiresSurvey,
        'survey_url': ?surveyUrl,
        'survey_answered': surveyAnswered,
      },
    );
    return Coupon.fromJson(data as Map<String, dynamic>);
  }

  Future<void> markSurveyAnswered(String couponId) async {
    await _api.patch('/coupons/$couponId/survey-answered', body: {});
  }

  Future<void> useCoupon(String couponId) async {
    await _api.patch('/coupons/$couponId/use', body: {});
  }

  Future<void> deleteCoupon(String couponId) async {
    await _api.delete('/coupons/$couponId');
  }

  Future<void> shareToCommunity(String couponId) async {
    await _api.patch('/coupons/$couponId/share-to-community', body: {});
  }
}
