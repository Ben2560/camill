import 'package:freezed_annotation/freezed_annotation.dart';

part 'bill_model.freezed.dart';
part 'bill_model.g.dart';

enum BillStatus { unpaid, pending, paid }

@freezed
sealed class Bill with _$Bill {
  const Bill._();

  const factory Bill({
    required String billId,
    required String title,
    required int amount,
    DateTime? dueDate,
    @JsonKey(unknownEnumValue: BillStatus.unpaid) required BillStatus status,
    required DateTime createdAt,
    String? category,
    @Default(false) bool isTaxExempt,
    DateTime? paidAt,
    String? memo,
  }) = _Bill;

  factory Bill.fromJson(Map<String, dynamic> json) => _$BillFromJson(json);

  int? get daysUntilDue {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  bool get isUrgent {
    final days = daysUntilDue;
    return days != null && days <= 3 && days >= 0;
  }
}
