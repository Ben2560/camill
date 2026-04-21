import 'package:flutter/material.dart';

import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/coupon_model.dart';
import '../../../shared/widgets/top_notification.dart';
import '../../coupon/services/coupon_service.dart';

class CalendarCouponActionSheet extends StatefulWidget {
  final Coupon coupon;
  final CouponService couponService;
  final VoidCallback onChanged;

  const CalendarCouponActionSheet({
    super.key,
    required this.coupon,
    required this.couponService,
    required this.onChanged,
  });

  @override
  State<CalendarCouponActionSheet> createState() => _CalendarCouponActionSheetState();
}

class _CalendarCouponActionSheetState extends State<CalendarCouponActionSheet> {
  bool _busy = false;

  Future<void> _markUsed() async {
    setState(() => _busy = true);
    try {
      await widget.couponService.useCoupon(widget.coupon.couponId);
      if (mounted) {
        Navigator.pop(context);
        widget.onChanged();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _delete() async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          '削除確認',
          style: camillBodyStyle(16, colors.textPrimary, weight: FontWeight.w700),
        ),
        content: Text(
          'このクーポンを削除しますか？',
          style: camillBodyStyle(14, colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('キャンセル', style: camillBodyStyle(14, colors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '削除',
              style: camillBodyStyle(14, colors.danger, weight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.couponService.deleteCoupon(widget.coupon.couponId);
      if (mounted) {
        Navigator.pop(context);
        widget.onChanged();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showTopNotification(context, '削除に失敗しました: $e');
      }
    }
  }

  Future<void> _showEditDialog() async {
    final colors = context.colors;
    final c = widget.coupon;
    final nameCtrl = TextEditingController(text: c.storeName);
    final descCtrl = TextEditingController(text: c.description);
    final amountCtrl = TextEditingController(text: c.discountAmount.toString());
    DateTime? validFrom = c.validFrom;
    DateTime? validUntil = c.validUntil;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'クーポンを編集',
            style: camillHeadingStyle(16, colors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: camillBodyStyle(14, colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: '店名',
                    labelStyle: camillBodyStyle(13, colors.textMuted),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  style: camillBodyStyle(14, colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: '内容',
                    labelStyle: camillBodyStyle(13, colors.textMuted),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: camillBodyStyle(14, colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: '割引額（円）※無料は0',
                    labelStyle: camillBodyStyle(13, colors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: validFrom ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDlg(() => validFrom = picked);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: colors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        validFrom != null
                            ? '開始: ${validFrom!.year}/${validFrom!.month}/${validFrom!.day}'
                            : '開始日を選択（任意）',
                        style: camillBodyStyle(13, colors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: validUntil ?? DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDlg(() => validUntil = picked);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.event_available, size: 16, color: colors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        validUntil != null
                            ? '有効期限: ${validUntil!.year}/${validUntil!.month}/${validUntil!.day}'
                            : '有効期限を選択（任意）',
                        style: camillBodyStyle(13, colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('キャンセル', style: camillBodyStyle(14, colors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await widget.couponService.deleteCoupon(c.couponId);
                  await widget.couponService.createCoupon(
                    storeName: nameCtrl.text,
                    description: descCtrl.text,
                    discountAmount: int.tryParse(amountCtrl.text) ?? 0,
                    validFrom: validFrom?.toIso8601String(),
                    validUntil: validUntil?.toIso8601String(),
                    isFromOcr: c.isFromOcr,
                    availableDays: c.availableDays,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    widget.onChanged();
                  }
                } catch (e) {
                  if (mounted) {
                    showTopNotification(context, '編集に失敗しました: $e');
                  }
                }
              },
              child: Text('保存', style: camillBodyStyle(14, colors.fabIcon)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final c = widget.coupon;
    final canUse = !c.isUsed && !c.isExpired;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textMuted.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.store_outlined, size: 14, color: colors.textMuted),
                    const SizedBox(width: 4),
                    Text(c.storeName, style: camillBodyStyle(13, colors.textMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(c.description, style: camillBodyStyle(16, colors.textPrimary, weight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  c.discountAmount > 0 ? '${c.discountAmount}円引き' : '無料',
                  style: camillAmountStyle(22, colors.accent),
                ),
                if (c.validUntil != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 13, color: colors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        c.validFrom != null
                            ? '${c.validFrom!.month}/${c.validFrom!.day}〜${c.validUntil!.month}/${c.validUntil!.day}'
                            : '〜${c.validUntil!.month}/${c.validUntil!.day}',
                        style: camillBodyStyle(12, colors.textMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                if (canUse)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _busy ? null : _markUsed,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: Text('使用済みにする', style: camillBodyStyle(16, Colors.white, weight: FontWeight.bold)),
                    ),
                  ),
                if (canUse) const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: colors.surfaceBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _busy ? null : _showEditDialog,
                        icon: Icon(Icons.edit_outlined, size: 18, color: colors.textSecondary),
                        label: Text('編集', style: camillBodyStyle(14, colors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: colors.danger.withAlpha(120)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _busy ? null : _delete,
                        icon: Icon(Icons.delete_outline, size: 18, color: colors.danger),
                        label: Text('削除', style: camillBodyStyle(14, colors.danger)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
