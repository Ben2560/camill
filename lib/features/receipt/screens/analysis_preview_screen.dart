import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/top_notification.dart';
import '../../coupon/services/coupon_service.dart';
import '../services/receipt_service.dart';

class AnalysisPreviewScreen extends StatefulWidget {
  final ReceiptAnalysis analysis;

  const AnalysisPreviewScreen({super.key, required this.analysis});

  @override
  State<AnalysisPreviewScreen> createState() => _AnalysisPreviewScreenState();
}

class _AnalysisPreviewScreenState extends State<AnalysisPreviewScreen> {
  final _receiptService = ReceiptService();
  final _couponService = CouponService();
  final _fmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
  bool _saving = false;

  late List<ReceiptItem> _items;
  late String _storeName;
  late DateTime? _purchasedAt;
  late String _paymentMethod;
  late String? _receiptCategory;
  late bool _categoryIsAuto;
  late int _totalAmount;
  late int _taxAmount;
  late bool _taxFromReceipt;
  late List<CouponDetected> _coupons;
  late List<bool> _couponIncluded;
  late bool _isMedical;
  late int _totalPoints;
  late double _burdenRate;

  // 品目の支出額が最大のカテゴリを自動判定
  String? get _autoCategory {
    if (_items.isEmpty) return null;
    final freq = <String, int>{};
    for (final item in _items) {
      freq[item.category] = (freq[item.category] ?? 0) + item.amount;
    }
    return freq.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // 表示に使う実効カテゴリ
  String? get _effectiveCategory => _receiptCategory ?? _autoCategory;

  @override
  void initState() {
    super.initState();
    _items = widget.analysis.items.where((item) => item.amount > 0).toList();
    _storeName = widget.analysis.storeName;
    _purchasedAt = DateTime.tryParse(widget.analysis.purchasedAt)?.toLocal();
    _paymentMethod = widget.analysis.paymentMethod;
    // APIが返したカテゴリを初期値に（ユーザーが変更したらフラグOFF）
    _receiptCategory = widget.analysis.category;
    _categoryIsAuto = widget.analysis.category != null;
    _totalAmount = widget.analysis.totalAmount;
    // 消費税はレシートから。なければ 0（未検出）
    _taxAmount = widget.analysis.taxAmount ?? 0;
    _taxFromReceipt = widget.analysis.taxAmount != null;
    _isMedical = widget.analysis.isMedical;
    _totalPoints = widget.analysis.totalPoints ?? 0;
    _burdenRate = widget.analysis.burdenRate ?? 0.0;
    // 医療レシートのデフォルト補正
    if (_isMedical) {
      if (_receiptCategory == null) {
        _receiptCategory = 'medical';
        _categoryIsAuto = false;
      }
      if (_paymentMethod == 'other') _paymentMethod = 'cash';
    }
    // validFrom が null で validUntil だけあるクーポンは購入日を開始日として補完
    final receiptDateStr = widget.analysis.purchasedAt.split('T').first;
    _coupons = widget.analysis.couponsDetected.map((c) {
      if (c.validFrom == null && c.validUntil != null) {
        return CouponDetected(
          description: c.description,
          discountAmount: c.discountAmount,
          validFrom: receiptDateStr,
          validUntil: c.validUntil,
          storageLocation: c.storageLocation,
        );
      }
      return c;
    }).toList();
    _couponIncluded = List.filled(_coupons.length, true);
  }

  Future<void> _saveReceipt() async {
    setState(() => _saving = true);
    try {
      final purchasedAtStr =
          _purchasedAt?.toIso8601String() ?? widget.analysis.purchasedAt;
      final includedCoupons = [
        for (int i = 0; i < _coupons.length; i++)
          if (_couponIncluded[i]) _coupons[i],
      ];
      final updated = ReceiptAnalysis(
        storeName: _storeName,
        purchasedAt: purchasedAtStr,
        totalAmount: _totalAmount,
        // 未検出時は null を送る（0はバリデーションエラーになる）
        taxAmount: _taxFromReceipt ? _taxAmount : null,
        paymentMethod: _paymentMethod,
        category: _receiptCategory,
        items: _items,
        couponsDetected: includedCoupons,
        duplicateCheckHash: widget.analysis.duplicateCheckHash,
        isMedical: _isMedical,
        totalPoints: _totalPoints != 0 ? _totalPoints : null,
        burdenRate: _burdenRate != 0 ? _burdenRate : null,
      );
      final receiptId = await _receiptService.saveReceipt(updated);
      // クーポンを /coupons に個別登録（レシートから検出されたので使用済みとして保存）
      for (final c in includedCoupons) {
        await _couponService.createCoupon(
          storeName: _storeName,
          description: c.description,
          discountAmount: c.discountAmount,
          validFrom: c.validFrom,
          validUntil: c.validUntil,
          isFromOcr: true,
          isUsed: true,
          receiptId: receiptId,
        );
      }
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.code == 'DUPLICATE_RECEIPT') {
        // 月別一覧から該当レシートを検索してDB上に存在するか確認
        String? existingId;
        try {
          final purchasedAt =
              _purchasedAt ?? DateTime.parse(widget.analysis.purchasedAt).toLocal();
          final yearMonth = DateFormat('yyyy-MM').format(purchasedAt);
          final receipts = await _receiptService.getReceipts(yearMonth);
          final match = receipts.where((r) {
            final rDate = DateTime.parse(r.purchasedAt).toLocal();
            return r.storeName == _storeName &&
                r.totalAmount == _totalAmount &&
                rDate.year == purchasedAt.year &&
                rDate.month == purchasedAt.month &&
                rDate.day == purchasedAt.day;
          }).firstOrNull;
          existingId = match?.receiptId;
        } catch (_) {}
        setState(() => _saving = false);
        if (existingId != null) {
          // レシートがDBに残っている → 上書き確認
          await _confirmOverwrite(existingId);
        } else {
          // レシートは削除済みだがハッシュが残っている → 空ハッシュで即再登録
          await _forceRegister();
        }
      } else {
        setState(() => _saving = false);
      }
    }
  }

