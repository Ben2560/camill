import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services/user_prefs.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/coupon_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/notification_inbox.dart';
import '../../../shared/services/overseas_service.dart';
import '../../bill/services/bill_service.dart';
import '../../coupon/services/coupon_service.dart';
import '../../receipt/services/receipt_service.dart';
import '../../../shared/models/bill_model.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../widgets/home_bill_detail_sheet.dart';
import '../widgets/notification_inbox_sheet.dart';
import '../widgets/today_coupon_sheet.dart';
import '../widgets/home_month_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// 海外モード変更時に外部からリロードさせるシグナル
  static final overseasRefreshSignal = ValueNotifier<int>(0);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _now = DateTime(DateTime.now().year, DateTime.now().month);

  // データがある月だけナビゲーション可能にする
  final _receiptService = ReceiptService();
  List<DateTime> _availableMonths = [];
  int _monthsVersion = 0; // PageView 再構築用キー
  PageController _pageController = PageController();

  // プラン情報
  int _analysisLimit = 10;
  String _plan = 'free';

  // 今日使えるクーポン
  final _couponService = CouponService();
  List<Coupon> _todayCoupons = [];

  // 未払い請求書アラート
  final _billService = BillService();
  List<Bill> _upcomingBills = [];
  final _billBannerController = PageController();
  int _billBannerPage = 0;
  // 請求書一覧（直近5件・ハイライトウィジェット用）
  List<Bill> _recentBills = [];

  // 予算
  int _budget = 80000;
  static const _budgetKey = 'budget_monthly';

  // カテゴリ別予算
  Map<String, int> _categoryBudgets = {};

  // ホームレイアウト編集
  static const _allWidgetIds = [
    'budget',
    'category',
    'score',
    'compare',
    'recent',
    'tax',
    'bills',
    'family_management',
    'family_partner',
    'family_savings',
  ];
  static const _familyWidgetIds = {
    'family_management',
    'family_partner',
    'family_savings',
  };
  static const _defaultWidgetIds = [
    'budget',
    'category',
    'score',
    'compare',
    'recent',
    'tax',
    'bills',
  ];
  static const _layoutKey = 'home_layout';
  List<String> _homeWidgets = List.from(_defaultWidgetIds);
  bool _editMode = false;

  bool _weekStartsSunday = true; // true=日曜始まり, false=月曜始まり
  static const _weekStartKey = 'week_start_sunday';

  // 海外モード
  late final _overseasService = OverseasService(ApiService());
  bool _isOverseas = false;
  String _overseasCurrency = 'JPY';
  double _overseasRate = 1.0;

  // ナビゲーションオーバーレイ用
  final _navProgress = ValueNotifier<double>(0.0);

  // レシート保存後の自動リフレッシュ用
  GoRouterDelegate? _routerDelegate;
  String? _prevRoutePath;

  @override
  void initState() {
    super.initState();
    // 初期状態は今月のみ表示（APIレスポンス後に更新）
    _availableMonths = [_now];
    _pageController = PageController(initialPage: 0);
    _loadAvailableMonths();
    _loadBudget();
    _loadCategoryBudgets();
    _loadHomeLayout();
    _loadWeekStartPref();
    _loadBillingStatus();
    _loadTodayCoupons();
    _loadUpcomingBills();
    _loadRecentBills();
    _loadOverseasStatus();
    CalendarScreen.billRefreshSignal.addListener(_onBillChanged);
    HomeScreen.overseasRefreshSignal.addListener(_loadOverseasStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _routerDelegate = GoRouter.of(context).routerDelegate;
      _routerDelegate?.addListener(_onRouteChanged);
    });
  }

  @override
  void dispose() {
    CalendarScreen.billRefreshSignal.removeListener(_onBillChanged);
    HomeScreen.overseasRefreshSignal.removeListener(_loadOverseasStatus);
    _routerDelegate?.removeListener(_onRouteChanged);
    _pageController.dispose();
    _billBannerController.dispose();
    _navProgress.dispose();
    super.dispose();
  }

  void _onBillChanged() {
    if (!mounted) return;
    _loadUpcomingBills();
    _loadRecentBills();
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final path = _routerDelegate?.currentConfiguration.uri.path;
    if (path == '/' && _prevRoutePath != null && _prevRoutePath != '/') {
      _loadBillingStatus();
      _loadAvailableMonths();
      _loadUpcomingBills();
      _loadRecentBills();
      _loadOverseasStatus();
    }
    _prevRoutePath = path;
  }

  Future<void> _loadOverseasStatus() async {
    final isOverseas = await _overseasService.getIsOverseas();
    if (!mounted) return;
    if (!isOverseas) {
      setState(() {
        _isOverseas = false;
        _overseasCurrency = 'JPY';
        _overseasRate = 1.0;
      });
      return;
    }
    final currency = await _overseasService.getCurrentCurrency();
    if (!mounted) return;
    if (currency == 'JPY') {
      setState(() {
        _isOverseas = false;
        _overseasCurrency = 'JPY';
        _overseasRate = 1.0;
      });
      return;
    }
    final data = await _overseasService.fetchRates();
    final rates = data['rates'] as Map<String, dynamic>? ?? {};
    final entry = rates[currency] as Map<String, dynamic>?;
    final rate = (entry?['rate'] as num?)?.toDouble() ?? 1.0;
    if (!mounted) return;
    setState(() {
      _isOverseas = isOverseas;
      _overseasCurrency = currency;
      _overseasRate = rate;
    });
  }

  /// データがある月の一覧を取得して PageView を再構築
  Future<void> _loadAvailableMonths() async {
    try {
      final rawMonths = await _receiptService.getActiveMonths();
      final months = rawMonths.map((s) {
        final parts = s.split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]));
      }).toList();

      // 今月は常に含める
      if (!months.any((m) => m.year == _now.year && m.month == _now.month)) {
        months.add(_now);
      }
      months.sort((a, b) => a.compareTo(b));

      if (!mounted) return;

      // 月リストが変わっていなければ PageView を再構築しない
      final changed =
          months.length != _availableMonths.length ||
          !months.asMap().entries.every(
            (e) =>
                e.key < _availableMonths.length &&
                _availableMonths[e.key].year == e.value.year &&
                _availableMonths[e.key].month == e.value.month,
          );
      if (!changed) return;

      _pageController.dispose();
      setState(() {
        _availableMonths = months;
        _pageController = PageController(initialPage: months.length - 1);
        _monthsVersion++;
      });
    } catch (e) {
      debugPrint('_loadAvailableMonths error: $e');
      // API未実装・エラー時は今月のみ（初期状態のまま）
    }
  }

  DateTime _monthForPage(int page) => _availableMonths[page];

  Future<void> _loadTodayCoupons() async {
    try {
      final all = await _couponService.fetchCoupons(isUsed: false);
      if (!mounted) return;
      setState(() {
        _todayCoupons = all
            .where((c) => !c.isExpired && !c.isUsed && c.isUsableToday)
            .toList();
      });
    } catch (e) {
      debugPrint('_loadTodayCoupons error: $e');
    }
  }

  Future<void> _loadUpcomingBills() async {
    try {
      final bills = await _billService.fetchBills(status: 'unpaid');
      if (!mounted) return;
      setState(() {
        _upcomingBills = bills
            .where((b) => b.dueDate != null && (b.daysUntilDue ?? 1) >= 0)
            .toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      });
    } catch (e) {
      debugPrint('_loadUpcomingBills error: $e');
    }
  }

  Future<void> _loadRecentBills() async {
    try {
      final bills = await _billService.fetchBills();
      if (!mounted) return;
      bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _recentBills = bills.take(5).toList();
      });
    } catch (e) {
      debugPrint('_loadRecentBills error: $e');
    }
  }

  Future<void> _loadWeekStartPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final v = await UserPrefs.getBool(prefs, _weekStartKey);
    if (!mounted) return;
    setState(() => _weekStartsSunday = v ?? true);
  }

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final v = await UserPrefs.getInt(prefs, _budgetKey);
    if (!mounted) return;
    setState(() => _budget = v ?? 80000);
  }

  Future<void> _loadCategoryBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final budgets = <String, int>{};
    for (final key in HomeMonthPageState.categoryMeta.keys) {
      budgets[key] =
          (await UserPrefs.getInt(prefs, 'category_budget_$key')) ?? 0;
    }
    if (!mounted) return;
    setState(() => _categoryBudgets = budgets);
  }

  Future<void> _loadHomeLayout() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final saved = await UserPrefs.getStringList(prefs, _layoutKey);
    if (saved != null && saved.isNotEmpty) {
      final valid = saved.where(_allWidgetIds.contains).toList();
      if (valid.isNotEmpty) setState(() => _homeWidgets = valid);
    }
  }

  Future<void> _saveHomeLayout(List<String> layout) async {
    final prefs = await SharedPreferences.getInstance();
    await UserPrefs.setStringList(prefs, _layoutKey, layout);
  }

  Future<void> _saveBudget(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await UserPrefs.setInt(prefs, _budgetKey, value);
  }

  Future<void> _saveCategoryBudgets(Map<String, int> map) async {
    final prefs = await SharedPreferences.getInstance();
    for (final e in map.entries) {
      await UserPrefs.setInt(prefs, 'category_budget_${e.key}', e.value);
    }
  }

  Future<void> _loadBillingStatus() async {
    try {
      final api = ApiService();
      final data = await api.get('/billing/status');
      if (!mounted) return;
      final newPlan = data['plan'] as String? ?? 'free';
      setState(() {
        _analysisLimit = (data['analysis_limit'] as num?)?.toInt() ?? 10;
        _plan = newPlan;
        if (newPlan != 'family') {
          _homeWidgets = _homeWidgets
              .where((id) => !_familyWidgetIds.contains(id))
              .toList();
        }
      });
      if (newPlan != 'family') {
        _saveHomeLayout(_homeWidgets);
      }
    } catch (e) {
      debugPrint('_loadBillingStatus error: $e');
    }
  }

  // ── 今日使えるクーポンバナー（固定ヘッダー用） ──────────────────────────────

  String _expiryLabel(Coupon c) {
    final from = c.validFrom;
    final until = c.validUntil;
    if (from != null && until != null) {
      return '${from.month}/${from.day}〜${until.month}/${until.day}';
    }
    final days = c.daysUntilExpiry;
    if (days != null) return days == 0 ? '本日まで！' : '残り$days日';
    return '';
  }

  void _showNotificationInbox(BuildContext context) {
    final colors = context.colors;
    NotificationInbox().markAllRead();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => NotificationInboxSheet(colors: colors),
    );
  }

  void _showTodayCouponDetail(CamillColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TodayCouponSheet(
        coupons: _todayCoupons,
        colors: colors,
        onUsed: (coupon) async {
          Navigator.pop(context);
          try {
            await _couponService.useCoupon(coupon.couponId);
            _loadTodayCoupons();
          } catch (e) {
            debugPrint('useCoupon error: $e');
          }
        },
        onViewAll: () {
          Navigator.pop(context);
          context.push('/coupon-wallet');
        },
      ),
    );
  }

  Widget _buildTodayCouponBanner(CamillColors colors) {
    final allFree = _todayCoupons.every((c) => c.isFree);
    final decoration = allFree
        ? BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B6914), Color(0xFFD4A017), Color(0xFFFFD700)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withAlpha(60),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          )
        : BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.surfaceBorder),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withAlpha(30),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          );
    final iconColor = allFree ? Colors.white : colors.primary;
    final titleColor = allFree ? Colors.white : colors.textPrimary;
    final subtitleColor = allFree ? Colors.white70 : colors.textMuted;
    final chevronColor = allFree ? Colors.white70 : colors.textMuted;

    return GestureDetector(
      onTap: () => _showTodayCouponDetail(colors),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: decoration,
        child: Row(
          children: [
            Icon(Icons.local_offer_rounded, color: iconColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _todayCoupons.length == 1
                        ? _todayCoupons.first.description
                        : '${_todayCoupons.length}枚のクーポンが使えます',
                    style: camillBodyStyle(
                      14,
                      titleColor,
                      weight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_todayCoupons.length == 1
                      ? _todayCoupons.first.validUntil != null
                      : true) ...[
                    const SizedBox(height: 2),
                    Text(
                      _todayCoupons.length == 1
                          ? _expiryLabel(_todayCoupons.first)
                          : _todayCoupons
                                .map((c) => c.storeName)
                                .toSet()
                                .join('・'),
                      style: camillBodyStyle(11, subtitleColor),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: chevronColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBillAlertBanner(CamillColors colors) {
    // 緊急を先頭に、残りは期限順で並べる
    final urgent = _upcomingBills.where((b) => b.isUrgent).toList();
    final nonUrgent = _upcomingBills.where((b) => !b.isUrgent).toList();
    final displayBills = [...urgent, ...nonUrgent];
    final fmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    final hasMultiple = displayBills.length > 1;

    Widget buildCard(Bill bill) {
      final isUrgent = bill.isUrgent;
      final days = bill.daysUntilDue;
      String subtitle;
      if (days == 0) {
        subtitle = '本日が支払い期限です';
      } else if (days == 1) {
        subtitle = '明日が支払い期限です';
      } else {
        subtitle = 'あと$days日';
      }

      return GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => HomeBillDetailSheet(
              bill: bill,
              fmt: fmt,
              colors: colors,
              onPaid: () async {
                try {
                  await _billService.payBill(bill.billId);
                  _loadUpcomingBills();
                  _loadRecentBills();
                } catch (e) {
                  debugPrint('payBill error: $e');
                }
              },
              onMemoUpdated: (newMemo) {
                setState(() {
                  _upcomingBills = _upcomingBills
                      .map(
                        (b) => b.billId == bill.billId
                            ? b.copyWith(memo: newMemo)
                            : b,
                      )
                      .toList();
                  _recentBills = _recentBills
                      .map(
                        (b) => b.billId == bill.billId
                            ? b.copyWith(memo: newMemo)
                            : b,
                      )
                      .toList();
                });
              },
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isUrgent
                ? const Color(0xFFE57373).withAlpha(20)
                : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUrgent
                  ? const Color(0xFFE57373).withAlpha(100)
                  : colors.surfaceBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: (isUrgent ? const Color(0xFFE57373) : colors.primary)
                    .withAlpha(25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isUrgent
                    ? Icons.warning_amber_rounded
                    : Icons.receipt_long_outlined,
                color: isUrgent ? const Color(0xFFE57373) : colors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.title,
                      style: camillBodyStyle(
                        14,
                        colors.textPrimary,
                        weight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${fmt.format(bill.amount)}　$subtitle',
                      style: camillBodyStyle(
                        11,
                        isUrgent ? const Color(0xFFE57373) : colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasMultiple)
                Icon(Icons.chevron_right, size: 16, color: colors.textMuted),
            ],
          ),
        ),
      );
    }

    if (!hasMultiple) return buildCard(displayBills.first);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 60,
          child: PageView.builder(
            controller: _billBannerController,
            itemCount: displayBills.length,
            onPageChanged: (i) => setState(() => _billBannerPage = i),
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(
                right: i < displayBills.length - 1 ? 6 : 0,
              ),
              child: buildCard(displayBills[i]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(displayBills.length, (i) {
            final active = i == _billBannerPage;
            final isUrgent = displayBills[i].isUrgent;
            final dotColor = isUrgent
                ? const Color(0xFFE57373)
                : colors.primary;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? dotColor : dotColor.withAlpha(60),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNavOverlay(CamillColors colors, double statusBarH) {
    return ValueListenableBuilder<double>(
      valueListenable: _navProgress,
      builder: (context, progress, _) {
        if (progress <= 0.01) return const SizedBox.shrink();

        final navH = statusBarH + 52.0;
        const fadeH = 48.0; // nav下のフェード幅
        final totalH = navH + fadeH;
        final blur = 24.0 * progress;
        final bgAlpha = progress * 0.03;
        final contentOpacity = progress;

        return SizedBox(
          height: totalH,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: navH,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.navBackground.withValues(alpha: bgAlpha),
                        colors.navBackground.withValues(
                          alpha: (progress * 5).clamp(0.0, 0.95),
                        ),
                        colors.navBackground.withValues(alpha: 0.0),
                      ],
                      stops: [0.0, navH / totalH, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: statusBarH,
                left: 0,
                right: 0,
                height: 52,
                child: Opacity(
                  opacity: contentOpacity,
                  child: Center(
                    child: Text(
                      'ホーム',
                      style: camillBodyStyle(
                        17,
                        colors.textPrimary,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              if (_editMode)
                Positioned(
                  top: statusBarH,
                  right: 4,
                  height: 52,
                  child: Opacity(
                    opacity: contentOpacity,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() => _editMode = false);
                          _saveHomeLayout(_homeWidgets);
                        },
                        child: Text(
                          '完了',
                          style: camillBodyStyle(
                            14,
                            colors.primary,
                            weight: FontWeight.w600,
                          ),
                        ),
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

  // ── ヘッダー境目グラデーションブラー ────────────────────────────────────────
  // 上ほど濃く、下ほど薄くなるグラデーションブラーを複数レイヤーで実現
  Widget _buildHeaderBlurOverlay(CamillColors colors) {
    const height = 20.0;
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Colors.white, Colors.transparent],
        stops: [0.0, 0.5, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 全体（20px）: σ=3
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: const SizedBox.expand(),
              ),
            ),
            // 上位 13px: さらに σ=3 追加（合計 σ≈6）
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 13,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            // 上位 7px: さらに σ=3 追加（合計 σ≈9）
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 7,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            // 背景色グラデーション（上: 完全不透明 → 下: 透明）
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.background, colors.background.withAlpha(0)],
                  stops: const [0.0, 0.8],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusBarH = MediaQuery.of(context).padding.top;
    final screenW = MediaQuery.of(context).size.width;
    final maxScale = screenW > 600 ? 1.5 : 1.22;
    double sp(double base) =>
        (base * screenW / 390.0).clamp(base * 0.82, base * maxScale);
    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 固定ヘッダー：タイトル＋年月＋ベル ─────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(20, statusBarH + 10, 8, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<double>(
                        valueListenable: _navProgress,
                        builder: (ctx, progress, child) => Opacity(
                          opacity: (1.0 - progress).clamp(0.0, 1.0),
                          child: child,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ホーム',
                              style: camillBodyStyle(
                                sp(30),
                                colors.textPrimary,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _editMode
                            ? TextButton(
                                onPressed: () {
                                  setState(() => _editMode = false);
                                  _saveHomeLayout(_homeWidgets);
                                },
                                child: Text(
                                  '完了',
                                  style: camillBodyStyle(
                                    16,
                                    colors.primary,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : ValueListenableBuilder<int>(
                                valueListenable:
                                    NotificationInbox().unreadCount,
                                builder: (ctx, count, _) => Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        count > 0
                                            ? Icons.notifications
                                            : Icons.notifications_outlined,
                                        color: count > 0
                                            ? colors.primary
                                            : colors.textSecondary,
                                      ),
                                      onPressed: () =>
                                          _showNotificationInbox(context),
                                    ),
                                    if (count > 0)
                                      Positioned(
                                        right: 6,
                                        top: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.danger,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            count > 99 ? '99+' : '$count',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── PageView（コンテンツ部分） ────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    PageView.builder(
                      key: ValueKey(_monthsVersion),
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: _availableMonths.length,
                      onPageChanged: (_) => _navProgress.value = 0.0,
                      itemBuilder: (context, page) => HomeMonthPage(
                        key: ValueKey(_availableMonths[page]),
                        month: _monthForPage(page),
                        budget: _budget,
                        categoryBudgets: _categoryBudgets,
                        homeWidgets: _homeWidgets,
                        editMode: _editMode,
                        weekStartsSunday: _weekStartsSunday,
                        analysisLimit: _analysisLimit,
                        navProgress: _navProgress,
                        onBudgetChanged: (v) async {
                          setState(() => _budget = v);
                          await _saveBudget(v);
                        },
                        onCategoryBudgetsChanged: (m) async {
                          setState(() => _categoryBudgets = m);
                          await _saveCategoryBudgets(m);
                        },
                        onLayoutChanged: (l) {
                          setState(() => _homeWidgets = l);
                          _saveHomeLayout(l);
                        },
                        onEnterEditMode: () => setState(() => _editMode = true),
                        onExitEditMode: () {
                          setState(() => _editMode = false);
                          _saveHomeLayout(_homeWidgets);
                        },
                        couponBanner:
                            page == _availableMonths.length - 1 &&
                                _todayCoupons.isNotEmpty
                            ? _buildTodayCouponBanner(colors)
                            : null,
                        billBanner:
                            page == _availableMonths.length - 1 &&
                                _upcomingBills.isNotEmpty
                            ? _buildBillAlertBanner(colors)
                            : null,
                        recentBills: _recentBills,
                        plan: _plan,
                        isOverseas: _isOverseas,
                        overseasCurrency: _overseasCurrency,
                        overseasRate: _overseasRate,
                      ),
                    ),
                    // ── ヘッダー境目グラデーションブラー ──────────────
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: _buildHeaderBlurOverlay(colors),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ── nav overlay（スクロール時に浮かび上がる） ──────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildNavOverlay(colors, statusBarH),
          ),
        ],
      ),
    );
  }
}
