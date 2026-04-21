import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/camill_colors.dart';
import '../../core/theme/camill_theme.dart';

/// 月の予算設定ボトムシート。
/// TextEditingController を StatefulWidget 内で管理し、
/// 閉じるアニメーション中に dispose されるクラッシュを防ぐ。
class BudgetSheet extends StatefulWidget {
  final int initialBudget;
  final int categoryTotal;
  final CamillColors colors;
  final Future<void> Function(int) onSave;

  const BudgetSheet({
    super.key,
    required this.initialBudget,
    this.categoryTotal = 0,
    required this.colors,
    required this.onSave,
  });

  @override
  State<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<BudgetSheet> {
  late final TextEditingController _controller;
  final _fmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialBudget.toString());
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final catTotal = widget.categoryTotal;
    final inputVal = int.tryParse(_controller.text) ?? 0;
    final diff = inputVal - catTotal;
    final hasCatTotal = catTotal > 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textMuted.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('月の予算を設定', style: camillHeadingStyle(16, colors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: camillAmountStyle(24, colors.textPrimary),
              decoration: InputDecoration(
                prefixText: '¥',
                prefixStyle: camillAmountStyle(24, colors.textMuted),
                hintText: '80,000',
                hintStyle: camillAmountStyle(24, colors.textMuted),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.surfaceBorder),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
              ),
            ),
            if (hasCatTotal) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Text(
                      'カテゴリ合計',
                      style: camillBodyStyle(13, colors.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _fmt.format(catTotal),
                      style: camillBodyStyle(
                        13,
                        colors.textSecondary,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    _DiffBadge(diff: diff, fmt: _fmt, colors: colors),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saving
                    ? null
                    : () async {
                        final val = int.tryParse(_controller.text);
                        if (val == null || val <= 0) return;
                        setState(() => _saving = true);
                        final nav = Navigator.of(context);
                        await widget.onSave(val);
                        if (!mounted) return;
                        nav.pop();
                      },
                child: Text(
                  '保存',
                  style: camillBodyStyle(
                    15,
                    colors.fabIcon,
                    weight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiffBadge extends StatelessWidget {
  final int diff;
  final NumberFormat fmt;
  final CamillColors colors;

  const _DiffBadge({
    required this.diff,
    required this.fmt,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isZero = diff == 0;
    final isOver = diff < 0;
    final color = isZero
        ? colors.success
        : isOver
        ? colors.danger
        : colors.primary;
    final label = isZero
        ? '±¥0'
        : isOver
        ? '-${fmt.format(diff.abs())}'
        : '+${fmt.format(diff)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: camillBodyStyle(12, color, weight: FontWeight.w700),
      ),
    );
  }
}
