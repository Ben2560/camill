import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/overseas_service.dart';
import 'receipt_edit_screen.dart'
    show showCategoryBottomSheet, showPaymentBottomSheet;

class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({super.key});

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeCtrl = TextEditingController();
  final _billAmountCtrl = TextEditingController();
  final _medicalAmountCtrl = TextEditingController();
  DateTime _purchasedAt = DateTime.now();
  DateTime? _billDueDate;
  String _paymentMethod = 'cash';
  String? _receiptCategory;
  String _billCategory = 'utility';
  String _docType = 'receipt'; // receipt | medical | bill
  int _burdenRate = 3; // 1割・2割・3割
  bool _isUncovered = false; // 保険適応外（自由診療）

  final List<_ItemEntry> _items = [_ItemEntry()];

  // 外貨対応
  bool _isOverseas = false;
  String _currency = 'JPY';
  double _exchangeRate = 1.0; // 1外貨単位 = X円
  late final _overseasService = OverseasService(ApiService());

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final isOverseas = await _overseasService.getIsOverseas();
    if (!mounted) {
      return;
    }
    if (!isOverseas) {
      setState(() => _isOverseas = false);
      return;
    }
    final currency = await _overseasService.getCurrentCurrency();
    final data = await _overseasService.fetchRates();
    final rates = data['rates'] as Map<String, dynamic>? ?? {};
    final rateEntry = rates[currency] as Map<String, dynamic>?;
    final rate = (rateEntry?['rate'] as num?)?.toDouble() ?? 1.0;
    if (mounted) {
      setState(() {
        _isOverseas = true;
        _currency = currency == 'JPY' ? 'JPY' : currency;
        _exchangeRate = currency == 'JPY' ? 1.0 : rate;
      });
    }
  }

  @override
  void dispose() {
    _storeCtrl.dispose();
    _billAmountCtrl.dispose();
    _medicalAmountCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPayment() async {
    final result = await showPaymentBottomSheet(context, _paymentMethod);
    if (result != null) setState(() => _paymentMethod = result);
  }

  Future<void> _pickCategory() async {
    final result = await showCategoryBottomSheet(
      context,
      _receiptCategory ?? 'food',
    );
    if (result != null) setState(() => _receiptCategory = result);
  }

  Future<void> _pickBillCategory() async {
    const billCategories = [
      'utility',
      'subscription',
      'transport',
      'medical',
      'education',
      'other',
    ];
    final result = await showCategoryBottomSheet(
      context,
      _billCategory,
      allowedCategories: billCategories,
    );
    if (result != null) setState(() => _billCategory = result);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchasedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _billDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _billDueDate = picked);
  }

  bool get _hasAnyItemPoints =>
      _items.any((e) => (int.tryParse(e.priceCtrl.text) ?? 0) > 0);

  int _calcMedicalTotal(List<ReceiptItem> items) {
    if (!_hasAnyItemPoints) {
      return int.tryParse(_medicalAmountCtrl.text.replaceAll(',', '')) ?? 0;
    }
    final totalPoints = items.fold(0, (s, i) => s + i.amount);
    if (_isUncovered) return totalPoints;
    return ((totalPoints * 10 * _burdenRate) / 10.0 / 10).round() * 10;
  }

  void _addItem() => setState(() => _items.add(_ItemEntry()));

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final ReceiptAnalysis analysis;

    if (_docType == 'bill') {
      final amount =
          int.tryParse(_billAmountCtrl.text.replaceAll(',', '')) ?? 0;
      analysis = ReceiptAnalysis(
        storeName: _storeCtrl.text,
        purchasedAt: _purchasedAt.toIso8601String(),
        totalAmount: amount,
        paymentMethod: _paymentMethod,
        category: _billCategory,
        items: [],
        couponsDetected: [],
        duplicateCheckHash: '',
        isBill: true,
        billDueDate: _billDueDate,
        billStatus: 'unpaid',
      );
    } else {
      final items = _items.map((e) {
        final amount = int.tryParse(e.priceCtrl.text.replaceAll(',', '')) ?? 0;
        final cat = _docType == 'medical' ? 'medical' : e.category;
        return ReceiptItem(
          itemName: e.nameCtrl.text,
          itemNameRaw: e.nameCtrl.text,
          category: cat,
          unitPrice: amount,
          quantity: 1,
          amount: amount,
        );
      }).toList();

      final rawTotal = _docType == 'medical'
          ? _calcMedicalTotal(items)
          : items.fold(0, (s, i) => s + i.amount);
      final total = _currency != 'JPY'
          ? (rawTotal * _exchangeRate).round()
          : rawTotal;
      analysis = ReceiptAnalysis(
        storeName: _storeCtrl.text,
        purchasedAt: _purchasedAt.toIso8601String(),
        totalAmount: total,
        paymentMethod: _paymentMethod,
        category: _docType == 'medical' ? 'medical' : _receiptCategory,
        items: items,
        couponsDetected: [],
        duplicateCheckHash: '',
        isMedical: _docType == 'medical',
        isUncovered: _docType == 'medical' && _isUncovered,
      );
    }

    context.push(
      '/receipt-preview',
      extra: (analyses: [analysis], maxReceipts: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFmt = DateFormat('yyyy年M月d日');

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        scrolledUnderElevation: 0,
        title: Text('手動入力', style: camillHeadingStyle(17, colors.textPrimary)),
        iconTheme: IconThemeData(color: colors.textSecondary),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── タイプセレクター ──
              _DocTypeSelector(
                selected: _docType,
                onChanged: (t) => setState(() => _docType = t),
                colors: colors,
              ),
              const SizedBox(height: 20),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  alignment: Alignment.topCenter,
                  children: <Widget>[...previousChildren, ?currentChild],
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _buildFormFields(colors, dateFmt),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalSummary(CamillColors colors) {
    final fmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    final totalPoints = _items.fold(
      0,
      (s, e) => s + (int.tryParse(e.priceCtrl.text) ?? 0),
    );

    // 保険適応外：合計金額をそのまま表示
    if (_isUncovered) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.danger.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.danger.withAlpha(60)),
        ),
        child: _SummaryRow(
          label: '請求金額（保険外）',
          value: fmt.format(totalPoints),
          colors: colors,
          highlight: true,
          highlightColor: colors.danger,
        ),
      );
    }

    final fullAmount = totalPoints * 10;
    final selfPay = (fullAmount * _burdenRate / 10.0 / 10).round() * 10;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withAlpha(40)),
      ),
      child: Column(
        children: [
          _SummaryRow(label: '合計点数', value: '$totalPoints 点', colors: colors),
          const SizedBox(height: 8),
          Divider(height: 1, color: colors.primary.withAlpha(30)),
          const SizedBox(height: 8),
          _SummaryRow(
            label: '10割分',
            value: fmt.format(fullAmount),
            colors: colors,
            muted: true,
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: '自己負担額（$_burdenRate割）',
            value: fmt.format(selfPay),
            colors: colors,
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalSummaryManual(CamillColors colors) {
    final fmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    final amount =
        int.tryParse(_medicalAmountCtrl.text.replaceAll(',', '')) ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withAlpha(40)),
      ),
      child: _SummaryRow(
        label: '自己負担額',
        value: fmt.format(amount),
        colors: colors,
        highlight: true,
      ),
    );
  }

  Widget _buildFormFields(CamillColors colors, DateFormat dateFmt) {
    return Column(
      key: ValueKey(_docType),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 店名 / 病院名 / 発行元 ──
        TextFormField(
          controller: _storeCtrl,
          decoration: InputDecoration(
            labelText: switch (_docType) {
              'medical' => '病院・クリニック名',
              'bill' => '発行元（会社・機関名）',
              _ => '店名',
            },
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: switch (_docType) {
              'medical' => 'クリニック名を入力してください',
              'bill' => '例：東京電力、NHK',
              _ => '例：スーパー、コンビニ',
            },
            hintStyle: TextStyle(
              color: colors.textMuted,
              fontWeight: FontWeight.w300,
            ),
            prefixIcon: Icon(switch (_docType) {
              'medical' => Icons.local_hospital_outlined,
              'bill' => Icons.business_outlined,
              _ => Icons.store_outlined,
            }, color: colors.textMuted),
          ),
          validator: (v) => (v == null || v.isEmpty) ? '入力してください' : null,
        ),

        // 通貨セレクター（レシートかつ海外モード時のみ表示）
        if (_docType == 'receipt' && _isOverseas) ...[
          const SizedBox(height: 12),
          _CurrencySelector(
            currency: _currency,
            exchangeRate: _exchangeRate,
            colors: colors,
            onChanged: (code, rate) => setState(() {
              _currency = code;
              _exchangeRate = rate;
            }),
            overseasService: _overseasService,
          ),
        ],

        // 保険適応外トグル（医療明細のみ）
        if (_docType == 'medical') ...[
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => _isUncovered = !_isUncovered),
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '保険適応外（自由診療）',
                labelStyle: TextStyle(
                  color: _isUncovered ? colors.danger : null,
                ),
                prefixIcon: Icon(
                  Icons.money_off_outlined,
                  color: _isUncovered ? colors.danger : colors.textMuted,
                ),
                suffixIcon: Switch(
                  value: _isUncovered,
                  onChanged: (v) => setState(() => _isUncovered = v),
                  activeThumbColor: colors.danger,
                  activeTrackColor: colors.danger.withAlpha(100),
                ),
              ),
              child: Text(
                '美容・矯正・健診など保険が使えない診療',
                style: camillBodyStyle(13, colors.textMuted),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // ── 日付 ──
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: switch (_docType) {
                'medical' => '受診日',
                'bill' => '請求日',
                _ => '購入日',
              },
              prefixIcon: Icon(
                Icons.calendar_today_outlined,
                color: colors.textMuted,
              ),
              suffixIcon: Icon(Icons.chevron_right, color: colors.textMuted),
            ),
            child: Text(
              dateFmt.format(_purchasedAt),
              style: camillBodyStyle(14, colors.textPrimary),
            ),
          ),
        ),

        // ── 請求書専用フィールド ──
        if (_docType == 'bill') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _billAmountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '請求金額',
              prefixText: '¥ ',
            ),
            validator: (v) => (v == null || v.isEmpty) ? '金額を入力してください' : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickBillCategory,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'カテゴリ',
                prefixIcon: Icon(Icons.label_outline, color: colors.textMuted),
                suffixIcon: Icon(Icons.chevron_right, color: colors.textMuted),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color:
                          AppConstants.categoryColors[_billCategory] ??
                          colors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppConstants.categoryLabels[_billCategory] ?? _billCategory,
                    style: camillBodyStyle(14, colors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDueDate,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '支払期限（任意）',
                prefixIcon: Icon(Icons.event_outlined, color: colors.textMuted),
                suffixIcon: _billDueDate != null
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 18,
                          color: colors.textMuted,
                        ),
                        onPressed: () => setState(() => _billDueDate = null),
                      )
                    : Icon(Icons.chevron_right, color: colors.textMuted),
              ),
              child: Text(
                _billDueDate != null ? dateFmt.format(_billDueDate!) : '未設定',
                style: camillBodyStyle(
                  14,
                  _billDueDate != null ? colors.textPrimary : colors.textMuted,
                ),
              ),
            ),
          ),
        ],

        // ── 通常・医療専用フィールド ──
        if (_docType != 'bill') ...[
          const SizedBox(height: 16),
          // 支払方法
          InkWell(
            onTap: _pickPayment,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '支払方法',
                prefixIcon: Icon(
                  Icons.payment_outlined,
                  color: colors.textMuted,
                ),
                suffixIcon: Icon(Icons.chevron_right, color: colors.textMuted),
              ),
              child: Text(
                AppConstants.paymentLabels[_paymentMethod] ?? _paymentMethod,
                style: camillBodyStyle(14, colors.textPrimary),
              ),
            ),
          ),

          // カテゴリ（通常のみ。医療は medical 固定）
          if (_docType == 'receipt') ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickCategory,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'レシートカテゴリ',
                  prefixIcon: Icon(
                    Icons.label_outline,
                    color: colors.textMuted,
                  ),
                  suffixIcon: Icon(
                    Icons.chevron_right,
                    color: colors.textMuted,
                  ),
                ),
                child: _receiptCategory == null
                    ? Text(
                        '自動で品目から判定します',
                        style: camillBodyStyle(14, colors.textMuted),
                      )
                    : Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color:
                                  AppConstants
                                      .categoryColors[_receiptCategory] ??
                                  colors.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppConstants.categoryLabels[_receiptCategory] ??
                                _receiptCategory!,
                            style: camillBodyStyle(14, colors.textPrimary),
                          ),
                        ],
                      ),
              ),
            ),
          ],

          // 医療明細専用：自己負担額（診療項目入力時は自動計算で非表示）
          if (_docType == 'medical') ...[
            const SizedBox(height: 16),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              firstCurve: Curves.easeOutCubic,
              secondCurve: Curves.easeInCubic,
              sizeCurve: Curves.easeInOut,
              crossFadeState: _hasAnyItemPoints
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: TextFormField(
                  controller: _medicalAmountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '自己負担額',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintText: '支払い金額',
                    hintStyle: TextStyle(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w300,
                    ),
                    prefixText: '¥ ',
                  ),
                  validator: (_hasAnyItemPoints)
                      ? null
                      : (v) =>
                            (v == null || v.isEmpty) ? '自己負担額を入力してください' : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],

          const SizedBox(height: 24),
          // 品目ヘッダー
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _docType == 'medical' ? '診療項目' : '品目',
                style: camillBodyStyle(
                  15,
                  colors.textPrimary,
                  weight: FontWeight.bold,
                ),
              ),
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
              showCategory: _docType == 'receipt',
              itemLabel: _docType == 'medical' ? '診療内容' : '商品名',
              isPointsMode: _docType == 'medical' && !_isUncovered,
              nameRequired: _docType != 'medical',
            ),
          ),
          const SizedBox(height: 12),
          // 合計 / 請求金額サマリー
          if (_docType == 'medical' && _hasAnyItemPoints && !_isUncovered) ...[
            // 負担割合セレクター
            Row(
              children: [
                Text('負担割合', style: camillBodyStyle(13, colors.textMuted)),
                const SizedBox(width: 12),
                ...([1, 2, 3].map((r) {
                  final selected = _burdenRate == r;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _burdenRate = r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? colors.primary : colors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? colors.primary
                                : colors.surfaceBorder,
                          ),
                        ),
                        child: Text(
                          '$r割',
                          style: camillBodyStyle(
                            13,
                            selected ? colors.fabIcon : colors.textSecondary,
                            weight: selected
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                })),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (_docType == 'medical')
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _hasAnyItemPoints
                  ? _buildMedicalSummary(colors)
                  : _buildMedicalSummaryManual(colors),
              // _isUncovered時は _buildMedicalSummary 内でそのまま合計表示
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '合計',
                    style: camillBodyStyle(
                      14,
                      colors.textPrimary,
                      weight: FontWeight.bold,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(() {
                        final total = _items.fold(
                          0,
                          (s, e) =>
                              s +
                              (int.tryParse(
                                    e.priceCtrl.text.replaceAll(',', ''),
                                  ) ??
                                  0),
                        );
                        if (_currency == 'JPY') {
                          return NumberFormat.currency(
                            locale: 'ja_JP',
                            symbol: '¥',
                          ).format(total);
                        }
                        return '$total $_currency';
                      }(), style: camillAmountStyle(18, colors.primary)),
                      if (_currency != 'JPY') ...[
                        const SizedBox(height: 2),
                        Text(
                          '≈ ${NumberFormat.currency(locale: 'ja_JP', symbol: '¥').format((_items.fold(0, (s, e) => s + (int.tryParse(e.priceCtrl.text.replaceAll(',', '')) ?? 0)) * _exchangeRate).round())}',
                          style: camillBodyStyle(12, colors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
        ],

        // 請求書の場合の合計表示
        if (_docType == 'bill' && _billAmountCtrl.text.isNotEmpty) ...[
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
                Text(
                  '請求金額',
                  style: camillBodyStyle(
                    14,
                    colors.textPrimary,
                    weight: FontWeight.bold,
                  ),
                ),
                Text(
                  NumberFormat.currency(locale: 'ja_JP', symbol: '¥').format(
                    int.tryParse(_billAmountCtrl.text.replaceAll(',', '')) ?? 0,
                  ),
                  style: camillAmountStyle(18, colors.primary),
                ),
              ],
            ),
          ),
        ],

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
    );
  }
}

