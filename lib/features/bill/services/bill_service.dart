import '../../../shared/models/bill_model.dart';
import '../../../shared/services/api_service.dart';

class BillService {
  final ApiService _api;
  BillService({ApiService? api}) : _api = api ?? ApiService();

  Future<List<Bill>> fetchBills({String? status}) async {
    final query = <String, String>{};
    if (status != null) query['status'] = status;
    final data = await _api.getAny('/bills', query: query);
    final list = data as List? ?? [];
    return list.map((e) => Bill.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Bill> createBill({
    required String title,
    required int amount,
    String? dueDate,
    String status = 'unpaid',
    String? category,
    String? paidAt,
  }) async {
    final data = await _api.postAny('/bills', body: {
      'title': title,
      'amount': amount,
      'due_date': dueDate,
      'status': status,
      'category': category,
      'paid_at': paidAt,
    });
    return Bill.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> analyzeBill(
      String imageBase64, String imageType) async {
    return _api.post('/bills/analyze', body: {
      'image_base64': imageBase64,
      'image_type': imageType,
    });
  }

  Future<void> payBill(String billId) async {
    await _api.patch('/bills/$billId/pay', body: {});
  }

  Future<void> deleteBill(String billId) async {
    await _api.delete('/bills/$billId');
  }
}
