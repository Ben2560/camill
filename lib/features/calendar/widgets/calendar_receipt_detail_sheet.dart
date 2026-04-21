import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/summary_model.dart';
import '../../receipt/services/receipt_service.dart';

class CalendarReceiptDetailSheet extends StatefulWidget {
  final String receiptId;
  final ReceiptService receiptService;
  final NumberFormat fmt;
  final VoidCallback onDeleted;
  final void Function(ReceiptListItem, {bool focusMemo}) onEdit;

  const CalendarReceiptDetailSheet({
    super.key,
    required this.receiptId,
    required this.receiptService,
    required this.fmt,
    required this.onDeleted,
    required this.onEdit,
  });

  @override
  State<CalendarReceiptDetailSheet> createState() => _CalendarReceiptDetailSheetState();
}

class _CalendarReceiptDetailSheetState extends State<CalendarReceiptDetailSheet> {
  Receipt? _receipt;
  bool _loading = true;
  bool _deleting = false;
  final _sheetController = DraggableScrollableController();
  bool _isClosing = false;
  double? _contentFraction;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetChange);
    _load();
  }

  void _onSheetChange() {
    if (_isClosing) return;
    if (_sheetController.isAttached && _sheetController.size < 0.15 && mounted) {
      _isClosing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetChange);
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await widget.receiptService.getReceiptDetail(widget.receiptId);
      if (mounted) {
        final screenH = MediaQuery.sizeOf(context).height;
        final memoLines = (r.memo ?? '').split('\n').length;
        final memoH = r.memo != null && r.memo!.isNotEmpty
            ? 60.0 + memoLines * 20.0
            : 60.0;
        final savingsH = r.savingsAmount > 0 ? 46.0 : 0.0;
        final totalH = 244.0 + r.items.length * 50.0 + memoH + savingsH;
        final fraction = (totalH / screenH).clamp(0.40, 0.93);
        setState(() {
          _receipt = r;
          _loading = false;
          _contentFraction = fraction;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _sheetController.isAttached) {
            _sheetController.animateTo(
              fraction,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          '削除の確認',
          style: camillBodyStyle(16, colors.textPrimary, weight: FontWeight.w700),
        ),
        content: Text(
          'このレシートを削除しますか？\nこの操作は元に戻せません。',
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
              '削除する',
              style: camillBodyStyle(14, const Color(0xFFFF3B30), weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.receiptService.deleteReceipt(widget.receiptId);
      if (mounted) {
        Navigator.pop(context);
        widget.onDeleted();
      }
    } catch (_) {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final r = _receipt;
    final isMedical = r != null && r.items.isNotEmpty &&
        r.items.any((item) => item.category == 'medical');
    final totalPoints = isMedical
        ? r.items.fold<int>(0, (s, e) => s + e.unitPrice ~/ 10)
        : 0;

    final handle = Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: colors.surfaceBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

    final snapTo = _contentFraction ?? 0.93;
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.40,
      minChildSize: 0.01,
      maxChildSize: snapTo,
      snap: true,
      snapSizes: [snapTo],
      expand: false,
      builder: (_, controller) {
        const decoration = BorderRadius.vertical(top: Radius.circular(24));
        if (_loading) {
          return Material(
            color: colors.background,
            borderRadius: decoration,
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              handle,
              Expanded(child: Center(child: CircularProgressIndicator(color: colors.primary))),
            ]),
          );
        }
        if (r == null) {
          return Material(
            color: colors.background,
            borderRadius: decoration,
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              handle,
              Expanded(child: Center(child: Text('読み込みに失敗しました', style: camillBodyStyle(14, colors.textMuted)))),
            ]),
          );
        }
        final purchasedAt = DateTime.parse(r.purchasedAt).toLocal();
        final hasTime = purchasedAt.hour != 0 || purchasedAt.minute != 0;
        final dateLabel = hasTime
            ? DateFormat('yyyy年M月d日 HH:mm').format(purchasedAt)
            : DateFormat('yyyy年M月d日').format(purchasedAt);

        Widget buildTotals() {
          if (isMedical) {
            final tenKaiAmount = totalPoints * 10;
            final burdenWari = tenKaiAmount > 0
                ? ((r.totalAmount / tenKaiAmount) * 10).round()
                : 0;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Column(
                children: [
                  Divider(height: 1, color: colors.surfaceBorder),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('合計', style: camillBodyStyle(13, colors.textMuted)),
                      const SizedBox(width: 6),
                      Text('$totalPoints点', style: camillBodyStyle(15, colors.textPrimary, weight: FontWeight.w600)),
                      const Spacer(),
                      Text('10割: ${widget.fmt.format(tenKaiAmount)}', style: camillBodyStyle(12, colors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('負担率', style: camillBodyStyle(13, colors.textMuted)),
                      Text('$burdenWari割負担', style: camillBodyStyle(13, colors.textSecondary, weight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('実負担額', style: camillBodyStyle(14, colors.textPrimary, weight: FontWeight.bold)),
                      Text(widget.fmt.format(r.totalAmount), style: camillAmountStyle(18, colors.textPrimary)),
                    ],
                  ),
                ],
              ),
            );
          }
          final subtotal = r.items.fold<int>(0, (s, e) => s + e.amount);
          final tax = r.totalAmount - subtotal;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Column(
              children: [
                Divider(height: 1, color: colors.surfaceBorder),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('小計', style: camillBodyStyle(13, colors.textMuted)),
                    Text(widget.fmt.format(subtotal), style: camillBodyStyle(13, colors.textMuted)),
                  ],
                ),
                if (tax > 0) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('消費税', style: camillBodyStyle(13, colors.textMuted)),
                      Text(widget.fmt.format(tax), style: camillBodyStyle(13, colors.textMuted)),
                    ],
                  ),
                ],
                for (final d in r.discounts) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('割引', style: camillBodyStyle(13, colors.textMuted)),
                      Text('-${widget.fmt.format(d.discountAmount)}', style: camillBodyStyle(13, colors.textMuted)),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('合計', style: camillBodyStyle(14, colors.textPrimary, weight: FontWeight.bold)),
                    Text(widget.fmt.format(r.totalAmount), style: camillAmountStyle(18, colors.textPrimary)),
                  ],
                ),
                if (r.savingsAmount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.success.withValues(alpha: 0.3)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.savings_outlined, size: 16, color: colors.success),
                        const SizedBox(width: 6),
                        Text('節約', style: camillBodyStyle(12, colors.success, weight: FontWeight.w600)),
                        const Spacer(),
                        Text(widget.fmt.format(r.savingsAmount), style: camillAmountStyle(14, colors.success)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        Widget footer = ColoredBox(
          color: colors.background,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildTotals(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _deleting ? null : _delete,
                        icon: _deleting
                            ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colors.danger))
                            : Icon(Icons.delete_outline, size: 18, color: colors.danger),
                        label: Text('削除', style: camillBodyStyle(15, colors.danger, weight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: colors.danger),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onEdit(ReceiptListItem(
                            receiptId: r.receiptId,
                            storeName: r.storeName,
                            totalAmount: r.totalAmount,
                            purchasedAt: r.purchasedAt,
                            paymentMethod: r.paymentMethod,
                            category: r.items.isNotEmpty ? r.items.first.category : 'other',
                            items: r.items,
                          ));
                        },
                        icon: Icon(Icons.edit_outlined, size: 18, color: colors.fabIcon),
                        label: Text('編集する', style: camillBodyStyle(15, colors.fabIcon, weight: FontWeight.w600)),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        return Material(
          color: colors.background,
          borderRadius: decoration,
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomScrollView(
                  controller: controller,
                  slivers: [
                    SliverToBoxAdapter(child: handle),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.storeName, style: camillBodyStyle(18, colors.textPrimary, weight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 13, color: colors.textMuted),
                                const SizedBox(width: 4),
                                Text(dateLabel, style: camillBodyStyle(13, colors.textMuted)),
                                const SizedBox(width: 12),
                                Icon(Icons.payment_outlined, size: 13, color: colors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  AppConstants.paymentLabels[r.paymentMethod] ?? r.paymentMethod,
                                  style: camillBodyStyle(13, colors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: Divider(height: 1, color: colors.surfaceBorder)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      sliver: SliverList.builder(
                        itemCount: r.items.length,
                        itemBuilder: (_, i) {
                          final item = r.items[i];
                          final catLabel = AppConstants.categoryLabels[item.category] ?? item.category;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.itemName, style: camillBodyStyle(14, colors.textPrimary)),
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colors.primaryLight,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(catLabel, style: camillBodyStyle(10, colors.primary)),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  isMedical
                                      ? '${item.unitPrice ~/ 10}点'
                                      : '${item.quantity > 1 ? '×${item.quantity}  ' : ''}${widget.fmt.format(item.amount)}',
                                  style: camillBodyStyle(14, colors.textPrimary, weight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            widget.onEdit(ReceiptListItem(
                              receiptId: r.receiptId,
                              storeName: r.storeName,
                              totalAmount: r.totalAmount,
                              purchasedAt: r.purchasedAt,
                              paymentMethod: r.paymentMethod,
                              category: r.items.isNotEmpty ? r.items.first.category : 'other',
                              items: r.items,
                              memo: r.memo,
                            ), focusMemo: true);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.surfaceBorder),
                            ),
                            child: (r.memo != null && r.memo!.isNotEmpty)
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.notes_outlined, size: 14, color: colors.textMuted),
                                          const SizedBox(width: 5),
                                          Text('メモ', style: camillBodyStyle(13, colors.textMuted, weight: FontWeight.w600)),
                                          const Spacer(),
                                          Icon(Icons.edit_outlined, size: 13, color: colors.textMuted),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(r.memo!, style: camillBodyStyle(14, colors.textPrimary)),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add, size: 16, color: colors.textMuted),
                                      const SizedBox(width: 6),
                                      Text('メモを追加', style: camillBodyStyle(14, colors.textMuted)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 160 + MediaQuery.of(context).padding.bottom)),
                  ],
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: footer,
              ),
            ],
          ),
        );
      },
    );
  }
}
