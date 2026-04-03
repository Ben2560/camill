enum BillStatus { unpaid, pending, paid }

class Bill {
  final String billId;
  final String title;
  final int amount;
  final DateTime? dueDate;
  final BillStatus status;
  final DateTime createdAt;
  final String? category;
  final DateTime? paidAt;

  Bill({
    required this.billId,
    required this.title,
    required this.amount,
    this.dueDate,
    required this.status,
    required this.createdAt,
    this.category,
    this.paidAt,
  });

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        billId: json['bill_id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toInt(),
        dueDate: json['due_date'] != null
            ? DateTime.parse(json['due_date'] as String)
            : null,
        status: _statusFromString(json['status'] as String? ?? 'unpaid'),
        createdAt: DateTime.parse(json['created_at'] as String),
        category: json['category'] as String?,
        paidAt: json['paid_at'] != null
            ? DateTime.parse(json['paid_at'] as String).toLocal()
            : null,
      );

  static BillStatus _statusFromString(String s) {
    switch (s) {
      case 'pending':
        return BillStatus.pending;
      case 'paid':
        return BillStatus.paid;
      default:
        return BillStatus.unpaid;
    }
  }

  Bill copyWith({BillStatus? status, DateTime? paidAt}) => Bill(
        billId: billId,
        title: title,
        amount: amount,
        dueDate: dueDate,
        status: status ?? this.status,
        createdAt: createdAt,
        category: category,
        paidAt: paidAt ?? this.paidAt,
      );

  int? get daysUntilDue {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  bool get isUrgent {
    final days = daysUntilDue;
    return days != null && days <= 3 && days >= 0;
  }
}
