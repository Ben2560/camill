import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/constants.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../features/bill/services/bill_service.dart';
import '../../../features/coupon/services/coupon_service.dart';
import '../../../features/receipt/services/receipt_service.dart';
import '../../../shared/models/bill_model.dart';
import '../../../shared/models/coupon_model.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/summary_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/top_notification.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.returnToTodayNotifier, this.refreshNotifier});

  final ValueNotifier<int>? returnToTodayNotifier;
  final ValueNotifier<int>? refreshNotifier;

  /// 外部（登録画面など）からカレンダーのbillリストを更新させるシグナル
  static final billRefreshSignal = ValueNotifier<int>(0);

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
  }

  @override
  void dispose() {
    widget.returnToTodayNotifier?.removeListener(_onReturnToToday);
    widget.refreshNotifier?.removeListener(_onRefresh);
    CalendarScreen.billRefreshSignal.removeListener(_loadBills);
    _transitionController.dispose();
    _slideController.dispose();
    _yearScrollController.dispose();
    _dayPageController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    final key = DateFormat('yyyy-MM').format(_focusedDay);
    _summaryCache.remove(key);
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
    // スライド方向を決定（タップした方向へ動く：後の曜日→右へ動く=左から、前の曜日→左へ動く=右から）
    _slideBegin = (_selectedDay != null && d.weekday > _selectedDay!.weekday)
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
      print('[Calendar] クーポン取得失敗: $e');
    }
  }

  Future<void> _loadBills() async {
    try {
      final bills = await _billService.fetchBills();
      if (mounted) setState(() => _bills = bills);
    } catch (_) {}
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
      builder: (_) => _BillDetailSheet(
        bill: bill,
        fmt: _fmt,
        colors: context.colors,
        onPaid: () async {
          try {
            await _billService.payBill(bill.billId);
            await _loadBills();
          } catch (_) {}
        },
      ),
    );
  }

  Future<void> _loadSummary(DateTime month) async {
    if (!mounted) return;
    final key = DateFormat('yyyy-MM').format(month);

    if (_summaryCache.containsKey(key)) {
      final summary = _summaryCache[key]!;
      setState(() {
        _summary = summary;
        _summaryMonth = DateTime(month.year, month.month);
        _dailyTotals = _buildDailyTotals(summary);
        _loading = false;
      });
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
        }).catchError((_) {});
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

  // その日に有効なクーポンとバーの左右キャップ情報を返す（最大2件）
  List<({Coupon coupon, bool isStart, bool isEnd})> _couponBarsForDay(
    DateTime day,
  ) {
    final result = <({Coupon coupon, bool isStart, bool isEnd})>[];
    final d = DateTime(day.year, day.month, day.day);
    for (final c in _coupons) {
      // 使用済み・期限切れクーポンはバー表示しない
      if (c.isUsed || c.isExpired) continue;
      // 有効期間が全く不明なクーポンはバー表示しない
      if (c.validFrom == null && c.validUntil == null) continue;
      // validFrom が null の場合は createdAt を開始日として使う
      final rawFrom = c.validFrom ?? c.createdAt;
      final from = DateTime(rawFrom.year, rawFrom.month, rawFrom.day);
      final until = c.validUntil != null
          ? DateTime(c.validUntil!.year, c.validUntil!.month, c.validUntil!.day)
          : null;
      final afterFrom = !d.isBefore(from);
      final beforeUntil = until == null || !d.isAfter(until);
      if (afterFrom && beforeUntil) {
        if (c.availableDays != null && c.availableDays!.isNotEmpty) {
          final dayIdx = d.weekday - 1; // 月=0 ... 日=6
          if (!c.availableDays!.contains(dayIdx)) continue;
        }
        result.add((
          coupon: c,
          isStart: d == from,
          isEnd: until != null && d == until,
        ));
      }
      if (result.length >= 2) break;
    }
    return result;
  }

  // その日に使えるクーポン一覧
  List<Coupon> _couponsForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _coupons.where((c) {
      if (c.isUsed || c.isExpired) return false;
      // 有効期間が全く不明なクーポンは表示しない
      if (c.validFrom == null && c.validUntil == null) return false;
      // validFrom が null の場合は createdAt を開始日として使う
      final rawFrom = c.validFrom ?? c.createdAt;
      final from = DateTime(rawFrom.year, rawFrom.month, rawFrom.day);
      final until = c.validUntil != null
          ? DateTime(c.validUntil!.year, c.validUntil!.month, c.validUntil!.day)
          : null;
      final afterFrom = !d.isBefore(from);
      final beforeUntil = until == null || !d.isAfter(until);
      if (!afterFrom || !beforeUntil) return false;
      if (c.availableDays != null && c.availableDays!.isNotEmpty) {
        final dayIdx = d.weekday - 1; // 月=0 ... 日=6
        if (!c.availableDays!.contains(dayIdx)) return false;
      }
      return true;
    }).toList();
  }

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
      builder: (_) => _CouponActionSheet(
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
      builder: (_) => _ReceiptDetailSheet(
        receiptId: receipt.receiptId,
        receiptService: _receiptService,
        fmt: _fmt,
        onDeleted: () {
          final key = DateFormat('yyyy-MM').format(_focusedDay);
          _summaryCache.remove(key);
          _loadSummary(_focusedDay);
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
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 日付・支出バッジ（縦中央）──
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: decoration,
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: camillBodyStyle(
                  14,
                  textColor,
                  weight: isSelected || isToday
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
            SizedBox(
              height: 14,
              child: amount != null && !isOutside
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '¥${_formatShort(amount)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
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
            top: 6,
            right: 6,
            child: Container(
              width: 6,
              height: 6,
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

  void _enterYearView() {
    if (_isYearView) return;

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
        //   曜日ヘッダー28px + 最大6行 + 詳細パネル最低65px が収まるよう調整
        //   セルコンテンツ（32px日付+14px金額=46px）を下回らないよう 46 でクランプ
        final rowH = ((constraints.maxHeight - 28.0 - 65.0) / 6)
            .clamp(46.0, 72.0);
        return _buildMonthColumn(colors, rowH);
      },
    );
  }

  Widget _buildMonthColumn(CamillColors colors, double rowH) {
    return Column(
      children: [
        TableCalendar(
          headerVisible: false,
          firstDay: DateTime(_kBaseYear, 1, 1),
          lastDay: DateTime(_kBaseYear + _kYearCount - 1, 12, 31),
          focusedDay: _focusedDay,
          rowHeight: rowH,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selected, focused) => _goToDay(selected),
          onPageChanged: (focusedDay) {
            setState(() => _focusedDay = focusedDay);
            _loadSummary(focusedDay);
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
            defaultBuilder: (_, day, focused) => _buildCell(day),
            todayBuilder: (_, day, focused) =>
                _buildCell(day, isToday: true),
            selectedBuilder: (_, day, focused) =>
                _buildCell(day, isSelected: true),
            outsideBuilder: (_, day, focused) =>
                _buildCell(day, isOutside: true),
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
                HapticFeedback.selectionClick();
              },
              itemBuilder: (context, index) {
                final day =
                    _baseDate.add(Duration(days: index - _kMiddlePage));
                return _DetailPanel(
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
class _DetailPanel extends StatelessWidget {
  final DateTime day;
  final List<RecentReceipt> receipts;
  final List<Coupon> activeCoupons;
  final List<Bill> dueBills;
  final bool loading;
  final NumberFormat fmt;
  final CamillColors colors;
  final void Function(RecentReceipt) onTapReceipt;
  final void Function(Coupon) onTapCoupon;
  final void Function(Bill) onTapBill;

  const _DetailPanel({
    required this.day,
    required this.receipts,
    required this.activeCoupons,
    required this.dueBills,
    required this.loading,
    required this.fmt,
    required this.colors,
    required this.onTapReceipt,
    required this.onTapCoupon,
    required this.onTapBill,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final vPad = constraints.maxHeight < 80 ? 8.0 : 12.0;
        return _buildColumn(context, vPad);
      },
    );
  }

  Widget _buildColumn(BuildContext context, double vPad) {
    final total = receipts.fold(0, (s, r) => s + r.totalAmount);
    final weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    final weekdayLabel = weekdays[day.weekday % 7];

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, vPad, 16, vPad),
          child: Row(
            children: [
              // 日付バッジ
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: camillBodyStyle(
                        20,
                        colors.primary,
                        weight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      weekdayLabel,
                      style: TextStyle(
                        fontSize: 9,
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.month}月${day.day}日',
                    style: camillBodyStyle(
                      15,
                      colors.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$weekdayLabel曜日',
                    style: camillBodyStyle(12, colors.textMuted),
                  ),
                ],
              ),
              const Spacer(),
              if (receipts.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('合計', style: camillBodyStyle(10, colors.textMuted)),
                    Text(
                      fmt.format(total),
                      style: camillAmountStyle(15, colors.primary),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.surfaceBorder),
        if (loading)
          Padding(
            padding: const EdgeInsets.all(24),
            child: CircularProgressIndicator(color: colors.primary),
          )
        else
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── 使えるクーポン ──
                if (activeCoupons.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 14,
                          color: colors.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSameDay(day, DateTime.now())
                              ? '今日使えるクーポン'
                              : 'この日に使えるクーポン',
                          style: camillBodyStyle(
                            12,
                            colors.accent,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...activeCoupons.map((c) {
                    final isFree = c.discountAmount == 0;
                    String? expiryText;
                    if (c.validUntil != null) {
                      expiryText =
                          '〜${c.validUntil!.month}/${c.validUntil!.day}';
                    }
                    return GestureDetector(
                      onTap: () => onTapCoupon(c),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colors.accentLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colors.accent.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isFree
                                    ? Icons.card_giftcard_outlined
                                    : Icons.local_offer_outlined,
                                size: 15,
                                color: colors.accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.description,
                                      style: camillBodyStyle(
                                        13,
                                        colors.textPrimary,
                                        weight: FontWeight.w500,
                                      ),
                                    ),
                                    if (c.storeName.isNotEmpty)
                                      Text(
                                        c.storeName,
                                        style: camillBodyStyle(
                                          11,
                                          colors.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    isFree ? '無料' : '${c.discountAmount}円引き',
                                    style: camillBodyStyle(
                                      13,
                                      colors.accent,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  if (expiryText != null)
                                    Text(
                                      expiryText,
                                      style: camillBodyStyle(
                                        10,
                                        colors.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  Divider(height: 1, color: colors.surfaceBorder),
                ],
                // ── 請求期限の請求書 ──
                if (dueBills.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 14, color: Color(0xFFE53935)),
                        const SizedBox(width: 6),
                        Text(
                          '支払期限の請求書',
                          style: camillBodyStyle(12, const Color(0xFFE53935), weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: dueBills.map((b) {
                        final catColor = AppConstants.categoryColors[b.category] ?? const Color(0xFF90A4AE);
                        final catLabel = AppConstants.categoryLabels[b.category] ?? 'その他';
                        return GestureDetector(
                          onTap: () => onTapBill(b),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withAlpha(12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE53935).withAlpha(80)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.description_outlined, size: 18, color: Color(0xFFE53935)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(b.title, style: camillBodyStyle(14, colors.textPrimary, weight: FontWeight.w600)),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: catColor.withAlpha(30),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(catLabel, style: TextStyle(fontSize: 10, color: catColor, fontWeight: FontWeight.w600)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(fmt.format(b.amount), style: camillAmountStyle(14, const Color(0xFFE53935))),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right, size: 16, color: Color(0xFFE53935)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Divider(height: 1, color: colors.surfaceBorder),
                ],
                // ── レシート一覧 ──
                if (receipts.isEmpty && dueBills.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'この日の記録はありません',
                      style: camillBodyStyle(14, colors.textMuted),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Column(
                      children: receipts.map((r) {
                        final isFirst = receipts.first == r;
                        return Column(
                          children: [
                            if (!isFirst)
                              Divider(height: 1, color: colors.surfaceBorder),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: colors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.receipt_outlined,
                                    color: colors.primary, size: 20),
                              ),
                              title: Text(r.storeName,
                                  style: camillBodyStyle(
                                      14, colors.textPrimary)),
                              subtitle: () {
                                final dt = DateTime.parse(r.purchasedAt).toLocal();
                                if (dt.hour == 0 && dt.minute == 0) return null;
                                return Text(
                                  DateFormat('HH:mm').format(dt),
                                  style: camillBodyStyle(12, colors.textMuted),
                                );
                              }(),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(fmt.format(r.totalAmount),
                                      style: camillAmountStyle(
                                          14, colors.textPrimary)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right,
                                      size: 16, color: colors.textMuted),
                                ],
                              ),
                              onTap: () => onTapReceipt(r),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
      ],
    );
  }
}

// ── レシート詳細ボトムシート ───────────────────────────────────
class _ReceiptDetailSheet extends StatefulWidget {
  final String receiptId;
  final ReceiptService receiptService;
  final NumberFormat fmt;
  final VoidCallback onDeleted;
  final void Function(ReceiptListItem, {bool focusMemo}) onEdit;

  const _ReceiptDetailSheet({
    required this.receiptId,
    required this.receiptService,
    required this.fmt,
    required this.onDeleted,
    required this.onEdit,
  });

  @override
  State<_ReceiptDetailSheet> createState() => _ReceiptDetailSheetState();
}

class _ReceiptDetailSheetState extends State<_ReceiptDetailSheet> {
  Receipt? _receipt;
  bool _loading = true;
  bool _deleting = false;
  final _sheetController = DraggableScrollableController();
  bool _isClosing = false;
  double? _contentFraction; // コンテンツ高さから計算したスナップ先（null=未計算）

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
        // ハンドル28 + ヘッダー56 + 仕切り1 + 品目×50 + メモカード + フッター160
        final memoLines = (r.memo ?? '').split('\n').length;
        final memoH = r.memo != null && r.memo!.isNotEmpty
            ? 60.0 + memoLines * 20.0  // カードベース＋テキスト行
            : 60.0;                     // 「メモを追加」カード
        final totalH = 244.0 + r.items.length * 50.0 + memoH;
        final fraction = (totalH / screenH).clamp(0.40, 0.93);
        setState(() {
          _receipt = r;
          _loading = false;
          _contentFraction = fraction;
        });
        // 読み込み完了後、コンテンツ高さまで滑らかに展開
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
          style: camillBodyStyle(
            16,
            colors.textPrimary,
            weight: FontWeight.w700,
          ),
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
              style: camillBodyStyle(
                14,
                const Color(0xFFFF3B30),
                weight: FontWeight.w600,
              ),
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
        ? r.items.fold(0, (s, e) => s + e.unitPrice ~/ 10)
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

    // コンテンツ高さから算出したスナップ先（未計算時は0.93）
    // ValueKeyなし → didUpdateWidgetでmaxChildSize/snapSizesを動的更新（コントローラー再アタッチ不要）
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
        final decoration = BorderRadius.vertical(top: Radius.circular(24));
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
        // 時刻あり判定
        final purchasedAt = DateTime.parse(r.purchasedAt).toLocal();
        final hasTime = purchasedAt.hour != 0 || purchasedAt.minute != 0;
        final dateLabel = hasTime
            ? DateFormat('yyyy年M月d日 HH:mm').format(purchasedAt)
            : DateFormat('yyyy年M月d日').format(purchasedAt);

        // 合計行ウィジェット
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
          final subtotal = r.items.fold(0, (s, e) => s + e.amount);
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
              ],
            ),
          );
        }

        // フッターウィジェット（合計 + ボタン）
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
              // ── スクロール領域（全体を覆う） ──
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
                    // ── メモ（表示のみ・編集は「編集する」ボタンから）──
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
                    // フッター分のスペース（フッター高さ＋セーフエリア）
                    SliverToBoxAdapter(child: SizedBox(height: 160 + MediaQuery.of(context).padding.bottom)),
                  ],
                ),
              ),
              // ── 固定フッター：常にシート底部に固定 ──
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

// ── クーポン操作シート ─────────────────────────────────────────
class _CouponActionSheet extends StatefulWidget {
  final Coupon coupon;
  final CouponService couponService;
  final VoidCallback onChanged;

  const _CouponActionSheet({
    required this.coupon,
    required this.couponService,
    required this.onChanged,
  });

  @override
  State<_CouponActionSheet> createState() => _CouponActionSheetState();
}

class _CouponActionSheetState extends State<_CouponActionSheet> {
  bool _busy = false;

  Future<void> _markUsed() async {
    setState(() => _busy = true);
    try {
      await widget.couponService.useCoupon(widget.coupon.couponId);
      if (mounted) {
        Navigator.pop(context);
        widget.onChanged();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _delete() async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          '削除確認',
          style: camillBodyStyle(
            16,
            colors.textPrimary,
            weight: FontWeight.w700,
          ),
        ),
        content: Text(
          'このクーポンを削除しますか？',
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
              '削除',
              style: camillBodyStyle(
                14,
                colors.danger,
                weight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.couponService.deleteCoupon(widget.coupon.couponId);
      if (mounted) {
        Navigator.pop(context);
        widget.onChanged();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showTopNotification(context, '削除に失敗しました: $e');
      }
    }
  }

  Future<void> _showEditDialog() async {
    final colors = context.colors;
    final c = widget.coupon;
    final nameCtrl = TextEditingController(text: c.storeName);
    final descCtrl = TextEditingController(text: c.description);
    final amountCtrl = TextEditingController(text: c.discountAmount.toString());
    DateTime? validFrom = c.validFrom;
    DateTime? validUntil = c.validUntil;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'クーポンを編集',
            style: camillHeadingStyle(16, colors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: camillBodyStyle(14, colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: '店名',
                    labelStyle: camillBodyStyle(13, colors.textMuted),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  style: camillBodyStyle(14, colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: '内容',
                    labelStyle: camillBodyStyle(13, colors.textMuted),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: camillBodyStyle(14, colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: '割引額（円）※無料は0',
                    labelStyle: camillBodyStyle(13, colors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: validFrom ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDlg(() => validFrom = picked);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: colors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        validFrom != null
                            ? '開始: ${validFrom!.year}/${validFrom!.month}/${validFrom!.day}'
                            : '開始日を選択（任意）',
                        style: camillBodyStyle(13, colors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate:
                          validUntil ??
                          DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDlg(() => validUntil = picked);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 16,
                        color: colors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        validUntil != null
                            ? '有効期限: ${validUntil!.year}/${validUntil!.month}/${validUntil!.day}'
                            : '有効期限を選択（任意）',
                        style: camillBodyStyle(13, colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'キャンセル',
                style: camillBodyStyle(14, colors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await widget.couponService.deleteCoupon(c.couponId);
                  await widget.couponService.createCoupon(
                    storeName: nameCtrl.text,
                    description: descCtrl.text,
                    discountAmount: int.tryParse(amountCtrl.text) ?? 0,
                    validFrom: validFrom?.toIso8601String(),
                    validUntil: validUntil?.toIso8601String(),
                    isFromOcr: c.isFromOcr,
                    availableDays: c.availableDays,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    widget.onChanged();
                  }
                } catch (e) {
                  if (mounted) {
                    showTopNotification(context, '編集に失敗しました: $e');
                  }
                }
              },
              child: Text('保存', style: camillBodyStyle(14, colors.fabIcon)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final c = widget.coupon;
    final canUse = !c.isUsed && !c.isExpired;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textMuted.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.store_outlined,
                      size: 14,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      c.storeName,
                      style: camillBodyStyle(13, colors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  c.description,
                  style: camillBodyStyle(
                    16,
                    colors.textPrimary,
                    weight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  c.discountAmount > 0 ? '${c.discountAmount}円引き' : '無料',
                  style: camillAmountStyle(22, colors.accent),
                ),
                if (c.validUntil != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 13, color: colors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        c.validFrom != null
                            ? '${c.validFrom!.month}/${c.validFrom!.day}〜${c.validUntil!.month}/${c.validUntil!.day}'
                            : '〜${c.validUntil!.month}/${c.validUntil!.day}',
                        style: camillBodyStyle(12, colors.textMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                if (canUse)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _busy ? null : _markUsed,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                            ),
                      label: Text(
                        '使用済みにする',
                        style: camillBodyStyle(
                          16,
                          Colors.white,
                          weight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (canUse) const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: colors.surfaceBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _busy ? null : _showEditDialog,
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        label: Text(
                          '編集',
                          style: camillBodyStyle(14, colors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: colors.danger.withAlpha(120)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _busy ? null : _delete,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: colors.danger,
                        ),
                        label: Text(
                          '削除',
                          style: camillBodyStyle(14, colors.danger),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 請求書詳細ボトムシート ─────────────────────────────────────
class _BillDetailSheet extends StatelessWidget {
  final Bill bill;
  final NumberFormat fmt;
  final CamillColors colors;
  final VoidCallback onPaid;

  const _BillDetailSheet({
    required this.bill,
    required this.fmt,
    required this.colors,
    required this.onPaid,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = AppConstants.categoryColors[bill.category] ?? const Color(0xFF90A4AE);
    final catLabel = AppConstants.categoryLabels[bill.category] ?? 'その他';
    final days = bill.daysUntilDue;
    final urgent = bill.isUrgent;

    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 60,
        bottom: 0,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ハンドル
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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル行
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description_outlined, color: Color(0xFFE53935), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bill.title, style: camillBodyStyle(17, colors.textPrimary, weight: FontWeight.w700)),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: catColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(catLabel, style: TextStyle(fontSize: 11, color: catColor, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 金額
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('金額', style: camillBodyStyle(13, colors.textMuted)),
                      Text(fmt.format(bill.amount), style: camillAmountStyle(20, colors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 支払期限
                  if (bill.dueDate != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('支払期限', style: camillBodyStyle(13, colors.textMuted)),
                        Row(
                          children: [
                            if (urgent)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.warning_amber_outlined, size: 14, color: Color(0xFFE53935)),
                              ),
                            Text(
                              '${bill.dueDate!.year}/${bill.dueDate!.month}/${bill.dueDate!.day}',
                              style: camillBodyStyle(14, urgent ? const Color(0xFFE53935) : colors.textPrimary, weight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (days != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          days >= 0 ? '残り$days日' : '期限切れ',
                          style: camillBodyStyle(12, urgent ? const Color(0xFFE53935) : colors.textMuted),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                  // 支払ボタン
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onPaid();
                      },
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: Text('支払いました', style: camillBodyStyle(15, Colors.white, weight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
