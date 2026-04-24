import '../../../shared/models/fixed_expense_model.dart';
import '../../../shared/services/api_service.dart';

class FixedExpenseService {
  final ApiService _api;

  FixedExpenseService({ApiService? api}) : _api = api ?? ApiService();

  /// 全固定費の引き落とし日設定を取得（category → billingDay）
  Future<Map<String, FixedExpenseSetting>> getSettings() async {
    final data = await _api.get('/fixed-expenses/settings');
    return data.map(
      (cat, day) => MapEntry(cat, FixedExpenseSetting.fromEntry(cat, day)),
    );
  }

  /// 引き落とし日・休日ルールを更新（billingDay=null で削除）
  Future<void> updateBillingDay(
    String category, {
    required int? billingDay,
    String? holidayRule,
  }) async {
    await _api.patch(
      '/fixed-expenses/settings/$category',
      body: {'billing_day': billingDay, 'holiday_rule': holidayRule},
    );
  }

  /// 指定月の支払い実績を取得（category → FixedPayment）
  Future<Map<String, FixedPayment>> getPayments(String yearMonth) async {
    final data = await _api.get('/fixed-expenses/payments/$yearMonth');
    return data.map(
      (cat, json) => MapEntry(
        cat,
        FixedPayment.fromEntry(cat, yearMonth, json as Map<String, dynamic>),
      ),
    );
  }

  /// 手動で支払い済みにマーク
  Future<void> markPaid(String yearMonth, String category) async {
    await _api.post('/fixed-expenses/payments/$yearMonth/$category', body: {});
  }

  /// 支払いマークを取り消し
  Future<void> unmarkPaid(String yearMonth, String category) async {
    await _api.delete('/fixed-expenses/payments/$yearMonth/$category');
  }

  /// 銀行明細スクショをOCRしてマッチ結果を返す
  Future<List<BankTransaction>> scanBankStatement(String imageBase64) async {
    final data = await _api.post(
      '/fixed-expenses/scan',
      body: {'image': imageBase64},
    );
    final transactions = data['transactions'] as List<dynamic>? ?? [];
    return transactions
        .map((t) => BankTransaction.fromJson(t as Map<String, dynamic>))
        .toList();
  }
}
