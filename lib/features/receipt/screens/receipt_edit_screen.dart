import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/summary_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/loading_overlay.dart';

class ReceiptEditScreen extends StatefulWidget {
  final ReceiptListItem receipt;
  final bool focusMemo;
  const ReceiptEditScreen({super.key, required this.receipt, this.focusMemo = false});

  @override
  State<ReceiptEditScreen> createState() => _ReceiptEditScreenState();
}

class _ReceiptEditScreenState extends State<ReceiptEditScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();
  final _memoFocusNode = FocusNode();
  late final TextEditingController _storeCtrl;
  late final TextEditingController _memoCtrl;
  late DateTime _purchasedAt;
  late String _paymentMethod;
  late String _receiptCategory;
  late List<_ItemEntry> _items;
  bool _saving = false;
  int _memoMinLines = 6;

  @override
  void initState() {
    super.initState();
    final r = widget.receipt;
    _storeCtrl = TextEditingController(text: r.storeName);
    _memoCtrl = TextEditingController(text: r.memo ?? '');
    _purchasedAt = DateTime.tryParse(r.purchasedAt) ?? DateTime.now();
    _paymentMethod = r.paymentMethod;
    _receiptCategory = r.category;
    _items = r.items.isEmpty
        ? [_ItemEntry()]
        : r.items
            .map((i) => _ItemEntry.fromReceiptItem(i))
            .toList();
    _memoCtrl.addListener(_onMemoChanged);
    _memoFocusNode.addListener(_onMemoFocus);
    // 既存メモがある場合は行数を反映
    _onMemoChanged();
    if (widget.focusMemo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _memoFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _memoFocusNode.removeListener(_onMemoFocus);
    _memoFocusNode.dispose();
    _storeCtrl.dispose();
    _memoCtrl.removeListener(_onMemoChanged);
    _memoCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _onMemoFocus() {
    if (!_memoFocusNode.hasFocus) return;
    // キーボードアニメーション完了後に末尾までスクロールしてメモ欄を表示
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || !_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _onMemoChanged() {
    final lineCount = _memoCtrl.text.isEmpty ? 0 : _memoCtrl.text.split('\n').length;
    final needed = (lineCount + 1).clamp(6, 9999);
    if (needed > _memoMinLines) {
      setState(() => _memoMinLines = needed);
    }
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

  void _addItem() => setState(() => _items.add(_ItemEntry()));

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final items = _items.map((e) {
        final amt = int.tryParse(e.priceCtrl.text.replaceAll(',', '')) ?? 0;
        return {
          'item_name': e.nameCtrl.text,
          'item_name_raw': e.nameCtrl.text,
          'category': e.category,
          'unit_price': amt,
          'quantity': 1,
          'amount': amt,
        };
      }).toList();

      await _api.patch('/receipts/${widget.receipt.receiptId}', body: {
        'store_name': _storeCtrl.text,
        'purchased_at': _purchasedAt.toIso8601String(),
        'payment_method': _paymentMethod,
        'category': _receiptCategory,
        'items': items,
        'memo': _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // silently swallow
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFmt = DateFormat('yyyy年M月d日 HH:mm');

    return LoadingOverlay(
      isLoading: _saving,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          title: Text('レシートを編集', style: camillHeadingStyle(17, colors.textPrimary)),
          iconTheme: IconThemeData(color: colors.textSecondary),
          actions: [
            TextButton(
              onPressed: _save,
              child: Text('保存する',
                  style: camillBodyStyle(15, colors.primary,
                      weight: FontWeight.bold)),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(16),
            children: [
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
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '購入日時',
                    prefixIcon: Icon(Icons.calendar_today_outlined,
                        color: colors.textMuted),
                    suffixIcon: Icon(Icons.chevron_right, color: colors.textMuted),
                  ),
                  child: Text(dateFmt.format(_purchasedAt),
                      style: camillBodyStyle(14, colors.textPrimary)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: InputDecoration(
                  labelText: '支払方法',
                  prefixIcon:
                      Icon(Icons.payment_outlined, color: colors.textMuted),
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
              DropdownButtonFormField<String>(
                initialValue: _receiptCategory,
                decoration: InputDecoration(
                  labelText: 'レシートカテゴリ',
                  prefixIcon: Icon(Icons.label_outline, color: colors.textMuted),
                ),
                items: AppConstants.categoryLabels.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _receiptCategory = v!),
              ),
              const SizedBox(height: 24),
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
              ...List.generate(
                _items.length,
                (i) => _ItemRow(
                  entry: _items[i],
                  index: i,
                  canRemove: _items.length > 1,
                  onRemove: () => _removeItem(i),
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 16),
              // ── メモ ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notes_outlined, size: 15, color: colors.textMuted),
                        const SizedBox(width: 6),
                        Text('メモ', style: camillBodyStyle(13, colors.textMuted, weight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _memoCtrl,
                      focusNode: _memoFocusNode,
                      minLines: _memoMinLines,
                      maxLines: null,
                      style: camillBodyStyle(14, colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'メモを入力...',
                        hintStyle: camillBodyStyle(14, colors.textMuted),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemEntry {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  String category;

  _ItemEntry({this.category = 'food'});

  factory _ItemEntry.fromReceiptItem(ReceiptItem item) {
    final e = _ItemEntry(category: item.category);
    e.nameCtrl.text = item.itemName;
    e.priceCtrl.text = item.amount.toString();
    return e;
  }

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
                    decoration:
                        const InputDecoration(labelText: '商品名', isDense: true),
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
                        labelText: '金額', prefixText: '¥', isDense: true),
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
              decoration:
                  const InputDecoration(labelText: 'カテゴリ', isDense: true),
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