// ────────────────────────────────────────────
// 通貨セレクター
// ────────────────────────────────────────────

class _CurrencySelector extends StatefulWidget {
  final String currency;
  final double exchangeRate;
  final CamillColors colors;
  final void Function(String code, double rate) onChanged;
  final OverseasService overseasService;

  const _CurrencySelector({
    required this.currency,
    required this.exchangeRate,
    required this.colors,
    required this.onChanged,
    required this.overseasService,
  });

  @override
  State<_CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<_CurrencySelector> {
  Map<String, dynamic> _rates = {};

  @override
  void initState() {
    super.initState();
    widget.overseasService.fetchRates().then((data) {
      if (mounted) {
        setState(() => _rates = data['rates'] as Map<String, dynamic>? ?? {});
      }
    });
  }

  Future<void> _showPicker() async {
    final entries = _rates.entries.toList();
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(
              'JPY（日本円）',
              style: camillBodyStyle(14, widget.colors.textPrimary),
            ),
            trailing: widget.currency == 'JPY'
                ? Icon(Icons.check, color: widget.colors.primary)
                : null,
            onTap: () => Navigator.pop(ctx, 'JPY'),
          ),
          const Divider(height: 1),
          ...entries.map((e) {
            final entry = e.value as Map<String, dynamic>;
            final label = entry['label'] as String? ?? e.key;
            final rate = (entry['rate'] as num?)?.toDouble() ?? 1.0;
            return ListTile(
              title: Text(
                '${e.key}（$label）',
                style: camillBodyStyle(14, widget.colors.textPrimary),
              ),
              subtitle: Text(
                '1 ${e.key} ≈ ¥${rate.toStringAsFixed(rate < 1 ? 4 : 2)}',
                style: camillBodyStyle(12, widget.colors.textMuted),
              ),
              trailing: widget.currency == e.key
                  ? Icon(Icons.check, color: widget.colors.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, e.key),
            );
          }),
        ],
      ),
    );
    if (picked == null) return;
    if (picked == 'JPY') {
      widget.onChanged('JPY', 1.0);
    } else {
      final entry = _rates[picked] as Map<String, dynamic>?;
      final rate = (entry?['rate'] as num?)?.toDouble() ?? 1.0;
      widget.onChanged(picked, rate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isJpy = widget.currency == 'JPY';
    return GestureDetector(
      onTap: _showPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isJpy
              ? widget.colors.surface
              : widget.colors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isJpy
                ? widget.colors.surfaceBorder
                : widget.colors.primary.withAlpha(80),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.currency_exchange,
              size: 16,
              color: isJpy ? widget.colors.textMuted : widget.colors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              isJpy
                  ? '通貨: JPY（日本円）'
                  : '通貨: ${widget.currency}  1${widget.currency} ≈ ¥${widget.exchangeRate.toStringAsFixed(widget.exchangeRate < 1 ? 4 : 2)}',
              style: camillBodyStyle(
                13,
                isJpy ? widget.colors.textMuted : widget.colors.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              size: 16,
              color: isJpy ? widget.colors.textMuted : widget.colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────
// ドキュメントタイプセレクター
// ────────────────────────────────────────────

class _DocTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final CamillColors colors;

  const _DocTypeSelector({
    required this.selected,
    required this.onChanged,
    required this.colors,
  });

  static const _types = [
    (key: 'receipt', label: 'レシート', icon: Icons.receipt_long),
    (key: 'medical', label: '医療明細', icon: Icons.medical_information_outlined),
    (key: 'bill', label: '請求書', icon: Icons.description_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Row(
        children: _types.map((t) {
          final isSelected = t.key == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(t.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.icon,
                      size: 20,
                      color: isSelected ? colors.fabIcon : colors.textMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.label,
                      style: camillBodyStyle(
                        12,
                        isSelected ? colors.fabIcon : colors.textMuted,
                        weight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ────────────────────────────────────────────
// ItemEntry / ItemRow
// ────────────────────────────────────────────

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
  final bool showCategory;
  final String itemLabel;
  final bool isPointsMode;
  final bool nameRequired;

  const _ItemRow({
    required this.entry,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
    required this.showCategory,
    required this.itemLabel,
    this.isPointsMode = false,
    this.nameRequired = true,
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
                Text(
                  '品目 ${index + 1}',
                  style: camillBodyStyle(12, colors.textMuted),
                ),
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
                    decoration: InputDecoration(
                      labelText: itemLabel,
                      isDense: true,
                    ),
                    validator: nameRequired
                        ? (v) => (v == null || v.isEmpty) ? '入力してください' : null
                        : null,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: entry.priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isPointsMode ? '点数' : '金額',
                      prefixText: isPointsMode ? null : '¥',
                      suffixText: isPointsMode ? '点' : null,
                      isDense: true,
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            if (showCategory) ...[
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  final catColor =
                      AppConstants.categoryColors[entry.category] ??
                      Colors.grey;
                  final catLabel =
                      AppConstants.categoryLabels[entry.category] ??
                      entry.category;
                  return InkWell(
                    onTap: () async {
                      final result = await showCategoryBottomSheet(
                        context,
                        entry.category,
                      );
                      if (result != null) {
                        entry.category = result;
                        onChanged();
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: catColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: catColor.withAlpha(70)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: catColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            catLabel,
                            style: camillBodyStyle(
                              13,
                              catColor,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: catColor.withAlpha(180),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final CamillColors colors;
  final bool muted;
  final bool highlight;
  final Color? highlightColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.colors,
    this.muted = false,
    this.highlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = muted ? colors.textMuted : colors.textSecondary;
    final effectiveHighlight = highlightColor ?? colors.primary;
    final valueColor = highlight
        ? effectiveHighlight
        : (muted ? colors.textMuted : colors.textPrimary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: camillBodyStyle(13, labelColor)),
        Text(
          value,
          style: highlight
              ? camillAmountStyle(18, valueColor)
              : camillBodyStyle(14, valueColor, weight: FontWeight.w600),
        ),
      ],
    );
  }
}
