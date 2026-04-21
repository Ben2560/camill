import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/receipt_model.dart';

/// スワイプで削除できるラッパー
class ReceiptSwipeable extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final Color background;

  const ReceiptSwipeable({
    super.key,
    required this.child,
    required this.onDelete,
    required this.background,
  });

  @override
  State<ReceiptSwipeable> createState() => _ReceiptSwipeableState();
}

class _ReceiptSwipeableState extends State<ReceiptSwipeable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _openX = -48.0;
  static const _spring = SpringDescription(mass: 1, stiffness: 400, damping: 22);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(vsync: this, value: 0.0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _ctrl.value = (_ctrl.value + d.delta.dx).clamp(_openX, 0.0);
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dx;
    final target = (_ctrl.value < _openX / 2 || v < -300) ? _openX : 0.0;
    _ctrl.animateWith(SpringSimulation(_spring, _ctrl.value, target, v));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: GestureDetector(
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 48,
              child: GestureDetector(
                onTap: widget.onDelete,
                child: const Center(
                  child: Icon(Icons.remove_circle, color: Color(0xFFFF3B30), size: 26),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) =>
                  Transform.translate(offset: Offset(_ctrl.value, 0), child: child),
              child: ColoredBox(color: widget.background, child: widget.child),
            ),
          ],
        ),
      ),
    );
  }
}

/// ヘッダー行（編集可能）
class ReceiptEditableInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? badge;
  final IconData icon;
  final CamillColors colors;
  final VoidCallback onTap;

  const ReceiptEditableInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.badge,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textMuted),
          const SizedBox(width: 8),
          Text('$label: ', style: camillBodyStyle(13, colors.textMuted)),
          Expanded(
            child: Text(value,
                style: camillBodyStyle(13, colors.textPrimary, weight: FontWeight.w500)),
          ),
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primaryLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge!,
                  style: camillBodyStyle(10, colors.primary, weight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
          ],
          Icon(Icons.edit_outlined, size: 14, color: colors.textMuted),
        ],
      ),
    );
  }
}

/// 品目行（編集可能）
class ReceiptEditableItemRow extends StatelessWidget {
  final ReceiptItem item;
  final NumberFormat fmt;
  final CamillColors colors;
  final bool isMedical;
  final VoidCallback onTap;
  final bool isOverseas;
  final String overseasCurrency;
  final double exchangeRate;

  const ReceiptEditableItemRow({
    super.key,
    required this.item,
    required this.fmt,
    required this.colors,
    required this.isMedical,
    required this.onTap,
    this.isOverseas = false,
    this.overseasCurrency = 'JPY',
    this.exchangeRate = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final catLabel = AppConstants.categoryLabels[item.category] ?? item.category;
    final showTranslation = isOverseas &&
        item.itemNameRaw.isNotEmpty &&
        item.itemName.isNotEmpty &&
        item.itemNameRaw != item.itemName;
    final primaryName =
        (isOverseas && item.itemNameRaw.isNotEmpty) ? item.itemNameRaw : item.itemName;

    Widget amountWidget;
    if (isMedical) {
      amountWidget = Text('${item.points}点',
          style: camillBodyStyle(14, colors.textPrimary, weight: FontWeight.w500));
    } else if (isOverseas) {
      final jpyAmount = (item.amount * exchangeRate).round();
      amountWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$overseasCurrency ${item.amount}',
              style: camillBodyStyle(14, colors.textPrimary, weight: FontWeight.w500)),
          Text('¥$jpyAmount', style: camillBodyStyle(11, colors.textMuted)),
        ],
      );
    } else {
      amountWidget = Text(fmt.format(item.amount),
          style: camillBodyStyle(14, colors.textPrimary, weight: FontWeight.w500));
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(primaryName,
                      style: camillBodyStyle(14, colors.textPrimary, weight: FontWeight.w500)),
                  if (showTranslation)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text('↪︎ ${item.itemName}',
                          style: camillBodyStyle(12, colors.textMuted)),
                    ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(catLabel, style: camillBodyStyle(11, colors.primary)),
                  ),
                ],
              ),
            ),
            amountWidget,
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 16, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// カテゴリピッカー
class ReceiptCategoryPicker extends StatelessWidget {
  final String current;
  final void Function(String) onSelected;

