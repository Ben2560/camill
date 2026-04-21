import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/top_notification.dart';
import '../../bill/services/bill_service.dart';
import '../../coupon/services/coupon_service.dart';
import '../services/receipt_service.dart';
import '../../../shared/services/overseas_service.dart';
import 'receipt_form_widgets.dart';

class ReceiptFormPage extends StatefulWidget {
  final ReceiptAnalysis analysis;

  const ReceiptFormPage({super.key, required this.analysis});

  @override
  State<ReceiptFormPage> createState() => ReceiptFormPageState();
}

class ReceiptFormPageState extends State<ReceiptFormPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _receiptService = ReceiptService();
  final _couponService = CouponService();
  final _billService = BillService();
  final _fmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');

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
  late List<bool> _shareToComm;
  late bool _isMedical;
  late bool _isUncovered;
  late int _totalPoints;
  late double _burdenRate;
  late bool _isBill;
  DateTime? _billDueDate;
  late String _billStatus; // 'paid' | 'unpaid'
  DateTime? _billPaidDate; // 印鑑から読み取った支払済み日
  late bool _billIsTaxExempt;

  bool _isOverseas = false;
  String _overseasCurrency = 'JPY';
  double _overseasExchangeRate = 1.0;

  final _memoCtrl = TextEditingController();
  final _memoFocus = FocusNode();
  bool _memoEditing = false;
  int _memoMinLines = 6;

  // 同一品目グループの展開状態
  final Set<String> _expandedGroups = {};

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
    _items = widget.analysis.items.where((item) => item.amount > 0).expand((
      item,
    ) {
      if (item.quantity <= 1) return [item];
      final perUnit =
          (item.unitPrice > 0 && item.unitPrice * item.quantity == item.amount)
          ? item.unitPrice
          : item.amount ~/ item.quantity;
      final unit = item.copyWith(
        quantity: 1,
        unitPrice: perUnit,
        amount: perUnit,
      );
      return List.filled(item.quantity, unit);
    }).toList();
    _storeName = widget.analysis.storeName;
    _purchasedAt = DateTime.tryParse(widget.analysis.purchasedAt)?.toLocal();
    _paymentMethod = widget.analysis.paymentMethod;
    _receiptCategory = widget.analysis.category;
    _categoryIsAuto = widget.analysis.category != null;
    _totalAmount = widget.analysis.totalAmount;
    _taxAmount = widget.analysis.taxAmount ?? 0;
    _taxFromReceipt = widget.analysis.taxAmount != null;
    _isMedical = widget.analysis.isMedical;
    _isUncovered = widget.analysis.isUncovered;
    _totalPoints = widget.analysis.totalPoints ?? 0;
    _burdenRate = widget.analysis.burdenRate ?? 0.0;
    _isBill = widget.analysis.isBill;
    _billDueDate = widget.analysis.billDueDate;
    _billStatus = widget.analysis.billStatus;
    _billPaidDate = widget.analysis.billPaidDate;
    _billIsTaxExempt = widget.analysis.billIsTaxExempt;
    if (_isMedical) {
      if (_receiptCategory == null) {
        _receiptCategory = 'medical';
        _categoryIsAuto = false;
      }
      if (_paymentMethod == 'other') _paymentMethod = 'cash';
    }
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
    _couponIncluded = List.filled(_coupons.length, true, growable: true);
    _shareToComm = List.filled(_coupons.length, false, growable: true);
    _memoCtrl.addListener(_onMemoChanged);
    _memoFocus.addListener(() {
      if (!_memoFocus.hasFocus && _memoEditing) {
        setState(() => _memoEditing = false);
      }
    });
    _loadOverseasState();
  }

  Future<void> _loadOverseasState() async {
    final service = OverseasService(ApiService());
    final isOverseas = await service.getIsOverseas();
    if (!isOverseas || !mounted) return;
    final currency = await service.getCurrentCurrency();
    final rates = await service.fetchRates();
    final rate = (rates[currency] as num?)?.toDouble() ?? 1.0;
    if (mounted) {
      setState(() {
        _isOverseas = true;
        _overseasCurrency = currency;
        _overseasExchangeRate = rate;
      });
    }
  }

  @override
  void dispose() {
    _memoCtrl.removeListener(_onMemoChanged);
    _memoCtrl.dispose();
    _memoFocus.dispose();
    super.dispose();
  }

  void _onMemoChanged() {
    final lineCount = _memoCtrl.text.isEmpty
        ? 0
        : _memoCtrl.text.split('\n').length;
    final needed = (lineCount + 1).clamp(6, 9999);
    if (needed > _memoMinLines) {
      setState(() => _memoMinLines = needed);
    }
  }

  String _itemGroupKey(ReceiptItem item) => '${item.itemName}|${item.amount}';

  // 同一品目（名前・金額が同じ）をグループ化して表示するウィジェット列を返す
  List<Widget> _buildGroupedItems(CamillColors colors) {
    final Map<String, List<int>> groups = {};
    final List<String> groupOrder = [];
    for (int i = 0; i < _items.length; i++) {
      final key = _itemGroupKey(_items[i]);
      if (!groups.containsKey(key)) groupOrder.add(key);
      groups.putIfAbsent(key, () => []).add(i);
    }

    final widgets = <Widget>[];
    for (final key in groupOrder) {
      final indices = groups[key]!;
      if (indices.length == 1) {
        // 1件：既存の動作そのまま
        final i = indices.first;
        widgets.add(
          ReceiptSwipeable(
            onDelete: () => setState(() => _items.removeAt(i)),
            background: colors.surface,
            child: ReceiptEditableItemRow(
              item: _items[i],
              fmt: _fmt,
              colors: colors,
              isMedical: _isMedical,
              onTap: () => _editItem(i),
              isOverseas: _isOverseas,
              overseasCurrency: _overseasCurrency,
              exchangeRate: _overseasExchangeRate,
            ),
          ),
        );
      } else {
        // 複数同一品目：折りたたみグループ
        final isExpanded = _expandedGroups.contains(key);
        final item = _items[indices.first];
        final count = indices.length;

        widgets.add(
          Column(
            key: ValueKey('group_$key'),
            mainAxisSize: MainAxisSize.min,
            children: [
              // グループヘッダー（常時表示）
              GestureDetector(
                onTap: () => setState(() {
                  if (isExpanded) {
                    _expandedGroups.remove(key);
                  } else {
                    _expandedGroups.add(key);
                  }
                }),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    (_isOverseas && item.itemNameRaw.isNotEmpty)
                                        ? item.itemNameRaw
                                        : item.itemName,
                                    style: camillBodyStyle(
                                      14,
                                      colors.textPrimary,
                                      weight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '×$count',
                                    style: camillBodyStyle(
                                      11,
                                      colors.primary,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_isOverseas &&
                                item.itemNameRaw.isNotEmpty &&
                                item.itemName.isNotEmpty &&
                                item.itemNameRaw != item.itemName)
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Text(
                                  '↪︎ ${item.itemName}',
                                  style: camillBodyStyle(12, colors.textMuted),
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
                                AppConstants.categoryLabels[item.category] ??
                                    item.category,
                                style: camillBodyStyle(11, colors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isOverseas)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$_overseasCurrency ${item.amount * count}',
                              style: camillBodyStyle(
                                14,
                                colors.textPrimary,
                                weight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '¥${(item.amount * count * _overseasExchangeRate).round()}',
                              style: camillBodyStyle(11, colors.textMuted),
                            ),
                          ],
                        )
                      else
                        Text(
                          _fmt.format(item.amount * count),
                          style: camillBodyStyle(
                            14,
                            colors.textPrimary,
                            weight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              // 展開コンテンツ（AnimatedSizeでスムーズに開閉）
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 2),
                          // 個数ステッパー（タップで増減、テキスト消去不要）
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '個数',
                                  style: camillBodyStyle(12, colors.primary),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: count > 1
                                      ? () {
                                          setState(() {
                                            _items.removeAt(indices.last);
                                            if (count - 1 < 2) {
                                              _expandedGroups.remove(key);
                                            }
                                          });
                                        }
                                      : null,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: count > 1
                                          ? colors.surface
                                          : colors.surfaceBorder,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colors.surfaceBorder,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      size: 16,
                                      color: count > 1
                                          ? colors.textPrimary
                                          : colors.textMuted,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Text(
                                    '$count',
                                    style: camillBodyStyle(
                                      16,
                                      colors.textPrimary,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _items.add(
                                        _items[indices.last].copyWith(),
                                      );
                                    });
                                  },
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colors.surfaceBorder,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 16,
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 個々の品目行（タップで編集シートを開く）
                          ...indices.map(
                            (globalIdx) => ReceiptEditableItemRow(
                              item: _items[globalIdx],
                              fmt: _fmt,
                              colors: colors,
                              isMedical: _isMedical,
                              onTap: () => _editItem(globalIdx),
                              isOverseas: _isOverseas,
                              overseasCurrency: _overseasCurrency,
                              exchangeRate: _overseasExchangeRate,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }
    }
    return widgets;
  }

  static bool _isConvenienceStore(String name) {
    const keywords = [
      'セブンイレブン',
      'セブン-イレブン',
      '7-eleven',
      '7eleven',
      'ファミリーマート',
      'ファミマ',
      'ローソン',
      'ミニストップ',
      'デイリーヤマザキ',
      'ヤマザキデイリー',
      'セイコーマート',
    ];
    final lower = name.toLowerCase();
    return keywords.any((k) => lower.contains(k.toLowerCase()));
  }

  Future<bool> performSave() async {
    final purchasedAtStr =
        _purchasedAt?.toIso8601String() ?? widget.analysis.purchasedAt;
    final includedCoupons = [
      for (int i = 0; i < _coupons.length; i++)
        if (_couponIncluded[i]) _coupons[i],
    ];
    // 海外モード時は金額を JPY に変換して保存
    final saveItems = _isOverseas
        ? _items
              .map(
                (item) => item.copyWith(
                  amount: (item.amount * _overseasExchangeRate).round(),
                  unitPrice: (item.unitPrice * _overseasExchangeRate).round(),
                ),
              )
              .toList()
        : _items;
    final saveTotalAmount = _isOverseas
        ? (_totalAmount * _overseasExchangeRate).round()
        : _totalAmount;
    final updated = ReceiptAnalysis(
      storeName: _storeName,
      purchasedAt: purchasedAtStr,
      totalAmount: saveTotalAmount,
      taxAmount: _taxFromReceipt ? _taxAmount : null,
      paymentMethod: _paymentMethod,
      category: _receiptCategory,
      items: saveItems,
      couponsDetected: includedCoupons,
      duplicateCheckHash: widget.analysis.duplicateCheckHash,
      isMedical: _isMedical,
      isUncovered: _isUncovered,
      totalPoints: _totalPoints != 0 ? _totalPoints : null,
      burdenRate: _burdenRate != 0 ? _burdenRate : null,
      memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
    );
    try {
      if (_isBill) {
        // 請求書はレシートテーブルに保存しない（二重計上防止）
        await _billService.createBill(
          title: _storeName,
          amount: _totalAmount,
          dueDate: _billDueDate?.toLocal().toIso8601String(),
          status: _billStatus,
          category: _receiptCategory ?? _autoCategory,
          isTaxExempt: _billIsTaxExempt,
          paidAt: _billStatus == 'paid'
              ? (_billPaidDate ?? DateTime.now()).toIso8601String()
              : null,
        );
        return true;
      }
      final receiptId = await _receiptService.saveReceipt(updated);
      for (int i = 0; i < _coupons.length; i++) {
        if (!_couponIncluded[i]) continue;
        final c = _coupons[i];
        final coupon = await _couponService.createCoupon(
          storeName: _storeName,
          description: c.description,
          discountAmount: c.discountAmount,
          validFrom: c.validFrom,
          validUntil: c.validUntil,
          isFromOcr: true,
          isUsed: !c.requiresSurvey,
          receiptId: receiptId,
          requiresSurvey: c.requiresSurvey,
          surveyUrl: c.surveyUrl,
        );
        if (_shareToComm[i]) {
          try {
            await _couponService.shareToCommunity(coupon.couponId);
          } catch (_) {}
        }
      }
      return true;
    } catch (e) {
      if (!mounted) return false;
      if (e is ApiException && e.code == 'DUPLICATE_RECEIPT') {
        String? existingId;
        try {
          final purchasedAt =
              _purchasedAt ??
              DateTime.parse(widget.analysis.purchasedAt).toLocal();
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
        } catch (e) {
          debugPrint('receipt duplicate check failed: $e');
        }
        if (existingId != null) {
          return await _confirmOverwrite(existingId, updated, includedCoupons);
        } else {
          return await _forceRegister(updated, includedCoupons);
        }
      }
      return false;
    }
  }

  Future<bool> _forceRegister(
    ReceiptAnalysis updated,
    List<CouponDetected> includedCoupons,
  ) async {
    try {
      final updatedNoHash = ReceiptAnalysis(
        storeName: updated.storeName,
        purchasedAt: updated.purchasedAt,
        totalAmount: updated.totalAmount,
        taxAmount: updated.taxAmount,
        paymentMethod: updated.paymentMethod,
        category: updated.category,
        items: updated.items,
        couponsDetected: updated.couponsDetected,
        linePromotions: updated.linePromotions,
        duplicateCheckHash: '',
        isMedical: updated.isMedical,
        totalPoints: updated.totalPoints,
        burdenRate: updated.burdenRate,
        memo: updated.memo,
        isBill: updated.isBill,
        billDueDate: updated.billDueDate,
      );
      final receiptId = await _receiptService.saveReceipt(updatedNoHash);
      for (int i = 0; i < _coupons.length; i++) {
        if (!_couponIncluded[i]) continue;
        final c = _coupons[i];
        final coupon = await _couponService.createCoupon(
          storeName: _storeName,
          description: c.description,
          discountAmount: c.discountAmount,
          validFrom: c.validFrom,
          validUntil: c.validUntil,
          isFromOcr: true,
          isUsed: !c.requiresSurvey,
          receiptId: receiptId,
          requiresSurvey: c.requiresSurvey,
          surveyUrl: c.surveyUrl,
        );
        if (_shareToComm[i]) {
          try {
            await _couponService.shareToCommunity(coupon.couponId);
          } catch (_) {}
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _confirmOverwrite(
    String existingId,
    ReceiptAnalysis updated,
    List<CouponDetected> includedCoupons,
  ) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'すでに登録済みです',
          style: camillBodyStyle(
            16,
            colors.textPrimary,
            weight: FontWeight.w700,
          ),
        ),
        content: Text(
          'このレシートはすでに登録されています。\n上書きして再登録しますか？',
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
              '上書き登録',
              style: camillBodyStyle(
                14,
                colors.primary,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;
    try {
      final newReceiptId = await _receiptService.overwriteReceipt(
        existingId,
        updated,
      );
      if (includedCoupons.isNotEmpty) {
        final existingCoupons = await _couponService.fetchCoupons();
        for (final existing in existingCoupons) {
          if (existing.storeName == _storeName &&
              includedCoupons.any(
                (c) => c.description == existing.description,
              )) {
            try {
              await _couponService.deleteCoupon(existing.couponId);
            } catch (e) {
              debugPrint('coupon deletion failed: $e');
            }
          }
        }
      }
      for (int i = 0; i < _coupons.length; i++) {
        if (!_couponIncluded[i]) continue;
        final c = _coupons[i];
        final coupon = await _couponService.createCoupon(
          storeName: _storeName,
          description: c.description,
          discountAmount: c.discountAmount,
          validFrom: c.validFrom,
          validUntil: c.validUntil,
          isFromOcr: true,
          isUsed: !c.requiresSurvey,
          receiptId: newReceiptId,
          requiresSurvey: c.requiresSurvey,
          surveyUrl: c.surveyUrl,
        );
        if (_shareToComm[i]) {
          try {
            await _couponService.shareToCommunity(coupon.couponId);
          } catch (_) {}
        }
      }
      if (mounted) {
        showTopNotification(
          context,
          'レシートを上書き登録しました',
          backgroundColor: colors.primary,
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        showTopNotification(context, '上書きに失敗しました: $e');
      }
      return false;
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

  // ── 請求書支払期限編集 ─────────────────────────────────────
  Future<void> _editBillDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _billDueDate ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _billDueDate = picked);
  }

  // ── 請求書支払方法編集（現金・QR・ペイジーのみ） ────────────
  Future<void> _editBillPaymentMethod() async {
    final colors = context.colors;
    const billPaymentOptions = {
      'cash': '現金',
      'qr': 'QRコード',
      'pay_easy': 'ペイジー',
    };
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
            ...billPaymentOptions.entries.map(
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
      builder: (ctx) => ReceiptCategoryPicker(
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

  // ── クーポン削除 ──────────────────────────────────────────────
  void _deleteCoupon(int index) {
    setState(() {
      _coupons.removeAt(index);
      _couponIncluded.removeAt(index);
      _shareToComm.removeAt(index);
    });
  }

  // ── クーポン編集・追加 ─────────────────────────────────────────
  void _editCoupon(int index) => _openCouponSheet(
    coupon: _coupons[index],
    onSave: (updated) => setState(() => _coupons[index] = updated),
    onDelete: () => setState(() {
      _coupons.removeAt(index);
      _couponIncluded.removeAt(index);
      _shareToComm.removeAt(index);
    }),
  );

  void _addCoupon() => _openCouponSheet(
    coupon: CouponDetected(description: '', discountAmount: 0),
    onSave: (c) => setState(() {
      _coupons.add(c);
      _couponIncluded.add(true);
      _shareToComm.add(false);
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
        discountUnit: c.discountUnit,
        validFrom: c.validFrom,
        validUntil: c.validUntil,
        storageLocation: location,
        requiresSurvey: c.requiresSurvey,
        surveyUrl: c.surveyUrl,
      );
    });
  }

  static const _storageOptions = ['紙クーポン', 'アプリ', 'ポイントカード', 'メール・LINE', 'その他'];

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
    String discountUnit = coupon.discountUnit ?? 'yen';
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
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
                      Text(
                        'クーポンを編集',
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _labeledField(
                    label: '品目（クーポン名・内容）',
                    child: _textInputField(
                      ctrl: descCtrl,
                      hint: 'クーポンの内容を入力',
                      colors: colors,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _labeledField(
                    label: '割引タイプ',
                    child: Row(
                      children: [
                        for (final entry in const [
                          ('yen', '円引き'),
                          ('percent', '％引き'),
                          ('free', '無料'),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  setSheet(() => discountUnit = entry.$1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: discountUnit == entry.$1
                                      ? colors.primary
                                      : colors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: discountUnit == entry.$1
                                        ? colors.primary
                                        : colors.surfaceBorder,
                                  ),
                                ),
                                child: Text(
                                  entry.$2,
                                  style: camillBodyStyle(
                                    13,
                                    discountUnit == entry.$1
                                        ? colors.fabIcon
                                        : colors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  child: discountUnit != 'free'
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: _labeledField(
                                label: discountUnit == 'percent'
                                    ? '割引率（%）'
                                    : '値引き額',
                                child: _numberInputField(
                                  ctrl: amtCtrl,
                                  colors: colors,
                                  prefix: discountUnit == 'percent' ? '%' : '¥',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        )
                      : const SizedBox(width: double.infinity),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _labeledField(
                    label: '有効期間',
                    child: Row(
                      children: [
                        Expanded(
                          child: ReceiptDatePickerField(
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
                          child: Text(
                            '〜',
                            style: camillBodyStyle(14, colors.textMuted),
                          ),
                        ),
                        Expanded(
                          child: ReceiptDatePickerField(
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
                          onTap: () => setSheet(
                            () => storageLocation = selected ? null : opt,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
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
                              opt,
                              style: camillBodyStyle(
                                13,
                                selected
                                    ? colors.fabIcon
                                    : colors.textSecondary,
                              ),
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
                    onSave(
                      CouponDetected(
                        description: desc,
                        discountAmount: discountUnit == 'free'
                            ? 0
                            : int.tryParse(amtCtrl.text) ?? 0,
                        discountUnit: discountUnit,
                        validFrom: _fmtCouponDate(validFrom),
                        validUntil: _fmtCouponDate(validUntil),
                        storageLocation: storageLocation,
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
      ),
    );
  }

  void _openItemSheet({
    required ReceiptItem item,
    required void Function(ReceiptItem) onSave,
    required VoidCallback? onDelete,
  }) {
    final colors = context.colors;
    const unknown = '不明';
    const unknownVariants = {'不明', '商品不明'};
    // コントローラーは空にして、現在の値をプレースホルダー（薄い文字）で表示
    // → タップ後すぐ入力できる（消去不要）
    final nameCtrl = TextEditingController();
    final nameHint = unknownVariants.contains(item.itemName)
        ? unknown
        : item.itemName;
    final amtCtrl = TextEditingController();
    final amtHint = item.amount > 0 ? item.amount.toString() : '0';
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _labeledField(
                  label: '品目名',
                  child: _textInputField(
                    ctrl: nameCtrl,
                    hint: nameHint,
                    colors: colors,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _labeledField(
                  label: '金額',
                  child: _numberInputField(
                    ctrl: amtCtrl,
                    hint: amtHint,
                    colors: colors,
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                        builder: (ctx2) => ReceiptCategoryPicker(
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
                  final name = nameCtrl.text.trim().isEmpty
                      ? nameHint
                      : nameCtrl.text.trim();
                  final amt = amtCtrl.text.trim().isEmpty
                      ? item.amount
                      : (int.tryParse(amtCtrl.text) ?? item.amount);
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

  // ── 請求金額編集 ───────────────────────────────────────────────
  Future<void> _editTotalAmount() async {
    final colors = context.colors;
    final ctrl = TextEditingController(text: _totalAmount.toString());
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
                  Icon(
                    Icons.description_outlined,
                    color: colors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '請求金額',
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
              child: _numberInputField(ctrl: ctrl, colors: colors),
            ),
            const SizedBox(height: 20),
            _saveButton(
              colors: colors,
              onPressed: () {
                setState(
                  () => _totalAmount = int.tryParse(ctrl.text) ?? _totalAmount,
                );
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 32),
          ],
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
                  Icon(
                    Icons.receipt_long_outlined,
                    color: colors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '内消費税等',
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
              child: _numberInputField(ctrl: ctrl, colors: colors),
            ),
            const SizedBox(height: 20),
            _saveButton(
              colors: colors,
              onPressed: () {
                setState(
                  () => _taxAmount = int.tryParse(ctrl.text) ?? _taxAmount,
                );
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
    String prefix = '¥',
    String hint = '0',
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
            prefix,
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
    super.build(context);
    final colors = context.colors;
    final purchasedAt = _purchasedAt;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
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
                ReceiptEditableInfoRow(
                  label: _isBill ? '支払先' : '店名',
                  value: _storeName,
                  icon: _isBill
                      ? Icons.account_balance_outlined
                      : Icons.store_outlined,
                  colors: colors,
                  onTap: _editStoreName,
                ),
                Divider(height: 20, color: colors.surfaceBorder),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position:
                          Tween(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            ),
                          ),
                      child: child,
                    ),
                  ),
                  child: ReceiptEditableInfoRow(
                    key: ValueKey(_isBill ? _billStatus : 'normal'),
                    label: _isBill
                        ? (_billStatus == 'paid' ? '支払日時' : '支払期限')
                        : (_isMedical ? '来院日時' : '購入日時'),
                    value: _isBill
                        ? (_billDueDate != null
                              ? DateFormat(
                                  'yyyy年M月d日',
                                ).format(_billDueDate!.toLocal())
                              : '未設定')
                        : (purchasedAt != null
                              ? (_isMedical &&
                                        purchasedAt.hour == 0 &&
                                        purchasedAt.minute == 0)
                                    ? DateFormat(
                                        'yyyy年M月d日',
                                      ).format(purchasedAt)
                                    : DateFormat(
                                        'yyyy年M月d日 HH:mm',
                                      ).format(purchasedAt)
                              : widget.analysis.purchasedAt),
                    icon: Icons.calendar_today_outlined,
                    colors: colors,
                    onTap: _isBill ? _editBillDueDate : _editDateTime,
                  ),
                ),
                if (!_isBill) ...[
                  Divider(height: 20, color: colors.surfaceBorder),
                  ReceiptEditableInfoRow(
                    label: '支払方法',
                    value:
                        AppConstants.paymentLabels[_paymentMethod] ??
                        _paymentMethod,
                    icon: Icons.payment_outlined,
                    colors: colors,
                    onTap: _editPaymentMethod,
                  ),
                ] else
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) => SizeTransition(
                      sizeFactor: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                      axisAlignment: -1,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: _billStatus == 'paid'
                        ? Column(
                            key: const ValueKey('paid'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Divider(height: 20, color: colors.surfaceBorder),
                              ReceiptEditableInfoRow(
                                label: '支払方法',
                                value:
                                    AppConstants
                                        .paymentLabels[_paymentMethod] ??
                                    _paymentMethod,
                                icon: Icons.payment_outlined,
                                colors: colors,
                                onTap: _editBillPaymentMethod,
                              ),
                            ],
                          )
                        : const SizedBox(
                            key: ValueKey('unpaid'),
                            width: double.infinity,
                          ),
                  ),
                if (!_isBill) ...[
                  Divider(height: 20, color: colors.surfaceBorder),
                  ReceiptEditableInfoRow(
                    label: 'カテゴリ',
                    value:
                        AppConstants.categoryLabels[_effectiveCategory] ??
                        (_effectiveCategory ?? '未設定'),
                    badge: _categoryIsAuto ? '自動' : null,
                    icon: Icons.label_outline,
                    colors: colors,
                    onTap: _editReceiptCategory,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── 品目リスト（請求書時は金額のみ表示）──
          if (_isBill)
            GestureDetector(
              onTap: _editTotalAmount,
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.surfaceBorder),
                ),
                padding: const EdgeInsets.all(16),
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
                    Row(
                      children: [
                        Text(
                          _fmt.format(_totalAmount),
                          style: camillAmountStyle(20, colors.textPrimary),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: colors.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
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
                  ..._buildGroupedItems(colors),
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
                    GestureDetector(
                      onTap: () => _editTax(),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 14,
                              color: colors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '内消費税等',
                              style: camillBodyStyle(13, colors.textMuted),
                            ),
                            const Spacer(),
                            Text(
                              _fmt.format(_taxAmount),
                              style: camillBodyStyle(
                                13,
                                colors.textMuted,
                                weight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: colors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  Divider(color: colors.surfaceBorder),
                  if (_isMedical) ...[
                    // 自由診療バッジ
                    if (_isUncovered) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.danger.withAlpha(18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colors.danger.withAlpha(80),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.money_off_outlined,
                              size: 14,
                              color: colors.danger,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '自由診療（保険外）',
                              style: camillBodyStyle(
                                12,
                                colors.danger,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '請求金額（保険外）',
                            style: camillBodyStyle(
                              14,
                              colors.textPrimary,
                              weight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _fmt.format(_totalAmount),
                            style: camillAmountStyle(18, colors.danger),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Text(
                            '合計',
                            style: camillBodyStyle(13, colors.textMuted),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_totalPoints点',
                            style: camillBodyStyle(
                              15,
                              colors.textPrimary,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '10割: ${_fmt.format(_totalPoints * 10)}',
                            style: camillBodyStyle(12, colors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '負担率',
                            style: camillBodyStyle(13, colors.textMuted),
                          ),
                          const Spacer(),
                          Text(
                            '${(_burdenRate * 10).round()}割負担',
                            style: camillBodyStyle(
                              13,
                              colors.textSecondary,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '実負担額',
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
          // ── 今回の節約額バッジ（割引適用があった場合のみ表示）──
          if (!_isBill && widget.analysis.savingsAmount > 0) ...[
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.success.withValues(alpha: 0.3),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.savings_outlined, size: 18, color: colors.success),
                  const SizedBox(width: 8),
                  Text(
                    '今回の節約',
                    style: camillBodyStyle(
                      13,
                      colors.success,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _fmt.format(widget.analysis.savingsAmount),
                    style: camillAmountStyle(16, colors.success),
                  ),
                ],
              ),
            ),
          ],
          // ── クーポン（医療時・請求書時は非表示）──
          if (!_isMedical && !_isBill) ...[
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
                    style: camillBodyStyle(
                      15,
                      colors.textPrimary,
                      weight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._coupons.asMap().entries.expand((e) {
                    final i = e.key;
                    final c = e.value;
                    final unit = c.discountUnit ?? 'yen';
                    final isFree = c.discountAmount == 0 && unit != 'other';
                    final isOther = unit == 'free';
                    final accentColor = isFree || isOther
                        ? const Color(0xFFD4A017)
                        : colors.primary;

                    String? periodText;
                    if (c.validFrom != null && c.validUntil != null) {
                      final f = DateTime.tryParse(c.validFrom!);
                      final u = DateTime.tryParse(c.validUntil!);
                      if (f != null && u != null) {
                        periodText =
                            '${f.month}/${f.day} 〜 ${u.month}/${u.day}';
                      }
                    } else if (c.validUntil != null) {
                      final u = DateTime.tryParse(c.validUntil!);
                      if (u != null) {
                        periodText = '〜 ${u.month}/${u.day}まで';
                      }
                    } else if (c.validFrom != null) {
                      final f = DateTime.tryParse(c.validFrom!);
                      if (f != null) {
                        periodText = '${f.month}/${f.day}〜';
                      }
                    }

                    return [
                      if (i > 0)
                        Divider(height: 16, color: colors.surfaceBorder),
                      ReceiptSwipeable(
                        onDelete: () => _deleteCoupon(i),
                        background: colors.surface,
                        child: GestureDetector(
                          onTap: () => _editCoupon(i),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: Checkbox(
                                        value: _couponIncluded[i],
                                        activeColor: colors.primary,
                                        visualDensity: VisualDensity.compact,
                                        onChanged: (v) => setState(
                                          () => _couponIncluded[i] = v ?? true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Row(
                                        children: [
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
                                              c.description.isEmpty
                                                  ? '（未入力）'
                                                  : c.description,
                                              style: camillBodyStyle(
                                                14,
                                                colors.textPrimary,
                                                weight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            isOther
                                                ? '無料'
                                                : isFree
                                                ? '無料'
                                                : unit == 'percent'
                                                ? '${c.discountAmount}%引き'
                                                : '${c.discountAmount}円引き',
                                            style: camillBodyStyle(
                                              13,
                                              accentColor,
                                              weight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.chevron_right,
                                            size: 16,
                                            color: colors.textMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (periodText != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 30,
                                      top: 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 11,
                                          color: colors.textMuted,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          periodText,
                                          style: camillBodyStyle(
                                            11,
                                            colors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 30,
                                    top: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      IntrinsicWidth(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: colors.surface,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: colors.surfaceBorder,
                                            ),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String?>(
                                              value: c.storageLocation,
                                              isDense: true,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              style: camillBodyStyle(
                                                11,
                                                colors.textSecondary,
                                              ),
                                              hint: Text(
                                                '保管場所',
                                                style: camillBodyStyle(
                                                  11,
                                                  colors.textMuted,
                                                ),
                                              ),
                                              icon: Icon(
                                                Icons.expand_more,
                                                size: 14,
                                                color: colors.textMuted,
                                              ),
                                              items: [
                                                DropdownMenuItem(
                                                  value: null,
                                                  child: Text(
                                                    '未選択',
                                                    style: camillBodyStyle(
                                                      11,
                                                      colors.textMuted,
                                                    ),
                                                  ),
                                                ),
                                                ..._storageOptions.map(
                                                  (opt) => DropdownMenuItem(
                                                    value: opt,
                                                    child: Text(
                                                      opt,
                                                      style: camillBodyStyle(
                                                        11,
                                                        colors.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              onChanged: (v) =>
                                                  _updateCouponStorage(i, v),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (!_isConvenienceStore(_storeName)) ...[
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => setState(
                                            () => _shareToComm[i] =
                                                !_shareToComm[i],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                              horizontal: 6,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _shareToComm[i]
                                                      ? Icons.people
                                                      : Icons.people_outline,
                                                  size: 14,
                                                  color: _shareToComm[i]
                                                      ? colors.primary
                                                      : colors.textMuted,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'コミュニティに公開',
                                                  style: camillBodyStyle(
                                                    11,
                                                    _shareToComm[i]
                                                        ? colors.primary
                                                        : colors.textMuted,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  _shareToComm[i]
                                                      ? Icons.check_circle
                                                      : Icons
                                                            .radio_button_unchecked,
                                                  size: 14,
                                                  color: _shareToComm[i]
                                                      ? colors.primary
                                                      : colors.textMuted,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                          Icon(
                            Icons.add_circle_outline,
                            size: 18,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'クーポンを追加',
                            style: camillBodyStyle(13, colors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isBill) ...[
            const SizedBox(height: 12),
            ReceiptBillSection(
              billStatus: _billStatus,
              colors: colors,
              onStatusChange: (s) => setState(() => _billStatus = s),
            ),
          ],
          const SizedBox(height: 12),
          // ── メモ ──
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
                Row(
                  children: [
                    Icon(
                      Icons.notes_outlined,
                      size: 16,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'メモ',
                      style: camillBodyStyle(
                        15,
                        colors.textPrimary,
                        weight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _memoCtrl,
                  focusNode: _memoFocus,
                  readOnly: !_memoEditing,
                  onTap: () {
                    if (!_memoEditing) {
                      setState(() => _memoEditing = true);
                      _memoFocus.requestFocus();
                    }
                  },
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── スワイプで削除できるラッパー ────────────────────────────────
