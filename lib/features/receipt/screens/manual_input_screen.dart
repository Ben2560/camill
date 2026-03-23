import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/receipt_model.dart';

class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({super.key});

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeCtrl = TextEditingController();
  DateTime _purchasedAt = DateTime.now();
  String _paymentMethod = 'cash';
  String? _receiptCategory;

  final List<_ItemEntry> _items = [_ItemEntry()];

  @override
  void dispose() {
    _storeCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchasedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _purchasedAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _purchasedAt.hour,
          _purchasedAt.minute,
        );
      });
    }
  }

  void _addItem() {
    setState(() => _items.add(_ItemEntry()));
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final items = _items.map((e) {
      final amount = int.tryParse(e.priceCtrl.text.replaceAll(',', '')) ?? 0;
      return ReceiptItem(
        itemName: e.nameCtrl.text,
        itemNameRaw: e.nameCtrl.text,
        category: e.category,
        unitPrice: amount,
        quantity: 1,
        amount: amount,
      );
    }).toList();

    final total = items.fold(0, (s, i) => s + i.amount);
    final analysis = ReceiptAnalysis(
      storeName: _storeCtrl.text,
      purchasedAt: _purchasedAt.toIso8601String(),
      totalAmount: total,
      paymentMethod: _paymentMethod,
      category: _receiptCategory,
      items: items,
      couponsDetected: [],
      duplicateCheckHash: '',
    );

    context.push('/receipt-preview', extra: analysis);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFmt = DateFormat('yyyy年M月d日 HH:mm');

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text('手動入力', style: camillHeadingStyle(17, colors.textPrimary)),
        iconTheme: IconThemeData(color: colors.textSecondary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 店名
            TextFormField(
              controller: _storeCtrl,
              decoration: InputDecoration(
                labelText: '店名',
                prefixIcon: Icon(Icons.store_outlined, color: colors.textMuted),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? '店名を入力してください' : null,
            ),
            const SizedBox(height: 16),
            // 日時
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: '購入日時',
                  prefixIcon: Icon(Icons.calendar_today_outlined,
                      color: colors.textMuted),
                  suffixIcon:
                      Icon(Icons.chevron_right, color: colors.textMuted),
                ),
                child: Text(dateFmt.format(_purchasedAt),
                    style: camillBodyStyle(14, colors.textPrimary)),
              ),
            ),
            const SizedBox(height: 16),
            // 支払方法
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: InputDecoration(
                labelText: '支払方法',
                prefixIcon: Icon(Icons.payment_outlined, color: colors.textMuted),
              ),
              items: AppConstants.paymentLabels.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            const SizedBox(height: 16),
            // レシートカテゴリ
            DropdownButtonFormField<String>(
              initialValue: _receiptCategory,
              decoration: InputDecoration(
                labelText: 'レシートカテゴリ',
                prefixIcon: Icon(Icons.label_outline, color: colors.textMuted),
              ),
              hint: const Text('自動（品目から判定）'),
              items: AppConstants.categoryLabels.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _receiptCategory = v),
            ),
            const SizedBox(height: 24),
            // 品目ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('品目',
                    style: camillBodyStyle(15, colors.textPrimary,
                        weight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: Icon(Icons.add, size: 18, color: colors.primary),
                  label: Text('追加', style: camillBodyStyle(14, colors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 品目リスト
            ...List.generate(
                _items.length,
                (i) => _ItemRow(
                      entry: _items[i],
                      index: i,
                      canRemove: _items.length > 1,
                      onRemove: () => _removeItem(i),
                      onChanged: () => setState(() {}),
                    )),
            const SizedBox(height: 12),
            // 合計
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('合計',
                      style: camillBodyStyle(14, colors.textPrimary,
                          weight: FontWeight.bold)),
                  Text(
                    NumberFormat.currency(locale: 'ja_JP', symbol: '¥').format(
                      _items.fold(
                        0,
                        (s, e) =>
                            s +
                            (int.tryParse(
                                    e.priceCtrl.text.replaceAll(',', '')) ??
                                0),
                      ),
                    ),
                    style: camillAmountStyle(18, colors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.fabIcon,
              ),
              onPressed: _submit,
              child: Text('確認画面へ', style: camillBodyStyle(16, colors.fabIcon)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ItemEntry {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  String category = 'food';

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _ItemRow extends StatelessWidget {
  final _ItemEntry entry;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ItemRow({
    required this.entry,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
        child: Column(
          children: [
            Row(
              children: [
                Text('品目 ${index + 1}',
                    style: camillBodyStyle(12, colors.textMuted)),
                const Spacer(),
                if (canRemove)
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: colors.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: entry.nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '商品名',
                      isDense: true,
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? '商品名を入力' : null,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: entry.priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '金額',
                      prefixText: '¥',
                      isDense: true,
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? '金額を入力' : null,
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: entry.category,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'カテゴリ',
                isDense: true,
              ),
              items: AppConstants.categoryLabels.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value,
                            style: const TextStyle(fontSize: 14)),
                      ))
                  .toList(),
              onChanged: (v) {
                entry.category = v!;
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
