import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/bill_model.dart';
import '../../bill/services/bill_service.dart';

class CalendarBillDetailSheet extends StatefulWidget {
  final Bill bill;
  final NumberFormat fmt;
  final CamillColors colors;
  final VoidCallback onPaid;
  final void Function(String? memo) onMemoUpdated;

  const CalendarBillDetailSheet({
    super.key,
    required this.bill,
    required this.fmt,
    required this.colors,
    required this.onPaid,
    required this.onMemoUpdated,
  });

  @override
  State<CalendarBillDetailSheet> createState() => _CalendarBillDetailSheetState();
}

class _CalendarBillDetailSheetState extends State<CalendarBillDetailSheet> {
  final _service = BillService();
  late String? _memo;

  @override
  void initState() {
    super.initState();
    _memo = widget.bill.memo;
  }

  Future<void> _editMemo() async {
    final colors = widget.colors;
    final messenger = ScaffoldMessenger.of(context);
    final ctrl = TextEditingController(text: _memo ?? '');

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text('メモを編集', style: camillHeadingStyle(16, colors.textPrimary)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 4,
            style: camillBodyStyle(14, colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'メモを入力...',
              hintStyle: camillBodyStyle(14, colors.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('キャンセル', style: camillBodyStyle(14, colors.textMuted)),
            ),
            TextButton(
              onPressed: () {
                final text = ctrl.text;
                Navigator.pop(ctx, text);
              },
              child: Text('保存', style: camillBodyStyle(14, colors.primary, weight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
    if (result == null) return;

    final newMemo = result.trim().isEmpty ? null : result.trim();
    try {
      await _service.updateMemo(widget.bill.billId, newMemo);
      if (mounted) {
        setState(() => _memo = newMemo);
        widget.onMemoUpdated(newMemo);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final fmt = widget.fmt;
    final colors = widget.colors;
    final catColor = AppConstants.categoryColors[bill.category] ?? const Color(0xFF90A4AE);
    final catLabel = AppConstants.categoryLabels[bill.category] ?? 'その他';
    final isPaid = bill.status == BillStatus.paid;
    final days = bill.daysUntilDue;
    final urgent = bill.isUrgent;

    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 60,
        bottom: 0,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isPaid
                              ? colors.success.withAlpha(20)
                              : const Color(0xFFE53935).withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isPaid ? Icons.check_circle_outline : Icons.description_outlined,
                          color: isPaid ? colors.success : const Color(0xFFE53935),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bill.title, style: camillBodyStyle(17, colors.textPrimary, weight: FontWeight.w700)),
                            Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: catColor.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(catLabel, style: TextStyle(fontSize: 11, color: catColor, fontWeight: FontWeight.w600)),
                                ),
                                if (isPaid) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colors.success.withAlpha(25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('支払済み', style: TextStyle(fontSize: 11, color: colors.success, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('金額', style: camillBodyStyle(13, colors.textMuted)),
                      Text(fmt.format(bill.amount), style: camillAmountStyle(20, colors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('メモ', style: camillBodyStyle(12, colors.textMuted, weight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _editMemo,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _memo != null && _memo!.isNotEmpty ? _memo! : 'メモを追加...',
                              style: camillBodyStyle(
                                13,
                                _memo != null && _memo!.isNotEmpty ? colors.textSecondary : colors.textMuted,
                              ),
                            ),
                          ),
                          Icon(Icons.edit_outlined, size: 14, color: colors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isPaid) ...[
                    if (bill.paidAt != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('支払日', style: camillBodyStyle(13, colors.textMuted)),
                          Text(
                            '${bill.paidAt!.year}/${bill.paidAt!.month.toString().padLeft(2, '0')}/${bill.paidAt!.day.toString().padLeft(2, '0')}',
                            style: camillBodyStyle(14, colors.textPrimary, weight: FontWeight.w600),
                          ),
                        ],
                      ),
                    if (bill.dueDate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('支払期限', style: camillBodyStyle(13, colors.textMuted)),
                          Text(
                            '${bill.dueDate!.year}/${bill.dueDate!.month.toString().padLeft(2, '0')}/${bill.dueDate!.day.toString().padLeft(2, '0')}',
                            style: camillBodyStyle(14, colors.textMuted),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: colors.success.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.success.withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: colors.success, size: 18),
                          const SizedBox(width: 8),
                          Text('支払い済みです', style: camillBodyStyle(15, colors.success, weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ] else ...[
                    if (bill.dueDate != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('支払期限', style: camillBodyStyle(13, colors.textMuted)),
                          Row(
                            children: [
                              if (urgent)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.warning_amber_outlined, size: 14, color: Color(0xFFE53935)),
                                ),
                              Text(
                                '${bill.dueDate!.year}/${bill.dueDate!.month.toString().padLeft(2, '0')}/${bill.dueDate!.day.toString().padLeft(2, '0')}',
                                style: camillBodyStyle(14, urgent ? const Color(0xFFE53935) : colors.textPrimary, weight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (days != null) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            days >= 0 ? '残り$days日' : '期限切れ',
                            style: camillBodyStyle(12, urgent ? const Color(0xFFE53935) : colors.textMuted),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onPaid();
                        },
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: Text('支払いました', style: camillBodyStyle(15, Colors.white, weight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
