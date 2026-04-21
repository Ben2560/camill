// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Bill _$BillFromJson(Map<String, dynamic> json) => _Bill(
  billId: json['bill_id'] as String,
  title: json['title'] as String,
  amount: (json['amount'] as num).toInt(),
  dueDate: json['due_date'] == null
      ? null
      : DateTime.parse(json['due_date'] as String),
  status: $enumDecode(
    _$BillStatusEnumMap,
    json['status'],
    unknownValue: BillStatus.unpaid,
  ),
  createdAt: DateTime.parse(json['created_at'] as String),
  category: json['category'] as String?,
  isTaxExempt: json['is_tax_exempt'] as bool? ?? false,
  paidAt: json['paid_at'] == null
      ? null
      : DateTime.parse(json['paid_at'] as String),
  memo: json['memo'] as String?,
);

Map<String, dynamic> _$BillToJson(_Bill instance) => <String, dynamic>{
  'bill_id': instance.billId,
  'title': instance.title,
  'amount': instance.amount,
  'due_date': instance.dueDate?.toIso8601String(),
  'status': _$BillStatusEnumMap[instance.status]!,
  'created_at': instance.createdAt.toIso8601String(),
  'category': instance.category,
  'is_tax_exempt': instance.isTaxExempt,
  'paid_at': instance.paidAt?.toIso8601String(),
  'memo': instance.memo,
};

const _$BillStatusEnumMap = {
  BillStatus.unpaid: 'unpaid',
  BillStatus.pending: 'pending',
  BillStatus.paid: 'paid',
};
