import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../shared/services/api_service.dart';

class PurchaseService {
  // App Store Connect に登録するプロダクトID
  static const proMonthlyId = 'camill_pro_monthly';
  static const proAnnualId = 'camill_pro_annual';
  static const familyMonthlyId = 'camill_family_monthly';
  static const familyAnnualId = 'camill_family_annual';
  static const _productIds = {
    proMonthlyId,
    proAnnualId,
    familyMonthlyId,
    familyAnnualId,
  };

  static const planByProduct = {
    proMonthlyId: 'pro',
    proAnnualId: 'pro_annual',
    familyMonthlyId: 'family',
    familyAnnualId: 'family_annual',
  };

  final _iap = InAppPurchase.instance;
  final _api = ApiService();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];

  /// 購入完了時に呼ばれるコールバック（プランの更新通知用）
  VoidCallback? onPurchaseComplete;

  /// エラー時に呼ばれるコールバック
  void Function(String message)? onPurchaseError;

  List<ProductDetails> get products => _products;

  ProductDetails? product(String id) =>
      _products.where((p) => p.id == id).firstOrNull;

  Future<void> init() async {
    // isAvailable() が先に投げることで purchaseStream に触れずに済む。
    // Xcode の In-App Purchase capability が未設定の環境では
    // canMakePayments チャンネルが存在せず例外が飛ぶため、ここで早期リターン。
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        debugPrint('[IAP] Store not available');
        return;
      }

      _subscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdate,
        onError: (e) => debugPrint('[IAP] stream error: $e'),
      );

      final response = await _iap.queryProductDetails(_productIds);
      if (response.error != null) {
        debugPrint('[IAP] query error: ${response.error}');
      }
      _products = response.productDetails;
      debugPrint('[IAP] loaded ${_products.length} products');
    } catch (e) {
      debugPrint('[IAP] not available (capability not configured?): $e');
    }
  }

  Future<void> buy(String productId) async {
    final p = product(productId);
    if (p == null) {
      onPurchaseError?.call('商品情報を取得できませんでした');
      return;
    }
    try {
      final param = PurchaseParam(productDetails: p);
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('[IAP] buy error: $e');
      onPurchaseError?.call('購入処理に失敗しました');
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[IAP] restore error: $e');
      onPurchaseError?.call('購入の復元に失敗しました');
    }
  }

  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndActivate(purchase);
          await _iap.completePurchase(purchase);
        case PurchaseStatus.error:
          onPurchaseError?.call(
            purchase.error?.message ?? '購入処理に失敗しました',
          );
        default:
          break;
      }
    }
  }

  Future<void> _verifyAndActivate(PurchaseDetails purchase) async {
    final plan = planByProduct[purchase.productID];
    if (plan == null) return;
    try {
      await _api.post('/billing/verify-purchase', body: {
        'product_id': purchase.productID,
        'plan': plan,
        'verification_data':
            purchase.verificationData.serverVerificationData,
        'source': purchase.verificationData.source,
        'is_trial': purchase.status == PurchaseStatus.restored
            ? false
            : true, // 初回購入はトライアル扱い
      });
      onPurchaseComplete?.call();
    } catch (e) {
      debugPrint('[IAP] verify error: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
