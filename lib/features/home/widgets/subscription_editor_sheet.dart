import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/services/api_service.dart';

// ─────────────────────────────────────────────────────────
// サブスク一覧エディターシート
// ─────────────────────────────────────────────────────────
class SubscriptionEditorSheet extends StatefulWidget {
  final List<Map<String, dynamic>> initialSubs;
  final int initialBudget;
  final CamillColors colors;
  final ApiService api;

  const SubscriptionEditorSheet({
    super.key,
    required this.initialSubs,
    required this.initialBudget,
    required this.colors,
    required this.api,
  });

  @override
  State<SubscriptionEditorSheet> createState() =>
      SubscriptionEditorSheetState();
}

class SubscriptionEditorSheetState extends State<SubscriptionEditorSheet> {
  final _fmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
  // confirmed subs from API: {id, store_name, amount}
  late List<Map<String, dynamic>> _subs;
  // pending deletes (ids)
  final Set<String> _pendingDeletes = {};
  // new items being added locally
  final List<({TextEditingController name, TextEditingController amount})>
  _newItems = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _subs = List.from(widget.initialSubs);
    _addNewRow();
  }

  @override
  void dispose() {
    for (final item in _newItems) {
      item.name.dispose();
      item.amount.dispose();
    }
    super.dispose();
  }

  void _addNewRow() {
    _newItems.add((
      name: TextEditingController(),
      amount: TextEditingController(),
    ));
  }

  void _onItemChanged() {
    setState(() {});
    final last = _newItems.last;
    if (last.name.text.trim().isNotEmpty &&
        last.amount.text.trim().isNotEmpty) {
      setState(() => _addNewRow());
    }
  }

  void _removeNewRow(int index) {
    final item = _newItems.removeAt(index);
    item.name.dispose();
    item.amount.dispose();
    if (_newItems.isEmpty) _addNewRow();
    setState(() {});
  }

  int get _total {
    final existingSum = _subs
        .where(
          (s) => !_pendingDeletes.contains(s['subscription_id']?.toString()),
        )
        .fold(0, (sum, s) => sum + ((s['amount'] as num?)?.toInt() ?? 0));
    final newSum = _newItems.fold(0, (sum, item) {
      return sum + (int.tryParse(item.amount.text) ?? 0);
    });
    return existingSum + newSum;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // 削除
      for (final id in _pendingDeletes) {
        try {
          await widget.api.delete('/subscriptions/$id');
        } catch (_) {}
      }
      // 新規追加
      for (final item in _newItems) {
        final name = item.name.text.trim();
        final amt = int.tryParse(item.amount.text) ?? 0;
        if (name.isEmpty || amt <= 0) continue;
        try {
          await widget.api.postAny(
            '/subscriptions/manual',
            body: {'service_name': name, 'monthly_amount': amt},
          );
        } catch (_) {}
      }
      if (mounted) Navigator.pop(context, _total);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final sh = MediaQuery.of(context).size.height;
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final visibleSubs = _subs
        .where(
          (s) => !_pendingDeletes.contains(s['subscription_id']?.toString()),
        )
        .toList();

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardBottom),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: sh * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ドラッグハンドル
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ヘッダー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.subscriptions_outlined,
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'サブスク',
                        style: camillBodyStyle(
                          20,
                          colors.textPrimary,
                          weight: FontWeight.w700,
                        ),
                      ),
                      Text('固定費', style: camillBodyStyle(12, colors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // リスト
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // 既存サブスク
                  ...visibleSubs.map((s) {
                    final id = s['subscription_id']?.toString() ?? '';
                    final name = s['store_name'] as String? ?? '';
                    final amount = (s['amount'] as num?)?.toInt() ?? 0;
                    return SubRow(
                      name: name,
                      amount: _fmt.format(amount),
                      colors: colors,
                      onDelete: () => setState(() => _pendingDeletes.add(id)),
                    );
                  }),
                  // 新規入力行
                  ..._newItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final radius = BorderRadius.circular(10);
                    final enabledBorder = OutlineInputBorder(
                      borderRadius: radius,
                      borderSide: BorderSide(color: colors.surfaceBorder),
                    );
                    final focusedBorder = OutlineInputBorder(
                      borderRadius: radius,
                      borderSide: BorderSide(color: colors.primary, width: 1.5),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: item.name,
                              style: camillBodyStyle(14, colors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'サービス名',
                                hintStyle: camillBodyStyle(
                                  14,
                                  colors.textMuted,
                                ),
                                enabledBorder: enabledBorder,
                                focusedBorder: focusedBorder,
                                filled: true,
                                fillColor: colors.surface,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (_) => _onItemChanged(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: item.amount,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: false,
                                    decimal: false,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: camillBodyStyle(
                                14,
                                colors.primary,
                                weight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: '月額',
                                hintStyle: camillBodyStyle(
                                  14,
                                  colors.textMuted,
                                ),
                                prefixText: '¥',
                                prefixStyle: camillBodyStyle(
                                  14,
                                  colors.textMuted,
                                ),
                                enabledBorder: enabledBorder,
                                focusedBorder: focusedBorder,
                                filled: true,
                                fillColor: colors.surface,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (_) => _onItemChanged(),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _removeNewRow(i),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: colors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            // 合計バー
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.surfaceBorder),
              ),
              child: Row(
                children: [
                  Text('合計 / 月', style: camillBodyStyle(13, colors.textMuted)),
                  const Spacer(),
                  Text(
                    _fmt.format(_total),
                    style: camillBodyStyle(
                      20,
                      colors.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // 設定するボタン
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, safeBottom + 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    '設定する',
                    style: camillBodyStyle(
                      16,
                      Colors.white,
                      weight: FontWeight.w600,
                    ),
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

class SubRow extends StatelessWidget {
  final String name;
  final String amount;
  final CamillColors colors;
  final VoidCallback onDelete;

  const SubRow({
    super.key,
    required this.name,
    required this.amount,
    required this.colors,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.surfaceBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: camillBodyStyle(
                  14,
                  colors.textPrimary,
                  weight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              amount,
              style: camillBodyStyle(
                14,
                colors.primary,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.delete_outline,
                size: 18,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HolidayRulePill extends StatelessWidget {
  final String label;
  final bool selected;
  final CamillColors colors;
  final VoidCallback onTap;

  const HolidayRulePill({
    super.key,
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colors.primary : colors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: camillBodyStyle(
            12,
            selected ? Colors.white : colors.textMuted,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