  const ReceiptCategoryPicker({
    super.key,
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: SingleChildScrollView(
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text('カテゴリを選択',
                  style: camillBodyStyle(17, colors.textPrimary, weight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            ...AppConstants.categoryLabels.entries.map(
              (e) => ListTile(
                title: Text(e.value, style: camillBodyStyle(15, colors.textPrimary)),
                leading: Icon(
                  current == e.key ? Icons.check_circle : Icons.circle_outlined,
                  color: current == e.key ? colors.primary : colors.textMuted,
                ),
                onTap: () => onSelected(e.key),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// 日付ピッカーフィールド
class ReceiptDatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final CamillColors colors;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;
  final bool withTime;

  const ReceiptDatePickerField({
    super.key,
    required this.label,
    required this.date,
    required this.colors,
    required this.onPick,
    required this.onClear,
    this.withTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    final hasTime = hasDate && (date!.hour != 0 || date!.minute != 0);
    String displayText;
    if (hasDate) {
      displayText = '${date!.month}/${date!.day}';
      if (hasTime) {
        displayText +=
            ' ${date!.hour.toString().padLeft(2, '0')}:${date!.minute.toString().padLeft(2, '0')}';
      }
    } else {
      displayText = label;
    }

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2040),
        );
        if (picked == null || !context.mounted) return;
        if (!withTime) {
          onPick(picked);
          return;
        }
        final time = await showTimePicker(
          context: context,
          initialTime: hasDate ? TimeOfDay.fromDateTime(date!) : TimeOfDay.now(),
        );
        onPick(DateTime(picked.year, picked.month, picked.day,
            time?.hour ?? 0, time?.minute ?? 0));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.surfaceBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 14, color: colors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(displayText,
                  style: camillBodyStyle(
                      13, hasDate ? colors.textPrimary : colors.textMuted)),
            ),
            if (hasDate)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 14, color: colors.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

/// 請求書セクション（支払状態スライダー）
class ReceiptBillSection extends StatefulWidget {
  final String billStatus;
  final CamillColors colors;
  final void Function(String) onStatusChange;

  const ReceiptBillSection({
    super.key,
    required this.billStatus,
    required this.colors,
    required this.onStatusChange,
  });

  @override
  State<ReceiptBillSection> createState() => _ReceiptBillSectionState();
}

class _ReceiptBillSectionState extends State<ReceiptBillSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  static const _unpaidColor = Color(0xFFE53935);
  static const _paidColor = Color(0xFF43A047);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (widget.billStatus == 'paid') _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(ReceiptBillSection old) {
    super.didUpdateWidget(old);
    if (old.billStatus != widget.billStatus) {
      widget.billStatus == 'paid' ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    if (_ctrl.value >= 0.5) {
      _ctrl.forward();
      widget.onStatusChange('paid');
    } else {
      _ctrl.reverse();
      widget.onStatusChange('unpaid');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.danger.withAlpha(120)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 18, color: colors.danger),
              const SizedBox(width: 8),
              Text('請求内容',
                  style: camillBodyStyle(15, colors.textPrimary, weight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final halfWidth = totalWidth / 2;
            return GestureDetector(
              onTapDown: (d) {
                if (d.localPosition.dx < halfWidth) {
                  _ctrl.reverse();
                  widget.onStatusChange('unpaid');
                } else {
                  _ctrl.forward();
                  widget.onStatusChange('paid');
                }
              },
              onHorizontalDragUpdate: (d) {
                _ctrl.value =
                    (_ctrl.value + d.delta.dx / halfWidth).clamp(0.0, 1.0);
              },
              onHorizontalDragEnd: (_) => _commit(),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.surfaceBorder),
                ),
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) {
                    final t = _anim.value;
                    final indicatorColor =
                        Color.lerp(_unpaidColor, _paidColor, t)!.withAlpha(210);
                    final leftPos = t * halfWidth;
                    return Stack(
                      children: [
                        Positioned(
                          left: leftPos + 2,
                          top: 2,
                          bottom: 2,
                          width: halfWidth - 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: indicatorColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: indicatorColor.withAlpha(80),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.pending_outlined,
                                        size: 14,
                                        color: Color.lerp(Colors.white, colors.textMuted, t)),
                                    const SizedBox(width: 4),
                                    Text('未払い',
                                        style: camillBodyStyle(
                                            13, Color.lerp(Colors.white, colors.textMuted, t)!,
                                            weight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        size: 14,
                                        color: Color.lerp(colors.textMuted, Colors.white, t)),
                                    const SizedBox(width: 4),
                                    Text('支払済み',
                                        style: camillBodyStyle(
                                            13, Color.lerp(colors.textMuted, Colors.white, t)!,
                                            weight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          }),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                final opacity = (_anim.value * 2 - 1).clamp(0.0, 1.0);
                if (opacity <= 0) return const SizedBox(width: double.infinity);
                return Opacity(
                  opacity: opacity,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 12, color: colors.textMuted),
                        const SizedBox(width: 4),
                        Text('印鑑・支払済みスタンプを検出しました',
                            style: camillBodyStyle(11, colors.textMuted)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
