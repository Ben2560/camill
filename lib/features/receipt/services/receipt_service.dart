import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/overseas_service.dart';

class ReceiptService {
  final _api = ApiService();

  Future<Uint8List> _compressImage(File imageFile) async {
    final result = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      minWidth: 1000,
      minHeight: 1500,
      quality: 75,
      format: CompressFormat.jpeg,
    );
    return result ?? await imageFile.readAsBytes();
  }

  Future<List<ReceiptAnalysis>> analyzeReceipt(
    File imageFile, {
    String? documentHint,
  }) async {
    final compressed = await _compressImage(imageFile);
    final base64Image = base64Encode(compressed);
    final overseasService = OverseasService(_api);
    final isOverseas = await overseasService.getIsOverseas();
    final overseasCurrency = isOverseas
        ? await overseasService.getCurrentCurrency()
        : 'JPY';
    final body = <String, dynamic>{
      'image_base64': 'data:image/jpeg;base64,$base64Image',
      'image_type': 'jpeg',
      'document_hint': documentHint,
      if (isOverseas) ...{
        'is_overseas': true,
        'current_currency': overseasCurrency,
      },
    };
    final data = await _api
        .post('/receipts/analyze', body: body)
        .timeout(const Duration(seconds: 120));
    List<ReceiptAnalysis> receipts;
    if (data.containsKey('receipts')) {
      receipts = (data['receipts'] as List<dynamic>)
          .map((e) => ReceiptAnalysis.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      receipts = [ReceiptAnalysis.fromJson(data)];
    }
    return _mergeReceiptsAndCoupons(receipts);
  }

  List<ReceiptAnalysis> _mergeReceiptsAndCoupons(
    List<ReceiptAnalysis> receipts,
  ) {
    if (receipts.length <= 1) return receipts;
    final groups = <String, List<ReceiptAnalysis>>{};
    for (final r in receipts) {
      final key = _mergeKey(r.storeName, r.purchasedAt);
      groups.putIfAbsent(key, () => []).add(r);
    }
    return groups.values.map((group) {
      if (group.length == 1) return group.first;
      group.sort((a, b) => b.items.length.compareTo(a.items.length));
      final base = group.first;
      final allCoupons = group.expand((r) => r.couponsDetected).toList();
      final allLinePromos = group.expand((r) => r.linePromotions).toList();
      return ReceiptAnalysis(
        storeName: base.storeName,
        purchasedAt: base.purchasedAt,
        totalAmount: base.totalAmount,
        taxAmount: base.taxAmount,
        paymentMethod: base.paymentMethod,
        category: base.category,
        items: base.items,
        couponsDetected: allCoupons,
        linePromotions: allLinePromos,
        duplicateCheckHash: base.duplicateCheckHash,
        isMedical: base.isMedical,
        totalPoints: base.totalPoints,
        burdenRate: base.burdenRate,
        isBill: base.isBill,
        billDueDate: base.billDueDate,
        billStatus: base.billStatus,
      );
    }).toList();
  }

  String _mergeKey(String storeName, String purchasedAt) {
    final normalized = storeName.toLowerCase().trim();
    final dt = DateTime.tryParse(purchasedAt)?.toLocal();
    if (dt == null) return normalized;
    final dateStr =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$normalized|$dateStr';
  }

  // 確認済みデータをDBに登録
  Future<String> saveReceipt(ReceiptAnalysis analysis) async {
    final data = await _api.post('/receipts', body: analysis.toJson());
    return data['receipt_id'] as String;
  }

  // 既存レシートを削除してから再登録（上書き）、新しい receipt_id を返す
  Future<String> overwriteReceipt(
    String existingReceiptId,
    ReceiptAnalysis analysis,
  ) async {
    await _api.delete('/receipts/$existingReceiptId');
    final body = analysis.toJson();
    body['duplicate_check_hash'] = '';
    final data = await _api.post('/receipts', body: body);
    return data['receipt_id'] as String;
  }

  // レシート一覧取得
  Future<List<Receipt>> getReceipts(String yearMonth) async {
    final data = await _api.get('/receipts', query: {'year_month': yearMonth});
    final list = (data['receipts'] as List<dynamic>?) ?? [];
    return list
        .map((e) => Receipt.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // レシート詳細取得
  Future<Receipt> getReceiptDetail(String receiptId) async {
    final data = await _api.get('/receipts/$receiptId');
    return Receipt.fromJson(data);
  }

  // レシート削除
  Future<void> deleteReceipt(String receiptId) async {
    await _api.delete('/receipts/$receiptId');
  }

  // メモのみ更新
  Future<void> updateMemo(String receiptId, String memo) async {
    await _api.patch(
      '/receipts/$receiptId',
      body: {'memo': memo.isEmpty ? null : memo},
    );
  }

  /// データが存在する月の一覧を取得（"yyyy-MM" 形式、昇順）
  Future<List<String>> getActiveMonths() async {
    final data = await _api.getAny('/receipts/active-months');
    final list =
        ((data as Map<String, dynamic>)['months'] as List<dynamic>?) ?? [];
    return list.cast<String>();
  }
}
