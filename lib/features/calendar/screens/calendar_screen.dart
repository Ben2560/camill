import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../features/bill/services/bill_service.dart';
import '../../../features/coupon/services/coupon_service.dart';
import '../../../features/receipt/services/receipt_service.dart';
import '../../../shared/models/bill_model.dart';
import '../../../shared/models/coupon_model.dart';
import '../../../shared/models/summary_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/top_notification.dart';
import '../widgets/calendar_bill_detail_sheet.dart';
import '../widgets/calendar_coupon_action_sheet.dart';
import '../widgets/calendar_day_panel.dart';
import '../widgets/calendar_receipt_detail_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.returnToTodayNotifier, this.refreshNotifier});

  final ValueNotifier<int>? returnToTodayNotifier;
  final ValueNotifier<int>? refreshNotifier;

  /// 外部（登録画面など）からカレンダーのbillリストを更新させるシグナル
  static final billRefreshSignal = ValueNotifier<int>(0);

  /// 外部（登録画面など）からカレンダーのサマリーを更新させるシグナル
  static final receiptRefreshSignal = ValueNotifier<int>(0);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  final _api = ApiService();
  final _receiptService = ReceiptService();
  final _couponService = CouponService();
  final _billService = BillService();
  final _fmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
  List<Bill> _bills = [];

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  MonthlySummary? _summary;
  DateTime? _summaryMonth; // _summary が何月のデータか
  bool _loading = true;
  Map<DateTime, int> _dailyTotals = {};
  List<Coupon> _coupons = [];

  // 日送りPageView
  static const int _kMiddlePage = 10000;
  late final PageController _dayPageController = PageController(initialPage: _kMiddlePage);
  final DateTime _baseDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  // カレンダータップ時のスライドアニメーション
  late final AnimationController _slideController;
  Offset _slideBegin = Offset.zero;

  // 年ビュー
  static const int _kBaseYear = 2000;
  static const int _kYearCount = 51; // 2000–2050
  bool _isYearView = false;
  bool _isReturningFromYearView = false; // 年→月の逆再生中フラグ
  int _yearViewYear = DateTime.now().year;
  late final AnimationController _transitionController;
  late ScrollController _yearScrollController;
  double _yearItemExtent = 400.0; // LayoutBuilder で更新される
  final GlobalKey _yearViewKey = GlobalKey();
  bool _pinchActive = false;
  final Map<String, MonthlySummary> _summaryCache = {};

  // PageView 高速スワイプ時に setState/haptic が連打されないよう debounce
  DateTime? _lastHapticDay;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _yearScrollController = ScrollController()
      ..addListener(_onYearScroll);
    _loadSummary(_focusedDay);
    _loadCoupons();
    _loadBills();
    widget.returnToTodayNotifier?.addListener(_onReturnToToday);
    widget.refreshNotifier?.addListener(_onRefresh);
    CalendarScreen.billRefreshSignal.addListener(_loadBills);
    CalendarScreen.receiptRefreshSignal.addListener(_onRefresh);
  }

  @override
  void dispose() {
    widget.returnToTodayNotifier?.removeListener(_onReturnToToday);
    widget.refreshNotifier?.removeListener(_onRefresh);
    CalendarScreen.billRefreshSignal.removeListener(_loadBills);
    CalendarScreen.receiptRefreshSignal.removeListener(_onRefresh);
    _transitionController.dispose();
    _slideController.dispose();
    _yearScrollController.dispose();
    _dayPageController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    _summaryCache.clear();
    _loadSummary(_focusedDay);
    _loadBills();
  }

  void _onReturnToToday() {
    final today = DateTime.now();
    if (_isYearView) {
      _tapMiniCalendar(today.year, today.month, Offset.zero).then((_) {
        if (mounted) _goToDay(today);
      });
    } else {
      _goToDay(today);
    }
  }

  void _goToDay(DateTime day) {
    // table_calendar は UTC で日付を返すのでローカルに正規化
    final d = DateTime(day.year, day.month, day.day);
    if (_selectedDay != null && isSameDay(d, _selectedDay!)) return;
    // スライド方向を決定（未来の日付→左から入る、過去の日付→右から入る）
    _slideBegin = (_selectedDay != null && d.isAfter(_selectedDay!))
        ? const Offset(1.0, 0.0)
        : const Offset(-1.0, 0.0);
    final needsReload =
        _summaryMonth == null ||
        d.month != _summaryMonth!.month ||
        d.year != _summaryMonth!.year;
    setState(() {
      _selectedDay = d;
      _focusedDay = d;
    });
    final diff = d.difference(_baseDate).inDays;
    _dayPageController.jumpToPage(_kMiddlePage + diff);
    _slideController.forward(from: 0.0);
    if (needsReload) _loadSummary(d);
  }

  Future<void> _loadCoupons() async {
    try {
      final coupons = await _couponService.fetchCoupons();
      if (mounted) setState(() => _coupons = coupons);
    } catch (e) {
      // ignore: avoid_print
      debugPrint('[Calendar] クーポン取得失敗: $e');
    }
  }

  Future<void> _loadBills() async {
    try {
      final bills = await _billService.fetchBills();
      if (mounted) setState(() => _bills = bills);
    } catch (e) {
      debugPrint('_loadBills failed: $e');
    }
  }

  List<Bill> _billsDueOnDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _bills.where((b) {
      if (b.dueDate == null) return false;
      if (b.status == BillStatus.paid) return false;
      final due = DateTime(b.dueDate!.year, b.dueDate!.month, b.dueDate!.day);
      return due == d;
    }).toList();
  }

  void _showBillDetailSheet(Bill bill) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CalendarBillDetailSheet(
        bill: bill,
        fmt: _fmt,
        colors: context.colors,
        onPaid: () async {
          // 楽観的更新：API 完了前にローカル状態を即座に反映
          final now = DateTime.now();
          final todayKey = DateTime(now.year, now.month, now.day);
          setState(() {
            _bills = _bills
                .map((b) => b.billId == bill.billId
                    ? b.copyWith(status: BillStatus.paid, paidAt: now)
                    : b)
                .toList();
            _dailyTotals[todayKey] =
                (_dailyTotals[todayKey] ?? 0) + bill.amount;
          });
          try {
            await _billService.payBill(bill.billId);
            // 成功時：サマリーキャッシュだけクリアして再取得（bills はローカル更新済み）
            _summaryCache.remove(DateFormat('yyyy-MM').format(_focusedDay));
            _summaryCache.remove(DateFormat('yyyy-MM').format(now));
            await _loadSummary(_focusedDay);
            if (mounted) {
              showTopNotification(context, '支払い済みにしました ✓');
            }
          } catch (_) {
            // 失敗時はサーバーから全再取得して楽観的更新を巻き戻す
            await _loadBills();
            _summaryCache.remove(DateFormat('yyyy-MM').format(_focusedDay));
            await _loadSummary(_focusedDay);
            if (mounted) {
              showTopNotification(context, '更新に失敗しました');
            }
          }
        },
        onMemoUpdated: (newMemo) {
          setState(() {
            _bills = _bills
                .map((b) => b.billId == bill.billId
                    ? b.copyWith(memo: newMemo)
                    : b)
                .toList();
          });
        },
      ),
    );
  }

  Future<void> _loadSummary(DateTime month) async {
    if (!mounted) return;
    final key = DateFormat('yyyy-MM').format(month);

    if (_summaryCache.containsKey(key)) {
      // キャッシュヒット時は setState を最小限に（_loading が true の場合だけ更新）
      final summary = _summaryCache[key]!;
      _summary = summary;
      _summaryMonth = DateTime(month.year, month.month);
      _dailyTotals = _buildDailyTotals(summary);
      if (_loading) setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    try {
      final data = await _api.get(
        '/summary/monthly',
        query: {'year_month': key},
      );
      final summary = MonthlySummary.fromJson(data);
      _summaryCache[key] = summary;
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _summaryMonth = DateTime(month.year, month.month);
        _dailyTotals = _buildDailyTotals(summary);
        _loading = false;
      });
      _prefetchAdjacent(month);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _prefetchAdjacent(DateTime month) {
    for (final offset in [-1, 1]) {
      final m = DateTime(month.year, month.month + offset);
      final key = DateFormat('yyyy-MM').format(m);
      if (!_summaryCache.containsKey(key)) {
        _api.get('/summary/monthly', query: {'year_month': key}).then((data) {
          _summaryCache[key] = MonthlySummary.fromJson(data);
        }).catchError((e) {
          // prefetch 失敗は無視（次回スクロール時に正規ロードが走る）
          debugPrint('[Calendar] prefetch $key 失敗: $e');
        });
      }
    }
  }

  Map<DateTime, int> _buildDailyTotals(MonthlySummary summary) {
    final Map<DateTime, int> totals = {};
    for (final r in summary.allReceipts) {
      final dt = DateTime.parse(r.purchasedAt).toLocal();
      final day = DateTime(dt.year, dt.month, dt.day);
      totals[day] = (totals[day] ?? 0) + r.totalAmount;
    }
    return totals;
  }

  // その日に有効なクーポンを返す共通ロジック
  List<({Coupon coupon, DateTime from, DateTime? until})> _validCouponsForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final result = <({Coupon coupon, DateTime from, DateTime? until})>[];
    for (final c in _coupons) {
      if (c.isUsed || c.isExpired) continue;
      if (c.validFrom == null && c.validUntil == null) continue;
      final rawFrom = c.validFrom ?? c.createdAt;
      final from = DateTime(rawFrom.year, rawFrom.month, rawFrom.day);
      final until = c.validUntil != null
          ? DateTime(c.validUntil!.year, c.validUntil!.month, c.validUntil!.day)
          : null;
      if (d.isBefore(from)) continue;
      if (until != null && d.isAfter(until)) continue;
      if (c.availableDays != null && c.availableDays!.isNotEmpty) {
        final dayIdx = d.weekday - 1; // 月=0 ... 日=6
        if (!c.availableDays!.contains(dayIdx)) continue;
      }
      result.add((coupon: c, from: from, until: until));
    }
    return result;
  }

  // その日に有効なクーポンとバーの左右キャップ情報を返す（最大2件）
  List<({Coupon coupon, bool isStart, bool isEnd})> _couponBarsForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _validCouponsForDay(day).take(2).map((e) => (
      coupon: e.coupon,
      isStart: d == e.from,
      isEnd: e.until != null && d == e.until,
    )).toList();
  }

  // その日に使えるクーポン一覧
  List<Coupon> _couponsForDay(DateTime day) =>
      _validCouponsForDay(day).map((e) => e.coupon).toList();

  List<RecentReceipt> _receiptsForDay(DateTime day) {
    if (_summary == null) return [];
    return _summary!.allReceipts.where((r) {
      final dt = DateTime.parse(r.purchasedAt).toLocal();
      return dt.year == day.year && dt.month == day.month && dt.day == day.day;
    }).toList();
  }

  void _showCouponSheet(Coupon coupon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CalendarCouponActionSheet(
        coupon: coupon,
        couponService: _couponService,
        onChanged: _loadCoupons,
      ),
    );
  }

  void _showReceiptDetail(RecentReceipt receipt) {
    // 支払済み請求書は bill 詳細シートを表示
    if (receipt.isBill && receipt.billId != null) {
      final bill = _bills.where((b) => b.billId == receipt.billId).firstOrNull;
      if (bill != null) {
        _showBillDetailSheet(bill);
        return;
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => CalendarReceiptDetailSheet(
        receiptId: receipt.receiptId,
        receiptService: _receiptService,
        fmt: _fmt,
        onDeleted: () {
          CalendarScreen.receiptRefreshSignal.value++;
        },
        onEdit: (receiptListItem, {bool focusMemo = false}) =>
            context.push('/receipt-edit', extra: (receipt: receiptListItem, focusMemo: focusMemo)),
      ),
    );
  }

  Widget _buildCell(
    DateTime day, {
    bool isToday = false,
    bool isSelected = false,
    bool isOutside = false,
    double rowH = 52.0,
  }) {
    final colors = context.colors;
    final key = DateTime(day.year, day.month, day.day);
    final amount = _dailyTotals[key];
    final bars = isOutside
        ? <({Coupon coupon, bool isStart, bool isEnd})>[]
        : _couponBarsForDay(day);
    final hasBillDue = !isOutside && _billsDueOnDay(day).isNotEmpty;

    Color textColor;
    BoxDecoration? decoration;

    if (isSelected) {
      textColor = Colors.white;
      decoration = BoxDecoration(color: colors.primary, shape: BoxShape.circle);
    } else if (isToday) {
      textColor = colors.primary;
      decoration = BoxDecoration(
        color: colors.primary.withAlpha(30),
        shape: BoxShape.circle,
      );
    } else if (isOutside) {
      textColor = colors.textMuted;
    } else {
      textColor = colors.textPrimary;
    }

    Color barColor(Coupon c) {
      if (c.isUsed || c.isExpired) return colors.textMuted.withAlpha(60);
      return colors.accent;
    }

    final activeBars = bars.take(2).toList();

    // table_calendar のセルは rowHeight 分の高さを与えるので
    // Stack(fit: StackFit.expand) で親の制約を完全に埋める
    // rowH に比例したサイズ計算
    // 日付円: rowH の 58%（最小24, 最大34）
    final circleSize = (rowH * 0.58).clamp(24.0, 34.0);
    // フォントサイズ: 円サイズの 43%（最小11, 最大14）
    final dateFontSize = (circleSize * 0.43).clamp(11.0, 14.0);
    // 金額バッジエリア: rowH の 24%（最小10, 最大14）
    final badgeAreaH = (rowH * 0.24).clamp(10.0, 14.0);
    // 金額フォント: バッジエリアの 75%（最小8, 最大10）
    final badgeFontSize = (badgeAreaH * 0.75).clamp(8.0, 10.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 日付・支出バッジ（縦中央）──
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: decoration,
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: camillBodyStyle(
                  dateFontSize,
                  textColor,
                  weight: isSelected || isToday
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
            SizedBox(
              height: badgeAreaH,
              child: amount != null && !isOutside
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryLight,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '¥${_formatShort(amount)}',
                          style: TextStyle(
                            fontSize: badgeFontSize,
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
        // ── 請求期限の赤ポチ ──
        if (hasBillDue)
          Positioned(
            top: (rowH * 0.10).clamp(4.0, 8.0),
            right: (rowH * 0.10).clamp(4.0, 8.0),
            child: Container(
              width: (rowH * 0.12).clamp(5.0, 7.0),
              height: (rowH * 0.12).clamp(5.0, 7.0),
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
            ),
          ),
        // ── クーポンバー（セル下部に Positioned で固定）──
        if (activeBars.isNotEmpty)
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: activeBars
                  .map(
                    (b) => Container(
                      height: 4,
                      margin: EdgeInsets.only(
                        top: activeBars.length > 1 ? 1 : 0,
                        left: b.isStart ? 5 : 0,
                        right: b.isEnd ? 5 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: barColor(b.coupon),
                        borderRadius: BorderRadius.horizontal(
                          left: b.isStart
                              ? const Radius.circular(3)
                              : Radius.zero,
                          right: b.isEnd
                              ? const Radius.circular(3)
                              : Radius.zero,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  String _formatShort(int amount) {
    if (amount >= 10000) return '${(amount / 10000).toStringAsFixed(1)}万';
    return amount.toString();
  }

  void _rebuildYearScrollController(double targetOffset) {
    _yearScrollController.removeListener(_onYearScroll);
    _yearScrollController.dispose();
    _yearScrollController = ScrollController(initialScrollOffset: targetOffset);
    _yearScrollController.addListener(_onYearScroll);
  }

  double _calcYearItemExtent() {
    final screenW = MediaQuery.sizeOf(context).width;
    final cellW = (screenW - 20 - 16) / 3;
    final cellH = cellW / 0.85;
    final gridH = 4 * cellH + 3 * 8.0;
    return 28.0 + gridH + 16.0;
  }

  void _enterYearView() {
    if (_isYearView) return;

    _yearItemExtent = _calcYearItemExtent();
    final targetOffset = (_focusedDay.year - _kBaseYear) * _yearItemExtent;
    _rebuildYearScrollController(targetOffset);

    setState(() {
      _yearViewYear = _focusedDay.year;
      _isYearView = true;
    });
  }

  void _onYearScroll() {
    // debugPrint('[onYearScroll] offset=${_yearScrollController.offset}');
    final idx =
        (_yearScrollController.offset / _yearItemExtent).round();
    final yr = (_kBaseYear + idx).clamp(
      _kBaseYear,
      _kBaseYear + _kYearCount - 1,
    );
    if (yr != _yearViewYear) setState(() => _yearViewYear = yr);
  }



  Future<void> _tapMiniCalendar(
    int year,
    int month,
    Offset globalTapPos,
  ) async {
    if (_transitionController.isAnimating) return;
    HapticFeedback.lightImpact();

    final now = DateTime.now();
    final isCurrentMonth = year == now.year && month == now.month;
    final targetDay = isCurrentMonth ? now.day : 1;
    setState(() {
      _focusedDay = DateTime(year, month, targetDay);
      _selectedDay = DateTime(year, month, targetDay);
      _isReturningFromYearView = true;
    });

    // _transitionController を逆再生（年→月）
    await _transitionController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );

    if (!mounted) return;
    setState(() {
      _isYearView = false;
      _isReturningFromYearView = false;
    });
    final targetDate = DateTime(year, month, targetDay);
    final diff = targetDate.difference(_baseDate).inDays;
    // PageView は setState 後のフレームで初めてツリーに現れるため
    // addPostFrameCallback でジャンプする
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _dayPageController.jumpToPage(_kMiddlePage + diff);
    });
    _loadSummary(DateTime(year, month));
  }

  Widget _buildAnimatedHeader(CamillColors colors) {
    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, _) {
        final p = _transitionController.value;
        final monthOpacity = (1.0 - p * 2.5).clamp(0.0, 1.0);
        final yearOpacity = ((p - 0.5) / 0.3).clamp(0.0, 1.0);
        final chevronOpacity = (1.0 - p * 3.3).clamp(0.0, 1.0);

        return SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 月ビュー用タイトル（年月）
              Opacity(
                opacity: monthOpacity,
                child: Text(
                  DateFormat('yyyy年M月').format(_focusedDay),
                  style: camillHeadingStyle(15, colors.textPrimary),
                ),
              ),
              // 年ビュー用タイトル（年のみ）
              Opacity(
                opacity: yearOpacity,
                child: Text(
                  '$_yearViewYear年',
                  style: camillHeadingStyle(15, colors.textPrimary),
                ),
              ),
              // 左シェブロン
              Positioned(
                left: 4,
                child: Opacity(
                  opacity: chevronOpacity,
                  child: IgnorePointer(
                    ignoring: p > 0.3,
                    child: IconButton(
                      icon: Icon(Icons.chevron_left, color: colors.textSecondary),
                      onPressed: () {
                        final prev = DateTime(
                          _focusedDay.year,
                          _focusedDay.month - 1,
                        );
                        setState(() => _focusedDay = prev);
                        _loadSummary(prev);
                      },
                    ),
                  ),
                ),
              ),
              // 右シェブロン
              Positioned(
                right: 44,
                child: Opacity(
                  opacity: chevronOpacity,
                  child: IgnorePointer(
                    ignoring: p > 0.3,
                    child: IconButton(
                      icon: Icon(Icons.chevron_right, color: colors.textSecondary),
                      onPressed: () {
                        final next = DateTime(
                          _focusedDay.year,
                          _focusedDay.month + 1,
                        );
                        setState(() => _focusedDay = next);
                        _loadSummary(next);
                      },
                    ),
                  ),
                ),
              ),
              // 年ビュー切替ボタン
              Positioned(
                right: 4,
                child: Opacity(
                  opacity: chevronOpacity,
                  child: IgnorePointer(
                    ignoring: p > 0.3,
                    child: IconButton(
                      icon: Icon(Icons.calendar_view_month, color: colors.textSecondary),
                      onPressed: () {
                        if (_isYearView || _transitionController.isAnimating) return;
                        // アニメーション開始前に ScrollController を準備
                        // （p > 0.15 で _buildYearView が使われるため）
                        _yearItemExtent = _calcYearItemExtent();
                        final targetOffset = (_focusedDay.year - _kBaseYear) * _yearItemExtent;
                        _rebuildYearScrollController(targetOffset);
                        _transitionController.animateTo(
                          1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ).then((_) {
                          if (mounted) _enterYearView();
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYearView(CamillColors colors) {
    return KeyedSubtree(
      key: const ValueKey('year-view'),
      child: Stack(
        key: _yearViewKey,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cellW = (w - 20 - 16) / 3; // h-pad=20, cross-spaces=16
              final cellH = cellW / 0.85;
              final gridH = 4 * cellH + 3 * 8.0;
              _yearItemExtent = 28.0 + gridH + 16.0; // label + grid + v-pad
              // debugPrint('[LayoutBuilder] maxWidth=$w, itemExtent=$_yearItemExtent');
              return ListView.builder(
                controller: _yearScrollController,
                itemCount: _kYearCount,
                itemExtent: _yearItemExtent,
                itemBuilder: (context, idx) =>
                    _buildYearSection(_kBaseYear + idx, colors),
              );
            },
          ),
          // ヘッダとの境目をなじませるグラデーション
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 40,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.background,
                      colors.background.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthContent(CamillColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 利用可能な高さから rowHeight を動的計算:
        //   曜日ヘッダー16px（table_calendar デフォルト）+ 最大6行 + 詳細パネル確保分
        //   小型端末（< 700px）では詳細パネルを 120px に緩め、大型端末では 180px 確保
        //   TableCalendar を SizedBox で囲み bounded constraints を与えることで
        //   _pageHeight タイミング競合によるオーバーフローを防止
        final minDetailH = constraints.maxHeight < 700 ? 120.0 : 180.0;
        final rowH = ((constraints.maxHeight - 16.0 - minDetailH) / 6)
            .clamp(40.0, 60.0);
        return ClipRect(child: _buildMonthColumn(colors, rowH));
      },
    );
  }

  Widget _buildMonthColumn(CamillColors colors, double rowH) {
    return Column(
      children: [
        SizedBox(
          // 16 = daysOfWeekHeight (table_calendar default)
          // bounded constraints で _pageHeight タイミング競合によるオーバーフローを防止
          height: rowH * 6 + 16.0,
          child: TableCalendar(
            headerVisible: false,
            shouldFillViewport: true,
            firstDay: DateTime(_kBaseYear, 1, 1),
            lastDay: DateTime(_kBaseYear + _kYearCount - 1, 12, 31),
            focusedDay: _focusedDay,
            rowHeight: rowH,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) => _goToDay(selected),
            onPageChanged: (focusedDay) {
              final now = DateTime.now();
              final isCurrentMonth = focusedDay.year == now.year && focusedDay.month == now.month;
              final targetDay = isCurrentMonth
                  ? DateTime(now.year, now.month, now.day)
                  : focusedDay;
              setState(() {
                _focusedDay = targetDay;
                _selectedDay = targetDay;
              });
              final localTarget = DateTime(targetDay.year, targetDay.month, targetDay.day);
              final diff = localTarget.difference(_baseDate).inDays;
              _dayPageController.jumpToPage(_kMiddlePage + diff);
              _loadSummary(targetDay);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: const BoxDecoration(),
              selectedDecoration: const BoxDecoration(),
              defaultTextStyle: const TextStyle(color: Colors.transparent),
              weekendTextStyle: const TextStyle(color: Colors.transparent),
              outsideTextStyle: const TextStyle(color: Colors.transparent),
              cellMargin: EdgeInsets.zero,
              cellPadding: EdgeInsets.zero,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: camillBodyStyle(12, colors.textMuted),
              weekendStyle: camillBodyStyle(12, colors.textSecondary),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (_, day, focused) => _buildCell(day, rowH: rowH),
              todayBuilder: (_, day, focused) =>
                  _buildCell(day, isToday: true, rowH: rowH),
              selectedBuilder: (_, day, focused) =>
                  _buildCell(day, isSelected: true, rowH: rowH),
              outsideBuilder: (_, day, focused) =>
                  _buildCell(day, isOutside: true, rowH: rowH),
            ),
          ),
        ),
        Expanded(
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _slideController,
              builder: (context, child) {
                final slide = Tween<Offset>(
                  begin: _slideBegin,
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideController,
                  curve: Curves.easeOut,
                ));
                return SlideTransition(position: slide, child: child);
              },
              child: Material(
                color: colors.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: PageView.builder(
              controller: _dayPageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                final newDay =
                    _baseDate.add(Duration(days: index - _kMiddlePage));
                // _goToDay から jumpToPage された場合は既に更新済み
                if (isSameDay(_selectedDay, newDay)) return;
                final needsReload = _summaryMonth == null ||
                    newDay.month != _summaryMonth!.month ||
                    newDay.year != _summaryMonth!.year;
                setState(() {
                  _selectedDay = newDay;
                  _focusedDay = newDay;
                });
                if (needsReload) _loadSummary(newDay);
                // 高速スワイプで haptic が連打されないよう、日付が変わったときだけ発火
                if (!isSameDay(_lastHapticDay, newDay)) {
                  _lastHapticDay = newDay;
                  HapticFeedback.selectionClick();
                }
              },
              itemBuilder: (context, index) {
                final day =
                    _baseDate.add(Duration(days: index - _kMiddlePage));
                return CalendarDayPanel(
                  day: day,
                  receipts: _receiptsForDay(day),
                  activeCoupons: _couponsForDay(day),
                  dueBills: _billsDueOnDay(day),
                  loading: _loading,
                  fmt: _fmt,
                  colors: colors,
                  onTapReceipt: _showReceiptDetail,
                  onTapCoupon: _showCouponSheet,
                  onTapBill: _showBillDetailSheet,
                );
              },
            ),
          ),
        ),
      ),
    ),
      ],
    );
  }

  Widget _buildYearSection(int year, CamillColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // debugPrint('[YearSection $year] constraints=$constraints');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                '$year年',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                ),
              ),
            ),
            Expanded(child: _buildYearGrid(year, colors)),
          ],
        );
      },
    );
  }

  Widget _buildYearGrid(int year, CamillColors colors) {
    final now = DateTime.now();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, i) {
        final month = i + 1;
        final isCurrentMonth = year == now.year && month == now.month;
        final isFocused =
            year == _focusedDay.year && month == _focusedDay.month;
        Offset? tapPos;
        return GestureDetector(
          onTapDown: (d) => tapPos = d.globalPosition,
          onTap: () => _tapMiniCalendar(year, month, tapPos ?? Offset.zero),
          child: _buildMiniCalendar(
            year,
            month,
            colors,
            isCurrentMonth: isCurrentMonth,
            isFocused: isFocused,
          ),
        );
      },
    );
  }


  Widget _buildMiniCalendar(
    int year,
    int month,
    CamillColors colors, {
    required bool isCurrentMonth,
    required bool isFocused,
  }) {
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // 日=0
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();
    const weekLabels = ['日', '月', '火', '水', '木', '金', '土'];

    // null = 空セル、int = 日付
    final cells = <int?>[
      ...List.filled(firstWeekday, null),
      ...List.generate(daysInMonth, (i) => i + 1),
    ];
    while (cells.length < 42) { cells.add(null); } // 常に6行
    final weeks = List.generate(6, (r) => cells.sublist(r * 7, r * 7 + 7));

    final labelColor = isCurrentMonth || isFocused
        ? colors.primary
        : colors.textPrimary;

    return Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
      decoration: BoxDecoration(
        color: isFocused ? colors.primary.withAlpha(18) : colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentMonth ? colors.primary : colors.surfaceBorder,
          width: isCurrentMonth ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 月ラベル
          Text(
            '$month月',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          // 曜日ヘッダー
          Row(
            children: weekLabels
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 6,
                          color: colors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 1),
          // 日付グリッド（6行固定）
          ...weeks.map(
            (week) => Expanded(
              child: Row(
                children: week
                    .map(
                      (day) => Expanded(
                        child: day == null
                            ? const SizedBox()
                            : _buildMiniDayCell(
                                day,
                                isToday: year == now.year &&
                                    month == now.month &&
                                    day == now.day,
                                colors: colors,
                              ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDayCell(
    int day, {
    required bool isToday,
    required CamillColors colors,
  }) {
    return Center(
      child: Container(
        width: 13,
        height: 13,
        decoration: isToday
            ? BoxDecoration(color: colors.primary, shape: BoxShape.circle)
            : null,
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 6.5,
            color: isToday ? Colors.white : colors.textPrimary,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final statusBarH = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: colors.background,
      resizeToAvoidBottomInset: false,
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, statusBarH + 15, 8, 4),
              child: Text(
                'カレンダー',
                style: camillBodyStyle(30, colors.textPrimary, weight: FontWeight.w800),
              ),
            ),
            // ── カスタムヘッダー（アニメーション付き）──
            _buildAnimatedHeader(colors),
            // ── 月ビュー / 年ビュー の切り替え ──
            Expanded(
              child: GestureDetector(
                onScaleStart: (d) {
                  if (d.pointerCount < 2 || _isYearView) return;
                  _pinchActive = true;
                  final screenW = MediaQuery.sizeOf(context).width;
                  final cellW = (screenW - 20 - 16) / 3;
                  final cellH = cellW / 0.85;
                  final gridH = 4 * cellH + 3 * 8.0;
                  _yearItemExtent = 28.0 + gridH + 16.0;
                  final targetOffset = (_focusedDay.year - _kBaseYear) * _yearItemExtent;
                  _yearScrollController.removeListener(_onYearScroll);
                  _yearScrollController.dispose();
                  _yearScrollController = ScrollController(
                    initialScrollOffset: targetOffset,
                  );
                  _yearScrollController.addListener(_onYearScroll);
                  _yearViewYear = _focusedDay.year;
                },
                onScaleUpdate: (d) {
                  if (!_pinchActive || d.pointerCount < 2) return;
                  final pinchIn = (1.0 - d.scale).clamp(0.0, double.infinity);
                  final progress = (pinchIn / 0.5).clamp(0.0, 1.0);
                  _transitionController.value = progress;
                },
                onScaleEnd: (d) {
                  if (!_pinchActive) return;
                  _pinchActive = false;
                  final p = _transitionController.value;
                  final velocity = d.velocity.pixelsPerSecond.distance;
                  final shouldCommit = p >= 0.6 || (p >= 0.3 && velocity > 800);
                  if (shouldCommit) {
                    // アニメーション開始前に ScrollController を準備
                    final screenW = MediaQuery.sizeOf(context).width;
                    final cellW = (screenW - 20 - 16) / 3;
                    final cellH = cellW / 0.85;
                    final gridH = 4 * cellH + 3 * 8.0;
                    _yearItemExtent = 28.0 + gridH + 16.0;
                    final targetOffset = (_focusedDay.year - _kBaseYear) * _yearItemExtent;
                    _yearScrollController.removeListener(_onYearScroll);
                    _yearScrollController.dispose();
                    _yearScrollController = ScrollController(
                      initialScrollOffset: targetOffset,
                    );
                    _yearScrollController.addListener(_onYearScroll);
                    _transitionController.animateTo(
                      1.0,
                      duration: Duration(milliseconds: (300 * (1.0 - p)).round().clamp(150, 300)),
                      curve: Curves.easeOut,
                    ).then((_) { if (mounted) _enterYearView(); });
                    HapticFeedback.mediumImpact();
                  } else {
                    _transitionController.animateTo(
                      0.0,
                      duration: Duration(milliseconds: (250 * p).round().clamp(100, 250)),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: AnimatedBuilder(
                animation: _transitionController,
                builder: (context, _) {
                  final p = _transitionController.value;

                  // ━━ 年ビュー表示中 or 逆再生中 ━━
                  // _buildYearView をツリーに残し続けることで、
                  // ウィジェット差し替えによるフラッシュを完全に防ぐ。
                  if (_isYearView || _isReturningFromYearView) {
                    final screenW = MediaQuery.sizeOf(context).width;
                    final availableH = MediaQuery.sizeOf(context).height
                        - kToolbarHeight
                        - MediaQuery.paddingOf(context).top
                        - 44.0;
                    final miniWidth = (screenW - 36) / 3;
                    final targetScale = miniWidth / screenW;
                    final col = (_focusedDay.month - 1) % 3;
                    final row = (_focusedDay.month - 1) ~/ 3;
                    final cellH = miniWidth / 0.85;
                    final targetX = 10.0 + col * (miniWidth + 8) + miniWidth / 2;
                    final targetY = 28.0 + 8.0 + row * (cellH + 8) + cellH / 2;
                    final centerX = screenW / 2;
                    final centerY = availableH / 2;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // 月ビュー（逆再生中のみフェードイン）
                        if (_isReturningFromYearView && p < 0.5)
                          Opacity(
                            key: const ValueKey('month-fade'),
                            opacity: (1.0 - p * 2.5).clamp(0.0, 1.0),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..translateByDouble(
                                  (targetX - centerX) * p,
                                  (targetY - centerY) * p,
                                  0.0,
                                  1.0,
                                )
                                ..scaleByDouble(
                                  1.0 - p * (1.0 - targetScale),
                                  1.0 - p * (1.0 - targetScale),
                                  1.0 - p * (1.0 - targetScale),
                                  1.0,
                                ),
                              child: IgnorePointer(
                                ignoring: p > 0.3,
                                child: _buildMonthContent(colors),
                              ),
                            ),
                          ),
                        // 年ビュー（常にツリーに存在、逆再生中はフェードアウト）
                        Opacity(
                          key: const ValueKey('year-fade'),
                          opacity: _isReturningFromYearView
                              ? p.clamp(0.0, 1.0)
                              : 1.0,
                          child: IgnorePointer(
                            ignoring: _isReturningFromYearView,
                            child: _buildYearView(colors),
                          ),
                        ),
                      ],
                    );
                  }

                  // ━━ 月ビュー表示中 or 順再生中（月→年）━━
                  final screenW = MediaQuery.sizeOf(context).width;
                  final availableH = MediaQuery.sizeOf(context).height
                      - kToolbarHeight
                      - MediaQuery.paddingOf(context).top
                      - 44.0;
                  final miniWidth = (screenW - 36) / 3;
                  final targetScale = miniWidth / screenW;
                  final col = (_focusedDay.month - 1) % 3;
                  final row = (_focusedDay.month - 1) ~/ 3;
                  final cellH = miniWidth / 0.85;
                  final targetX = 10.0 + col * (miniWidth + 8) + miniWidth / 2;
                  final targetY = 28.0 + 8.0 + row * (cellH + 8) + cellH / 2;
                  final centerX = screenW / 2;
                  final centerY = availableH / 2;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // ── 月ビュー ──
                      if (p < 0.5)
                        Opacity(
                          opacity: (1.0 - p * 2.5).clamp(0.0, 1.0),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..translateByDouble(
                                (targetX - centerX) * p,
                                (targetY - centerY) * p,
                                0.0,
                                1.0,
                              )
                              ..scaleByDouble(
                                1.0 - p * (1.0 - targetScale),
                                1.0 - p * (1.0 - targetScale),
                                1.0 - p * (1.0 - targetScale),
                                1.0,
                              ),
                            child: IgnorePointer(
                              ignoring: p > 0.3,
                              child: _buildMonthContent(colors),
                            ),
                          ),
                        ),
                      // ── 年グリッド（順再生用）──
                      if (p > 0.15)
                        Opacity(
                          opacity: ((p - 0.15) / 0.35).clamp(0.0, 1.0),
                          child: IgnorePointer(
                            ignoring: p < 0.7,
                            child: ColoredBox(
                              color: colors.background,
                              child: _buildYearView(colors),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          ],
        ),
    );
  }
}

// ── 日別明細パネル ─────────────────────────────────────────────
