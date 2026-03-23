import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/services/api_service.dart';

class ReceiptService {
  final _api = ApiService();

  /// 画像を幅1000px・品質75のJPEGに圧縮する
  Future<Uint8List> _compressImage(File imageFile) async {
    final result = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      minWidth: 1000,
      minHeight: 1500,
      quality: 75,
      format: CompressFormat.jpeg,
    );
    // 圧縮失敗時はそのまま送信
    return result ?? await imageFile.readAsBytes();
  }

  // 画像を圧縮→Base64エンコードして解析リクエスト
  Future<ReceiptAnalysis> analyzeReceipt(File imageFile) async {
    final compressed = await _compressImage(imageFile);
    final base64Image = base64Encode(compressed);

    final data = await _api.post('/receipts/analyze', body: {
      'image_base64': 'data:image/jpeg;base64,$base64Image',
      'image_type': 'jpeg',
    });
    return ReceiptAnalysis.fromJson(data);
  }

  // 確認済みデータをDBに登録
  Future<String> saveReceipt(ReceiptAnalysis analysis) async {
    final data = await _api.post('/receipts', body: analysis.toJson());
    return data['receipt_id'] as String;
  }

  // 既存レシートを削除してから再登録（上書き）、新しい receipt_id を返す
  Future<String> overwriteReceipt(
      String existingReceiptId, ReceiptAnalysis analysis) async {
    await _api.delete('/receipts/$existingReceiptId');
    final body = analysis.toJson();
    body['duplicate_check_hash'] = '';
    final data = await _api.post('/receipts', body: body);
    return data['receipt_id'] as String;
  }

  // レシート一覧取得
  Future<List<Receipt>> getReceipts(String yearMonth) async {
    final data = await _api.get('/receipts', query: {'year_month': yearMonth});
    final list = data['receipts'] as List<dynamic>;
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
}