  // ── ハッシュのみ残存時の強制再登録 ──────────────────────────
  Future<void> _forceRegister() async {
    setState(() => _saving = true);
    try {
      final purchasedAtStr =
          _purchasedAt?.toIso8601String() ?? widget.analysis.purchasedAt;
      final includedCoupons = [
        for (int i = 0; i < _coupons.length; i++)
          if (_couponIncluded[i]) _coupons[i],
      ];
      final receiptId = await _receiptService.saveReceipt(
        ReceiptAnalysis(
          storeName: _storeName,
          purchasedAt: purchasedAtStr,
          totalAmount: _totalAmount,
          taxAmount: _taxFromReceipt ? _taxAmount : null,
          paymentMethod: _paymentMethod,
          category: _receiptCategory,
          items: _items,
          couponsDetected: includedCoupons,
          duplicateCheckHash: '',
          isMedical: _isMedical,
          totalPoints: _totalPoints != 0 ? _totalPoints : null,
          burdenRate: _burdenRate != 0 ? _burdenRate : null,
        ),
      );
      for (final c in includedCoupons) {
        await _couponService.createCoupon(
          storeName: _storeName,
          description: c.description,
          discountAmount: c.discountAmount,
          validFrom: c.validFrom,
          validUntil: c.validUntil,
          isFromOcr: true,
          isUsed: true,
          receiptId: receiptId,
        );
      }
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── 重複時の上書き確認 ─────────────────────────────────────
  Future<void> _confirmOverwrite(String? existingId) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('すでに登録済みです',
            style: camillBodyStyle(16, colors.textPrimary,
                weight: FontWeight.w700)),
        content: Text(
          'このレシートはすでに登録されています。\n上書きして再登録しますか？',
          style: camillBodyStyle(14, colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('キャンセル',
                style: camillBodyStyle(14, colors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('上書き登録',
                style: camillBodyStyle(14, colors.primary,
                    weight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      final purchasedAtStr =
          _purchasedAt?.toIso8601String() ?? widget.analysis.purchasedAt;
      final includedCoupons = [
        for (int i = 0; i < _coupons.length; i++)
          if (_couponIncluded[i]) _coupons[i],
      ];
      final updated = ReceiptAnalysis(
        storeName: _storeName,
        purchasedAt: purchasedAtStr,
        totalAmount: _totalAmount,
        taxAmount: _taxFromReceipt ? _taxAmount : null,
        paymentMethod: _paymentMethod,
        category: _receiptCategory,
        items: _items,
        couponsDetected: includedCoupons,
        duplicateCheckHash: widget.analysis.duplicateCheckHash,
        isMedical: _isMedical,
        totalPoints: _totalPoints != 0 ? _totalPoints : null,
        burdenRate: _burdenRate != 0 ? _burdenRate : null,
      );
      // 1. 古いレシートを削除して新しいレシートを作成
      final newReceiptId =
          await _receiptService.overwriteReceipt(existingId!, updated);
      // 2. 同店・同説明文の既存クーポンを削除（重複防止）
      if (includedCoupons.isNotEmpty) {
        final existingCoupons = await _couponService.fetchCoupons();
        for (final existing in existingCoupons) {
          if (existing.storeName == _storeName &&
              includedCoupons
                  .any((c) => c.description == existing.description)) {
            try {
              await _couponService.deleteCoupon(existing.couponId);
            } catch (_) {}
          }
        }
      }
      // 3. 新しいクーポンを登録（レシートから検出されたので使用済みとして保存）
      for (final c in includedCoupons) {
        await _couponService.createCoupon(
          storeName: _storeName,
          description: c.description,
          discountAmount: c.discountAmount,
          validFrom: c.validFrom,
          validUntil: c.validUntil,
          isFromOcr: true,
          isUsed: true,
          receiptId: newReceiptId,
        );
      }
      if (mounted) {
        showTopNotification(context, 'レシートを上書き登録しました',
            backgroundColor: colors.primary);
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        showTopNotification(context, '上書きに失敗しました: $e');
        setState(() => _saving = false);
      }
    }
  }

  // ── 店名編集 ───────────────────────────────────────────────
  Future<void> _editStoreName() async {
    final colors = context.colors;
    final ctrl = TextEditingController(text: _storeName);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AnimatedPadding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(colors),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.store_outlined, color: colors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    '店名',
                    style: camillBodyStyle(
                      17,
                      colors.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _textInputField(
                ctrl: ctrl,
                hint: '店名を入力',
                autofocus: true,
                colors: colors,
              ),
            ),
            const SizedBox(height: 20),
            _saveButton(
              colors: colors,
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  setState(() => _storeName = ctrl.text.trim());
                }
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── 日時編集 ───────────────────────────────────────────────
  Future<void> _editDateTime() async {
    final initial = _purchasedAt ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _purchasedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // ── 支払方法編集 ───────────────────────────────────────────
  Future<void> _editPaymentMethod() async {
    final colors = context.colors;
    await showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(colors),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                '支払方法',
                style: camillBodyStyle(
                  17,
                  colors.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...AppConstants.paymentLabels.entries.map(
              (e) => ListTile(
                title: Text(
                  e.value,
                  style: camillBodyStyle(15, colors.textPrimary),
                ),
                leading: Icon(
                  _paymentMethod == e.key
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: _paymentMethod == e.key
                      ? colors.primary
                      : colors.textMuted,
                ),
                onTap: () {
                  setState(() => _paymentMethod = e.key);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── レシートカテゴリ編集 ───────────────────────────────────
  Future<void> _editReceiptCategory() async {
    final colors = context.colors;
    await showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CategoryPicker(
        current: _effectiveCategory ?? '',
        onSelected: (cat) {
          setState(() {
            _receiptCategory = cat;
            _categoryIsAuto = false;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ── 品目編集・追加 ─────────────────────────────────────────
  void _editItem(int index) => _openItemSheet(
    item: _items[index],
    onSave: (updated) => setState(() => _items[index] = updated),
    onDelete: () => setState(() => _items.removeAt(index)),
  );

  void _addItem() => _openItemSheet(
    item: ReceiptItem(
      itemName: '',
      itemNameRaw: '',
      category: 'other',
      unitPrice: 0,
      quantity: 1,
      amount: 0,
    ),
    onSave: (newItem) => setState(() => _items.add(newItem)),
    onDelete: null,
  );

  // ── クーポン編集・追加 ─────────────────────────────────────────
  void _editCoupon(int index) => _openCouponSheet(
    coupon: _coupons[index],
    onSave: (updated) => setState(() => _coupons[index] = updated),
    onDelete: () => setState(() {
      _coupons.removeAt(index);
      _couponIncluded.removeAt(index);
    }),
  );

  void _addCoupon() => _openCouponSheet(
    coupon: CouponDetected(description: '', discountAmount: 0),
    onSave: (c) => setState(() {
      _coupons.add(c);
      _couponIncluded.add(true);
    }),
    onDelete: null,
  );

  // 時刻なし → YYYY-MM-DD、時刻あり → フルISO
  static String? _fmtCouponDate(DateTime? dt) {
    if (dt == null) return null;
    if (dt.hour == 0 && dt.minute == 0) {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    return dt.toIso8601String();
  }

  void _updateCouponStorage(int index, String? location) {
    setState(() {
      final c = _coupons[index];
      _coupons[index] = CouponDetected(
        description: c.description,
        discountAmount: c.discountAmount,
        validFrom: c.validFrom,
        validUntil: c.validUntil,
        storageLocation: location,
      );
    });
  }

  static const _storageOptions = [
    '紙クーポン', 'アプリ', 'ポイントカード', 'メール・LINE', 'その他',
  ];

  void _openCouponSheet({
    required CouponDetected coupon,
    required void Function(CouponDetected) onSave,
    required VoidCallback? onDelete,
  }) {
    final colors = context.colors;
    final descCtrl = TextEditingController(text: coupon.description);
    final amtCtrl = TextEditingController(
      text: coupon.discountAmount > 0 ? coupon.discountAmount.toString() : '',
    );
    DateTime? validFrom = coupon.validFrom != null
        ? DateTime.tryParse(coupon.validFrom!)
        : null;
    DateTime? validUntil = coupon.validUntil != null
        ? DateTime.tryParse(coupon.validUntil!)
        : null;
    String? storageLocation = coupon.storageLocation;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => AnimatedPadding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(colors),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text('クーポンを編集',
                          style: camillBodyStyle(17, colors.textPrimary,
                              weight: FontWeight.w700)),
                      const Spacer(),
                      if (onDelete != null)
                        GestureDetector(
                          onTap: () { Navigator.pop(ctx); onDelete(); },
                          child: Text('削除',
                              style: camillBodyStyle(14, const Color(0xFFFF3B30))),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // 品目
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _labeledField(
                    label: '品目（クーポン名・内容）',
                    child: _textInputField(
                        ctrl: descCtrl, hint: 'クーポンの内容を入力', colors: colors),
                  ),
                ),
                const SizedBox(height: 12),
                // 値引き額
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _labeledField(
                    label: '値引き額（0 = 無料クーポン）',
                    child: _numberInputField(ctrl: amtCtrl, colors: colors),
                  ),
                ),
                const SizedBox(height: 12),
                // 有効期間
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _labeledField(
                    label: '有効期間',
                    child: Row(
                      children: [
                        Expanded(
                          child: _DatePickerField(
                            label: '開始日',
                            date: validFrom,
                            colors: colors,
                            withTime: true,
                            onPick: (d) => setSheet(() => validFrom = d),
                            onClear: () => setSheet(() => validFrom = null),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('〜', style: camillBodyStyle(14, colors.textMuted)),
                        ),
                        Expanded(
                          child: _DatePickerField(
                            label: '終了日',
                            date: validUntil,
                            colors: colors,
                            withTime: true,
                            onPick: (d) => setSheet(() => validUntil = d),
                            onClear: () => setSheet(() => validUntil = null),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 保管場所
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _labeledField(
                    label: '保管場所',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _storageOptions.map((opt) {
                        final selected = storageLocation == opt;
                        return GestureDetector(
                          onTap: () => setSheet(() =>
                              storageLocation = selected ? null : opt),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: selected
                                  ? colors.primary
                                  : colors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? colors.primary
                                    : colors.surfaceBorder,
                              ),
                            ),
                            child: Text(
                              opt,
                              style: camillBodyStyle(
                                  13,
                                  selected
                                      ? colors.fabIcon
                                      : colors.textSecondary),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _saveButton(
                  colors: colors,
                  onPressed: () {
                    final desc = descCtrl.text.trim();
                    if (desc.isEmpty) return;
                    onSave(CouponDetected(
                      description: desc,
                      discountAmount: int.tryParse(amtCtrl.text) ?? 0,
                      validFrom: _fmtCouponDate(validFrom),
                      validUntil: _fmtCouponDate(validUntil),
                      storageLocation: storageLocation,
                    ));
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openItemSheet({
    required ReceiptItem item,
    required void Function(ReceiptItem) onSave,
    required VoidCallback? onDelete,
  }) {
    final colors = context.colors;
    final nameCtrl = TextEditingController(text: item.itemName);
    final amtCtrl = TextEditingController(
      text: item.amount > 0 ? item.amount.toString() : '',
    );
    String selectedCategory = item.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => AnimatedPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(colors),
              // ヘッダー行
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      '品目を編集',
                      style: camillBodyStyle(
                        17,
                        colors.textPrimary,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (onDelete != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          onDelete();
                        },
                        child: Text(
                          '削除',
                          style: camillBodyStyle(14, const Color(0xFFFF3B30)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 品目名
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _labeledField(
                  label: '品目名',
                  child: _textInputField(
                    ctrl: nameCtrl,
                    hint: '品目名を入力',
                    colors: colors,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 金額
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _labeledField(
                  label: '金額',
                  child: _numberInputField(ctrl: amtCtrl, colors: colors),
                ),
              ),
              const SizedBox(height: 12),
              // カテゴリ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _labeledField(
                  label: 'カテゴリ',
                  child: GestureDetector(
                    onTap: () async {
                      await showModalBottomSheet(
                        context: ctx,
                        backgroundColor: colors.background,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        builder: (ctx2) => _CategoryPicker(
                          current: selectedCategory,
                          onSelected: (cat) {
                            setSheet(() => selectedCategory = cat);
                            Navigator.pop(ctx2);
                          },
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.surfaceBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppConstants.categoryLabels[selectedCategory] ??
                                selectedCategory,
                            style: camillBodyStyle(15, colors.textPrimary),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: colors.textMuted,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _saveButton(
                colors: colors,
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final amt = int.tryParse(amtCtrl.text) ?? 0;
                  if (name.isEmpty) return;
                  onSave(
                    ReceiptItem(
                      itemName: name,
                      itemNameRaw: item.itemNameRaw,
                      category: selectedCategory,
                      unitPrice: amt,
                      quantity: 1,
                      amount: amt,
                    ),
                  );
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── 消費税編集 ─────────────────────────────────────────────────
  Future<void> _editTax() async {
    final colors = context.colors;
    final ctrl = TextEditingController(text: _taxAmount.toString());
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AnimatedPadding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(colors),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      color: colors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text('内消費税等',
                      style: camillBodyStyle(17, colors.textPrimary,
                          weight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _numberInputField(ctrl: ctrl, colors: colors),
            ),
            const SizedBox(height: 20),
            _saveButton(
              colors: colors,
              onPressed: () {
                setState(() => _taxAmount = int.tryParse(ctrl.text) ?? _taxAmount);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── 共通ウィジェット ───────────────────────────────────────
  Widget _sheetHandle(CamillColors colors) => Center(
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

  Widget _labeledField({required String label, required Widget child}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      );

  Widget _textInputField({
    required TextEditingController ctrl,
    required String hint,
    required CamillColors colors,
    bool autofocus = false,
  }) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: TextField(
          controller: ctrl,
          autofocus: autofocus,
          style: camillBodyStyle(15, colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: camillBodyStyle(15, colors.textMuted),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    ),
  );

  Widget _numberInputField({
    required TextEditingController ctrl,
    required CamillColors colors,
  }) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Row(
        children: [
          Text(
            '¥',
            style: camillBodyStyle(
              16,
              colors.textMuted,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                splashFactory: NoSplash.splashFactory,
                highlightColor: Colors.transparent,
              ),
              child: TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                  signed: false,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: camillBodyStyle(15, colors.textPrimary),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: camillBodyStyle(15, colors.textMuted),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _saveButton({
    required CamillColors colors,
    required VoidCallback onPressed,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          '決定する',
          style: camillBodyStyle(16, Colors.white, weight: FontWeight.w600),
        ),
      ),
    ),
  );

  // ── build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final purchasedAt = _purchasedAt;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(
          '解析結果の確認',
          style: camillHeadingStyle(17, colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textSecondary),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── ヘッダー情報 ──
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.surfaceBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _EditableInfoRow(
                        label: '店名',
                        value: _storeName,
                        icon: Icons.store_outlined,
                        colors: colors,
                        onTap: _editStoreName,
                      ),
                      Divider(height: 20, color: colors.surfaceBorder),
                      _EditableInfoRow(
                        label: _isMedical ? '来院日時' : '購入日時',
                        value: purchasedAt != null
                            ? (_isMedical && purchasedAt.hour == 0 && purchasedAt.minute == 0)
                                ? DateFormat('yyyy年M月d日').format(purchasedAt)
                                : DateFormat('yyyy年M月d日 HH:mm').format(purchasedAt)
                            : widget.analysis.purchasedAt,
                        icon: Icons.calendar_today_outlined,
                        colors: colors,
                        onTap: _editDateTime,
                      ),
                      Divider(height: 20, color: colors.surfaceBorder),
                      _EditableInfoRow(
                        label: '支払方法',
                        value:
                            AppConstants.paymentLabels[_paymentMethod] ??
                            _paymentMethod,
                        icon: Icons.payment_outlined,
                        colors: colors,
                        onTap: _editPaymentMethod,
                      ),
                      Divider(height: 20, color: colors.surfaceBorder),
                      _EditableInfoRow(
                        label: 'カテゴリ',
                        value: AppConstants.categoryLabels[_effectiveCategory] ??
                            (_effectiveCategory ?? '未設定'),
                        badge: _categoryIsAuto ? '自動' : null,
                        icon: Icons.label_outline,
                        colors: colors,
                        onTap: _editReceiptCategory,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // ── 品目リスト ──
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.surfaceBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isMedical ? '診療内容' : '品目',
                        style: camillBodyStyle(
                          15,
                          colors.textPrimary,
                          weight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._items.asMap().entries.map(
                        (e) => _EditableItemRow(
                          item: e.value,
                          fmt: _fmt,
                          colors: colors,
                          isMedical: _isMedical,
                          onTap: () => _editItem(e.key),
                        ),
                      ),
                      // 品目追加ボタン
                      GestureDetector(
                        onTap: _addItem,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 18,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '品目を追加',
                                style: camillBodyStyle(13, colors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_taxFromReceipt) ...[
                        Divider(color: colors.surfaceBorder),
                        // 消費税行（編集可能）
                        GestureDetector(
                          onTap: () => _editTax(),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 14, color: colors.textMuted),
                                const SizedBox(width: 6),
                                Text('内消費税等',
                                    style: camillBodyStyle(13, colors.textMuted)),
                                const Spacer(),
                                Text(_fmt.format(_taxAmount),
                                    style: camillBodyStyle(
                                        13, colors.textMuted,
                                        weight: FontWeight.w500)),
                                const SizedBox(width: 6),
                                Icon(Icons.edit_outlined,
                                    size: 13, color: colors.textMuted),
                              ],
                            ),
                          ),
                        ),
                      ],
                      Divider(color: colors.surfaceBorder),
                      if (_isMedical) ...[
                        // 合計点数 + 10割金額
                        Row(
                          children: [
                            Text(
                              '合計',
                              style: camillBodyStyle(13, colors.textMuted),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_totalPoints点',
                              style: camillBodyStyle(15, colors.textPrimary,
                                  weight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text(
                              '10割: ${_fmt.format(_totalPoints * 10)}',
                              style: camillBodyStyle(12, colors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // 負担率
                        Row(
                          children: [
                            Text(
                              '負担率',
                              style: camillBodyStyle(13, colors.textMuted),
                            ),
                            const Spacer(),
                            Text(
                              '${(_burdenRate * 10).round()}割負担',
                              style: camillBodyStyle(13, colors.textSecondary,
                                  weight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // 実負担額
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '実負担額',
                              style: camillBodyStyle(14, colors.textPrimary,
                                  weight: FontWeight.bold),
                            ),
                            Text(
                              _fmt.format(_totalAmount),
                              style: camillAmountStyle(18, colors.textPrimary),
                            ),
                          ],
                        ),
                      ] else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '合計（税込）',
                              style: camillBodyStyle(
                                14,
                                colors.textPrimary,
                                weight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _fmt.format(_totalAmount),
                              style: camillAmountStyle(18, colors.textPrimary),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // ── クーポン（医療時は非表示）──
                if (!_isMedical) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.surfaceBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'クーポン',
                        style: camillBodyStyle(15, colors.textPrimary,
                            weight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._coupons.asMap().entries.expand((e) {
                        final i = e.key;
                        final c = e.value;
                        final isFree = c.discountAmount == 0;
                        final accentColor = isFree
                            ? const Color(0xFFD4A017)
                            : colors.primary;

                        // 有効期間テキスト
                        String? periodText;
                        if (c.validFrom != null && c.validUntil != null) {
                          final f = DateTime.tryParse(c.validFrom!);
                          final u = DateTime.tryParse(c.validUntil!);
                          if (f != null && u != null) {
                            periodText = '${f.month}/${f.day} 〜 ${u.month}/${u.day}';
                          }
                        } else if (c.validUntil != null) {
                          final u = DateTime.tryParse(c.validUntil!);
                          if (u != null) periodText = '〜 ${u.month}/${u.day}まで';
                        } else if (c.validFrom != null) {
                          final f = DateTime.tryParse(c.validFrom!);
                          if (f != null) periodText = '${f.month}/${f.day}〜';
                        }

                        return [
                          if (i > 0) Divider(height: 16, color: colors.surfaceBorder),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1行目: チェック + アイコン + 説明 + 金額 + 編集
                                Row(
                                  children: [
                                    Transform.translate(
                                      offset: const Offset(-6, 0),
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: Checkbox(
                                          value: _couponIncluded[i],
                                          activeColor: colors.primary,
                                          visualDensity: VisualDensity.compact,
                                          onChanged: (v) => setState(
                                              () => _couponIncluded[i] = v ?? true),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      isFree
                                          ? Icons.card_giftcard_outlined
                                          : Icons.local_offer_outlined,
                                      size: 15,
                                      color: accentColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        c.description.isEmpty ? '（未入力）' : c.description,
                                        style: camillBodyStyle(14, colors.textPrimary,
                                            weight: FontWeight.w500),
                                      ),
                                    ),
                                    Text(
                                      isFree ? '無料' : '${c.discountAmount}円引き',
                                      style: camillBodyStyle(13, accentColor,
                                          weight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _editCoupon(i),
                                      child: Icon(Icons.edit_outlined,
                                          size: 14, color: colors.textMuted),
                                    ),
                                  ],
                                ),
                                // 2行目: 有効期間
                                if (periodText != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 30, top: 2),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today_outlined,
                                            size: 11, color: colors.textMuted),
                                        const SizedBox(width: 3),
                                        Text(periodText,
                                            style: camillBodyStyle(11, colors.textMuted)),
                                      ],
                                    ),
                                  ),
                                // 3行目: 保管場所チップ（インライン選択）
                                Padding(
                                  padding: const EdgeInsets.only(left: 30, top: 6),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: _storageOptions.map((opt) {
                                      final selected = c.storageLocation == opt;
                                      return GestureDetector(
                                        onTap: () => _updateCouponStorage(
                                            i, selected ? null : opt),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? accentColor
                                                : colors.surface,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: selected
                                                  ? accentColor
                                                  : colors.surfaceBorder,
                                            ),
                                          ),
                                          child: Text(
                                            opt,
                                            style: camillBodyStyle(
                                              10,
                                              selected
                                                  ? colors.fabIcon
                                                  : colors.textMuted,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ];
                      }),
                      GestureDetector(
                        onTap: _addCoupon,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline,
                                  size: 18, color: colors.primary),
                              const SizedBox(width: 6),
                              Text('クーポンを追加',
                                  style: camillBodyStyle(13, colors.primary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ], // end if (!_isMedical)
                const SizedBox(height: 80),
              ],
            ),
          ),
          // ── 登録ボタン ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saving ? null : _saveReceipt,
                icon: _saving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.fabIcon,
                        ),
                      )
                    : Icon(Icons.save_outlined, color: colors.fabIcon),
                label: Text(
                  'このレシートを登録',
                  style: camillBodyStyle(16, colors.fabIcon),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ヘッダー行（編集可能） ─────────────────────────────────────
class _EditableInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? badge;
  final IconData icon;
  final CamillColors colors;
  final VoidCallback onTap;

  const _EditableInfoRow({
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
            child: Text(
              value,
              style: camillBodyStyle(13, colors.textPrimary, weight: FontWeight.w500),
            ),
          ),
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primaryLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge!, style: camillBodyStyle(10, colors.primary, weight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
          ],
          Icon(Icons.edit_outlined, size: 14, color: colors.textMuted),
        ],
      ),
    );
  }
}

// ── 品目行（編集可能） ─────────────────────────────────────────
class _EditableItemRow extends StatelessWidget {
  final ReceiptItem item;
  final NumberFormat fmt;
  final CamillColors colors;
  final bool isMedical;
  final VoidCallback onTap;

  const _EditableItemRow({
    required this.item,
    required this.fmt,
    required this.colors,
    required this.isMedical,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final catLabel =
        AppConstants.categoryLabels[item.category] ?? item.category;
    final amountText = isMedical
        ? '${item.points}点'
        : '${item.quantity > 1 ? '×${item.quantity}  ' : ''}${fmt.format(item.amount)}';
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
                  Text(
                    item.itemName,
                    style: camillBodyStyle(
                      14,
                      colors.textPrimary,
                      weight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      catLabel,
                      style: camillBodyStyle(11, colors.primary),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amountText,
              style: camillBodyStyle(
                14,
                colors.textPrimary,
                weight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit_outlined, size: 14, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── カテゴリピッカー ───────────────────────────────────────────
class _CategoryPicker extends StatelessWidget {
  final String current;
  final void Function(String) onSelected;

  const _CategoryPicker({required this.current, required this.onSelected});

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
              child: Text(
                'カテゴリを選択',
                style: camillBodyStyle(
                  17,
                  colors.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...AppConstants.categoryLabels.entries.map(
              (e) => ListTile(
                title: Text(
                  e.value,
                  style: camillBodyStyle(15, colors.textPrimary),
                ),
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

// ── 日付ピッカーフィールド ─────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final CamillColors colors;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;
  final bool withTime;

  const _DatePickerField({
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
        onPick(DateTime(
          picked.year, picked.month, picked.day,
          time?.hour ?? 0, time?.minute ?? 0,
        ));
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
            Icon(Icons.calendar_today_outlined,
                size: 14, color: colors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                displayText,
                style: camillBodyStyle(
                    13, hasDate ? colors.textPrimary : colors.textMuted),
              ),
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
