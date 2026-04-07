import 'dart:ui' show ImageFilter;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/coupon_model.dart';
import '../../../shared/models/summary_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/camill_card.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../../bill/services/bill_service.dart';
import '../../coupon/services/coupon_service.dart';
import '../../receipt/services/receipt_service.dart';
import '../../../shared/models/bill_model.dart';
import '../../bill/screens/bill_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../receipt/screens/receipt_list_screen.dart';
import '../../../core/constants.dart';
import '../../data/screens/data_screen.dart';
import '../../reports/screens/report_screen.dart';
import 'category_budget_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  // プラン情報（アップグレードモーダル用）
  int _analysisLimit = 10;

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
  ];
  static const _layoutKey = 'home_layout';
  List<String> _homeWidgets = List.from(_allWidgetIds);
  bool _editMode = false;

  bool _weekStartsSunday = true; // true=日曜始まり, false=月曜始まり
  static const _weekStartKey = 'week_start_sunday';

  // ナビゲーションオーバーレイ用
  final _navProgress = ValueNotifier<double>(0.0);

  // レシート保存後の自動リフレッシュ用
  late final GoRouterDelegate _routerDelegate;
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
    CalendarScreen.billRefreshSignal.addListener(_onBillChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routerDelegate = GoRouter.of(context).routerDelegate;
      _routerDelegate.addListener(_onRouteChanged);
    });
  }

  @override
  void dispose() {
    CalendarScreen.billRefreshSignal.removeListener(_onBillChanged);
    _routerDelegate.removeListener(_onRouteChanged);
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
    final path = _routerDelegate.currentConfiguration.uri.path;
    if (path == '/' && _prevRoutePath != null && _prevRoutePath != '/') {
      _loadAvailableMonths();
      _loadUpcomingBills();
      _loadRecentBills();
    }
    _prevRoutePath = path;
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
    } catch (_) {
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
    } catch (_) {
      // ホーム画面なのでエラーは無視
    }
  }

  Future<void> _loadUpcomingBills() async {
    try {
      final bills = await _billService.fetchBills(status: 'unpaid');
      if (!mounted) return;
      setState(() {
        _upcomingBills = bills.where((b) => b.dueDate != null).toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      });
    } catch (_) {}
  }

  Future<void> _loadRecentBills() async {
    try {
      final bills = await _billService.fetchBills();
      if (!mounted) return;
      bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _recentBills = bills.take(5).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadWeekStartPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _weekStartsSunday = prefs.getBool(_weekStartKey) ?? true);
  }

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _budget = prefs.getInt(_budgetKey) ?? 80000);
  }

  static const _categoryMeta = <String, ({IconData icon, String label})>{
    'food': (icon: Icons.rice_bowl_outlined, label: '食費'),
    'dining_out': (icon: Icons.restaurant_outlined, label: '外食費'),
    'daily': (icon: Icons.shopping_basket_outlined, label: '日用品'),
    'transport': (icon: Icons.train_outlined, label: '交通費'),
    'clothing': (icon: Icons.checkroom_outlined, label: '衣服'),
    'social': (icon: Icons.people_outline, label: '交際費'),
    'hobby': (icon: Icons.sports_esports_outlined, label: '趣味'),
    'medical': (icon: Icons.local_hospital_outlined, label: '医療・健康'),
    'education': (icon: Icons.menu_book_outlined, label: '教育・書籍'),
    'utility': (icon: Icons.bolt_outlined, label: '光熱費'),
    'subscription': (icon: Icons.subscriptions_outlined, label: 'サブスク'),
    'other': (icon: Icons.more_horiz, label: 'その他雑費'),
  };

  Future<void> _loadCategoryBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final budgets = <String, int>{};
    for (final key in _categoryMeta.keys) {
      budgets[key] = prefs.getInt('category_budget_$key') ?? 0;
    }
    setState(() => _categoryBudgets = budgets);
  }

  Future<void> _loadHomeLayout() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final saved = prefs.getStringList(_layoutKey);
    if (saved != null && saved.isNotEmpty) {
      final valid = saved.where(_allWidgetIds.contains).toList();
      if (valid.isNotEmpty) setState(() => _homeWidgets = valid);
    }
  }

  Future<void> _saveHomeLayout(List<String> layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_layoutKey, layout);
  }

  Future<void> _saveBudget(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_budgetKey, value);
  }

  Future<void> _saveCategoryBudgets(Map<String, int> map) async {
    final prefs = await SharedPreferences.getInstance();
    for (final e in map.entries) {
      await prefs.setInt('category_budget_${e.key}', e.value);
    }
  }

  Future<void> _loadBillingStatus() async {
    try {
      final api = ApiService();
      final data = await api.get('/billing/status');
      if (!mounted) return;
      setState(() {
        _analysisLimit = (data['analysis_limit'] as num?)?.toInt() ?? 10;
      });
    } catch (_) {}
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

  void _showTodayCouponDetail(CamillColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TodayCouponSheet(
        coupons: _todayCoupons,
        colors: colors,
        onUsed: (coupon) async {
          Navigator.pop(context);
          try {
            await _couponService.useCoupon(coupon.couponId);
            _loadTodayCoupons();
          } catch (_) {}
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
                  if (_todayCoupons.first.validUntil != null) ...[
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
            builder: (_) => _HomeBillDetailSheet(
              bill: bill,
              fmt: fmt,
              colors: colors,
              onPaid: () async {
                try {
                  await _billService.payBill(bill.billId);
                  _loadUpcomingBills();
                  _loadRecentBills();
                } catch (_) {}
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
                                30,
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
                            : IconButton(
                                icon: Icon(
                                  Icons.notifications_outlined,
                                  color: colors.textSecondary,
                                ),
                                onPressed: () {},
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
                      itemBuilder: (context, page) => _HomeMonthPage(
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

// ── 月ごとのページウィジェット ────────────────────────────────────────────────

class _HomeMonthPage extends StatefulWidget {
  final DateTime month;
  final int budget;
  final Map<String, int> categoryBudgets;
  final List<String> homeWidgets;
  final bool editMode;
  final bool weekStartsSunday;
  final int analysisLimit;
  final ValueNotifier<double> navProgress;
  final void Function(int) onBudgetChanged;
  final void Function(Map<String, int>) onCategoryBudgetsChanged;
  final void Function(List<String>) onLayoutChanged;
  final VoidCallback onEnterEditMode;
  final VoidCallback onExitEditMode;
  final Widget? couponBanner;
  final Widget? billBanner;
  final List<Bill> recentBills;

  const _HomeMonthPage({
    super.key,
    required this.month,
    required this.budget,
    required this.categoryBudgets,
    required this.homeWidgets,
    required this.editMode,
    required this.weekStartsSunday,
    required this.analysisLimit,
    required this.navProgress,
    required this.onBudgetChanged,
    required this.onCategoryBudgetsChanged,
    required this.onLayoutChanged,
    required this.onEnterEditMode,
    required this.onExitEditMode,
    this.couponBanner,
    this.billBanner,
    this.recentBills = const [],
  });

  @override
  State<_HomeMonthPage> createState() => _HomeMonthPageState();
}

class _HomeMonthPageState extends State<_HomeMonthPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _api = ApiService();
  final _currencyFmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');

  MonthlySummary? _summary;
  bool _loading = true;
  int? _prevExpense;
  int _dotsVisible = 0;
  bool _isRefreshing = false;
  bool _ignoreUntilTop = false;
  bool _reachedFullPull = false;
  late final AnimationController _bounceController;

  int? _weekExpense;
  int? _yearExpense;
  int? _yearBillTotal;
  bool _weekLoading = false;
  bool _yearLoading = false;
  int _periodIndex = 1; // 0=週, 1=月, 2=年

  // 医療費非課税
  int? _monthMedicalExpense;
  int? _weekMedicalExpense;

  String? _selectedCategory;

  late final ScrollController _scrollController;
  late final GoRouterDelegate _routerDelegate;
  bool _wasScrollingBeforeTap = false;

  static const _allWidgetIds = [
    'budget',
    'category',
    'score',
    'compare',
    'recent',
    'tax',
    'bills',
  ];
  static const _widgetLabels = <String, ({String title, IconData icon})>{
    'budget': (title: '収支', icon: Icons.account_balance_wallet_outlined),
    'category': (title: '使いみち', icon: Icons.pie_chart_outline),
    'score': (title: 'やりくりスコア', icon: Icons.emoji_events_outlined),
    'compare': (title: '先月との比較', icon: Icons.compare_arrows),
    'recent': (title: '最近のレシート', icon: Icons.receipt_outlined),
    'tax': (title: '消費税', icon: Icons.account_balance_outlined),
    'bills': (title: '請求書', icon: Icons.receipt_long_outlined),
  };

  static const _categoryMeta = <String, ({IconData icon, String label})>{
    'food': (icon: Icons.rice_bowl_outlined, label: '食費'),
    'dining_out': (icon: Icons.restaurant_outlined, label: '外食費'),
    'daily': (icon: Icons.shopping_basket_outlined, label: '日用品'),
    'transport': (icon: Icons.train_outlined, label: '交通費'),
    'clothing': (icon: Icons.checkroom_outlined, label: '衣服'),
    'social': (icon: Icons.people_outline, label: '交際費'),
    'hobby': (icon: Icons.sports_esports_outlined, label: '趣味'),
    'medical': (icon: Icons.local_hospital_outlined, label: '医療・健康'),
    'education': (icon: Icons.menu_book_outlined, label: '教育・書籍'),
    'utility': (icon: Icons.bolt_outlined, label: '光熱費'),
    'subscription': (icon: Icons.subscriptions_outlined, label: 'サブスク'),
    'other': (icon: Icons.more_horiz, label: 'その他雑費'),
  };

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(); // 初期ロード中はドットをアニメーション
    _scrollController = ScrollController()
      ..addListener(() {
        const threshold = 100.0;
        final p = (_scrollController.offset / threshold).clamp(0.0, 1.0);
        widget.navProgress.value = p;
      });
    _load();
    CalendarScreen.receiptRefreshSignal.addListener(_onReceiptChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routerDelegate = GoRouter.of(context).routerDelegate;
      _routerDelegate.addListener(_onRouteChanged);
    });
  }

  @override
  void dispose() {
    CalendarScreen.receiptRefreshSignal.removeListener(_onReceiptChanged);
    _routerDelegate.removeListener(_onRouteChanged);
    _bounceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onReceiptChanged() {
    if (!mounted) return;
    _load(silent: true);
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final path = _routerDelegate.currentConfiguration.uri.path;
    if (path == '/') {
      _load(silent: true);
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _loading = true);
    try {
      final yearMonth = DateFormat('yyyy-MM').format(widget.month);
      final prevMonth = DateTime(widget.month.year, widget.month.month - 1);
      final prevYearMonth = DateFormat('yyyy-MM').format(prevMonth);

      final results = await Future.wait([
        _api.get('/summary/monthly', query: {'year_month': yearMonth}),
        _api.get('/summary/monthly', query: {'year_month': prevYearMonth}),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = MonthlySummary.fromJson(results[0]);
        _prevExpense = (results[1]['total_expense'] as num?)?.toInt() ?? 0;
        if (!silent) {
          _loading = false;
          if (!_isRefreshing) {
            _bounceController.stop();
            _bounceController.reset();
          }
        }
      });
      _loadMonthMedicalExpense();
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _summary = MonthlySummary(
            yearMonth: DateFormat('yyyy-MM').format(widget.month),
            totalExpense: 0,
            totalIncome: 0,
            score: 0,
            byCategory: [],
            recentReceipts: [],
            allReceipts: [],
          );
          _prevExpense = null;
          _loading = false;
          if (!_isRefreshing) {
            _bounceController.stop();
            _bounceController.reset();
          }
        });
      }
    }
  }

  void _startSilentRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _dotsVisible = 3;
      _ignoreUntilTop = true;
    });
    if (!_bounceController.isAnimating) _bounceController.repeat();
    await Future.wait<void>([
      _load(silent: true),
      Future<void>.delayed(const Duration(milliseconds: 1200)),
    ]);
    if (!mounted) return;
    _bounceController.stop();
    _bounceController.reset();
    setState(() {
      _isRefreshing = false;
      _dotsVisible = 0;
      _ignoreUntilTop = false;
      _reachedFullPull = false;
    });
  }

  Future<void> _loadMonthMedicalExpense() async {
    try {
      final yearMonth = DateFormat('yyyy-MM').format(widget.month);
      final data = await _api.get(
        '/receipts',
        query: {'year_month': yearMonth},
      );
      final list = (data['receipts'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final medical = list.fold<int>(0, (sum, r) {
        if (r['is_tax_exempt'] as bool? ?? false) {
          return sum + ((r['total_amount'] as num?)?.toInt() ?? 0);
        }
        return sum;
      });
      if (mounted) setState(() => _monthMedicalExpense = medical);
    } catch (_) {
      if (mounted) setState(() => _monthMedicalExpense = null);
    }
  }

  Future<void> _loadWeekExpense() async {
    if (!mounted) return;
    setState(() => _weekLoading = true);
    try {
      final yearMonth = DateFormat('yyyy-MM').format(DateTime.now());
      final data = await _api.get(
        '/receipts',
        query: {'year_month': yearMonth},
      );
      final list = (data['receipts'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final now = DateTime.now();
      final offsetDays = widget.weekStartsSunday
          ? now.weekday % 7
          : now.weekday - 1;
      final weekStart = DateTime(now.year, now.month, now.day - offsetDays);
      final weekEnd = weekStart.add(const Duration(days: 7));

      int total = 0;
      int medical = 0;
      for (final r in list) {
        final raw = r['purchased_at'] as String?;
        if (raw == null) continue;
        final date = DateTime.tryParse(raw);
        if (date == null) continue;
        final d = date.toLocal();
        if (!d.isBefore(weekStart) && d.isBefore(weekEnd)) {
          final amount = (r['total_amount'] as num?)?.toInt() ?? 0;
          total += amount;
          if (r['is_tax_exempt'] as bool? ?? false) medical += amount;
        }
      }

      if (mounted) {
        setState(() {
          _weekExpense = total;
          _weekMedicalExpense = medical;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _weekExpense = null;
          _weekMedicalExpense = null;
        });
      }
    } finally {
      if (mounted) setState(() => _weekLoading = false);
    }
  }

  Future<void> _loadYearExpense() async {
    if (!mounted) return;
    setState(() => _yearLoading = true);
    try {
      final year = widget.month.year;
      final futures = List.generate(12, (i) {
        final ym = DateFormat('yyyy-MM').format(DateTime(year, i + 1));
        return _api.get('/summary/monthly', query: {'year_month': ym});
      });
      final results = await Future.wait(futures);
      final total = results.fold<int>(
        0,
        (s, r) => s + ((r['total_expense'] as num?)?.toInt() ?? 0),
      );
      final billTotal = results.fold<int>(
        0,
        (s, r) => s + ((r['bill_total'] as num?)?.toInt() ?? 0),
      );
      if (mounted) {
        setState(() {
          _yearExpense = total;
          _yearBillTotal = billTotal;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _yearExpense = null;
          _yearBillTotal = null;
        });
      }
    } finally {
      if (mounted) setState(() => _yearLoading = false);
    }
  }

  void _loadCategoryBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final budgets = <String, int>{};
    for (final key in _categoryMeta.keys) {
      budgets[key] = prefs.getInt('category_budget_$key') ?? 0;
    }
    widget.onCategoryBudgetsChanged(budgets);
  }

  // ── セクションヘッダー ────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, CamillColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: camillBodyStyle(22, colors.textPrimary, weight: FontWeight.w800),
      ),
    );
  }

  // ── ウィジェット管理 ───────────────────────────────────────────────────────

  Widget _buildWidgetById(String id, CamillColors colors) {
    switch (id) {
      case 'budget':
        return _buildBudgetCard(colors);
      case 'category':
        return _buildCategorySummary(colors);
      case 'score':
        return _buildScoreCard(colors);
      case 'compare':
        return _buildCompareCard(colors);
      case 'recent':
        return _buildRecentReceipts(colors);
      case 'tax':
        return _buildTaxCard(colors);
      case 'bills':
        return _buildBillsCard(colors);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEditButton(CamillColors colors) {
    return Center(
      child: GestureDetector(
        onTap: widget.editMode ? widget.onExitEditMode : widget.onEnterEditMode,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.surfaceBorder),
          ),
          child: Text(
            widget.editMode ? '完了' : 'ホームを編集',
            style: camillBodyStyle(
              13,
              widget.editMode ? colors.primary : colors.textMuted,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddWidgetButton(CamillColors colors) {
    return GestureDetector(
      onTap: () => _showAddWidgetSheet(colors),
      child: Padding(
        padding: const EdgeInsets.only(top: 13, left: 13),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: colors.primaryLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.primary.withAlpha(80)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ウィジェットを追加',
                style: camillBodyStyle(
                  14,
                  colors.primary,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddWidgetSheet(CamillColors colors) {
    final hidden = _allWidgetIds
        .where((id) => !widget.homeWidgets.contains(id))
        .toList();
    if (hidden.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
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
            Text(
              'ウィジェットを追加',
              style: camillHeadingStyle(16, colors.textPrimary),
            ),
            const SizedBox(height: 8),
            ...hidden.map((id) {
              final meta = _widgetLabels[id]!;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(meta.icon, color: colors.primary, size: 22),
                ),
                title: Text(
                  meta.title,
                  style: camillBodyStyle(14, colors.textPrimary),
                ),
                trailing: GestureDetector(
                  onTap: () {
                    final newList = List<String>.from(widget.homeWidgets);
                    if (!newList.contains(id)) newList.add(id);
                    widget.onLayoutChanged(newList);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showCategorySheet(
    CamillColors colors,
    List<MapEntry<String, ({String label, IconData icon})>> availableCats,
    String? catKey,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
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
                'カテゴリ',
                style: camillBodyStyle(
                  17,
                  colors.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text('合計', style: camillBodyStyle(15, colors.textPrimary)),
              leading: Icon(
                catKey == null
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: catKey == null ? colors.primary : colors.textMuted,
              ),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedCategory = null);
              },
            ),
            ...availableCats.map(
              (e) => ListTile(
                title: Text(
                  e.value.label,
                  style: camillBodyStyle(15, colors.textPrimary),
                ),
                leading: Icon(
                  catKey == e.key
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: catKey == e.key ? colors.primary : colors.textMuted,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedCategory = e.key);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPeriodSheet(CamillColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
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
                '期間',
                style: camillBodyStyle(
                  17,
                  colors.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...['週', '月', '年'].asMap().entries.map(
              (e) => ListTile(
                title: Text(
                  e.value,
                  style: camillBodyStyle(15, colors.textPrimary),
                ),
                leading: Icon(
                  _periodIndex == e.key
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: _periodIndex == e.key
                      ? colors.primary
                      : colors.textMuted,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _periodIndex = e.key);
                  if (e.key == 0) _loadWeekExpense();
                  if (e.key == 2) _loadYearExpense();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void showUpgradeModal(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(Icons.lock_outline, size: 48, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              '今月の解析上限（${widget.analysisLimit}回）に達しました',
              style: camillHeadingStyle(16, colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'プロプランにアップグレードすると1日20回まで解析できます',
              style: camillBodyStyle(13, colors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  '1ヶ月無料で試す',
                  style: camillBodyStyle(
                    15,
                    colors.fabIcon,
                    weight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                '後で',
                style: camillBodyStyle(14, colors.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── カードビルダー群 ──────────────────────────────────────────────────────

  Widget _buildBudgetCard(CamillColors colors) {
    final cats = _summary!.byCategory;
    final totalExpense = _summary!.totalExpense;

    // 表示対象の支出・予算を期間とカテゴリに応じて決定
    final catKey = _periodIndex == 1 ? _selectedCategory : null;
    final int expense;
    final int budget;
    final String budgetLabel;

    if (_periodIndex == 0) {
      // 週
      expense = _weekExpense ?? 0;
      final daysInMonth = DateTime(
        widget.month.year,
        widget.month.month + 1,
        0,
      ).day;
      budget = (widget.budget * 7 / daysInMonth).round();
      budgetLabel = '週の予算';
    } else if (_periodIndex == 2) {
      // 年
      expense = _yearExpense ?? 0;
      budget = widget.budget * 12;
      budgetLabel = '年の予算';
    } else if (catKey == null) {
      expense = totalExpense;
      budget = widget.budget;
      budgetLabel = '月の予算';
    } else {
      final found = cats.where((c) => c.category == catKey);
      expense = found.isEmpty ? 0 : found.first.amount;
      budget = widget.categoryBudgets[catKey] ?? 0;
      budgetLabel = _categoryMeta[catKey]?.label ?? catKey;
    }

    final remaining = budget > 0 ? budget - expense : 0;
    final ratio = budget > 0 ? (expense / budget).clamp(0.0, 1.0) : 0.0;

    // カテゴリチップ用リスト（データがあるカテゴリのみ）
    final availableCats = _categoryMeta.entries
        .where((e) => cats.any((c) => c.category == e.key))
        .toList();

    final selectedLabel = catKey == null
        ? '合計'
        : (_categoryMeta[catKey]?.label ?? catKey);

    return OpenContainer(
      transitionType: ContainerTransitionType.fade,
      transitionDuration: const Duration(milliseconds: 400),
      closedColor: colors.surface,
      openColor: colors.background,
      closedElevation: 0,
      openElevation: 0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      tappable: false,
      openBuilder: (_, _) => const BalanceChartScreen(),
      closedBuilder: (_, openContainer) => GestureDetector(
        onTap: () {
          if (_wasScrollingBeforeTap) {
            _wasScrollingBeforeTap = false;
            return;
          }
          openContainer();
        },
        child: CamillCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル行
              Row(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 16,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '収支',
                        style: camillBodyStyle(
                          14,
                          colors.textPrimary,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // カテゴリフィルタ（月モードのみ）
                  if (_periodIndex == 1) ...[
                    GestureDetector(
                      onTap: () =>
                          _showCategorySheet(colors, availableCats, catKey),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.surfaceBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedLabel,
                              style: camillBodyStyle(12, colors.textPrimary),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 16,
                              color: colors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  // 期間フィルタ
                  GestureDetector(
                    onTap: () => _showPeriodSheet(colors),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.surfaceBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ['週', '月', '年'][_periodIndex],
                            style: camillBodyStyle(12, colors.textPrimary),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: colors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              const SizedBox(height: 14),
              // 週・年ロード中
              if ((_periodIndex == 0 && _weekLoading) ||
                  (_periodIndex == 2 && _yearLoading))
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    ),
                  ),
                )
              else
                // 支出内容
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              startDegreeOffset: -90,
                              sectionsSpace: 0,
                              centerSpaceRadius: 32,
                              sections: budget > 0
                                  ? [
                                      PieChartSectionData(
                                        value: ratio,
                                        color: ratio > 0.8
                                            ? colors.danger
                                            : colors.primary,
                                        radius: 18,
                                        showTitle: false,
                                      ),
                                      PieChartSectionData(
                                        value: 1 - ratio,
                                        color: colors.surfaceBorder,
                                        radius: 18,
                                        showTitle: false,
                                      ),
                                    ]
                                  : [
                                      PieChartSectionData(
                                        value: 1,
                                        color: colors.surfaceBorder,
                                        radius: 18,
                                        showTitle: false,
                                      ),
                                    ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                budget > 0 ? '残り' : '予算',
                                style: camillBodyStyle(8, colors.textMuted),
                              ),
                              Text(
                                budget > 0
                                    ? _currencyFmt
                                          .format(remaining > 0 ? remaining : 0)
                                          .replaceAll('¥', '')
                                    : '未設定',
                                style: camillAmountStyle(
                                  budget > 0 ? 11 : 9,
                                  remaining > 0
                                      ? colors.primary
                                      : colors.danger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currencyFmt.format(expense),
                            style: camillAmountStyle(28, colors.textPrimary),
                          ),
                          Text(
                            budget > 0
                                ? '/ ${_currencyFmt.format(budget)}'
                                : budgetLabel,
                            style: camillBodyStyle(13, colors.textMuted),
                          ),
                          if (budget > 0) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                backgroundColor: colors.surfaceBorder,
                                color: ratio > 0.8
                                    ? colors.danger
                                    : colors.primary,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              remaining > 0
                                  ? '残り ${_currencyFmt.format(remaining)}'
                                  : '超過 ${_currencyFmt.format(-remaining)}',
                              style: camillBodyStyle(
                                12,
                                remaining > 0
                                    ? colors.textMuted
                                    : colors.danger,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySummary(CamillColors colors) {
    final cats = _summary!.byCategory;
    // 予算カードと一致するよう totalExpense を使う
    final total = _summary!.totalExpense;
    final periodLabel = ['週', '月', '年'][_periodIndex];

    // 支出があるカテゴリの行（予算未設定でも表示）
    final rows =
        _categoryMeta.entries
            .map((e) {
              final found = cats.where((c) => c.category == e.key);
              final amount = found.isEmpty ? 0 : found.first.amount;
              return (key: e.key, meta: e.value, amount: amount);
            })
            .where((r) => r.amount > 0)
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    // 表示行の合計を計算し、差分を「その他」に含める
    final rowsTotal = rows.fold(0, (sum, r) => sum + r.amount);
    final otherAmount = total - rowsTotal;
    final otherMeta = _categoryMeta['other']!;

    return OpenContainer(
      transitionType: ContainerTransitionType.fade,
      transitionDuration: const Duration(milliseconds: 400),
      closedColor: colors.surface,
      openColor: colors.background,
      closedElevation: 0,
      openElevation: 0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      onClosed: (_) async {
        final prefs = await SharedPreferences.getInstance();
        final newBudget = prefs.getInt('budget_monthly') ?? 0;
        if (mounted) widget.onBudgetChanged(newBudget);
        _loadCategoryBudgets();
        _load(silent: true);
      },
      openBuilder: (_, _) => const CategoryBudgetScreen(),
      closedBuilder: (_, _) => CamillCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart_outline, size: 16, color: colors.primary),
                const SizedBox(width: 6),
                Text(
                  '使いみち ($periodLabel)',
                  style: camillBodyStyle(
                    14,
                    colors.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  _currencyFmt.format(total),
                  style: camillAmountStyle(14, colors.textMuted),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    if (_wasScrollingBeforeTap) {
                      _wasScrollingBeforeTap = false;
                      return;
                    }
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoryBudgetScreen(),
                      ),
                    );
                    final prefs = await SharedPreferences.getInstance();
                    final newBudget = prefs.getInt('budget_monthly') ?? 0;
                    if (mounted) widget.onBudgetChanged(newBudget);
                    _loadCategoryBudgets();
                    _load(silent: true);
                  },
                  child: Icon(Icons.tune, size: 18, color: colors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'まだデータがありません',
                    style: camillBodyStyle(13, colors.textMuted),
                  ),
                ),
              ),
            ...rows.map((r) {
              final budget = widget.categoryBudgets[r.key] ?? 0;
              final hasBudget = budget > 0;
              final ratio = hasBudget
                  ? (r.amount / budget).clamp(0.0, 1.0)
                  : (total > 0 ? r.amount / total : 0.0);
              final overBudget = hasBudget && r.amount > budget;
              final barColor = overBudget
                  ? const Color(0xFFFF3B30)
                  : colors.primary;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: overBudget
                            ? const Color(0x1AFF3B30)
                            : colors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        r.meta.icon,
                        color: overBudget
                            ? const Color(0xFFFF3B30)
                            : colors.primary,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                r.meta.label,
                                style: camillBodyStyle(13, colors.textPrimary),
                              ),
                              const Spacer(),
                              if (hasBudget) ...[
                                Text(
                                  _currencyFmt.format(r.amount),
                                  style: camillAmountStyle(
                                    12,
                                    overBudget
                                        ? const Color(0xFFFF3B30)
                                        : colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  ' / ${_currencyFmt.format(budget)}',
                                  style: camillBodyStyle(11, colors.textMuted),
                                ),
                              ] else
                                Text(
                                  _currencyFmt.format(r.amount),
                                  style: camillAmountStyle(
                                    13,
                                    colors.textPrimary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 3,
                              backgroundColor: colors.surfaceBorder,
                              color: barColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            // 予算未設定カテゴリの合計「その他」行（常に一番下）
            if (otherAmount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        otherMeta.icon,
                        color: colors.textMuted,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'その他雑費',
                                style: camillBodyStyle(13, colors.textMuted),
                              ),
                              const Spacer(),
                              Text(
                                _currencyFmt.format(otherAmount),
                                style: camillAmountStyle(13, colors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: total > 0
                                  ? (otherAmount / total).clamp(0.0, 1.0)
                                  : 0.0,
                              minHeight: 3,
                              backgroundColor: colors.surfaceBorder,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
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

  Widget _buildScoreCard(CamillColors colors) {
    final score = _summary?.score ?? 0;
    final hasBudget = widget.categoryBudgets.values.any((v) => v > 0);
    final scoreColor = score >= 80
        ? colors.success
        : score >= 60
        ? colors.primary
        : colors.danger;
    final message = !hasBudget
        ? '使いみちをタップして予算設定を行なってください！'
        : score >= 90
        ? 'すばらしいやりくりです！'
        : score >= 80
        ? '予算内に収まっています'
        : score >= 60
        ? 'もう少し抑えましょう'
        : '予算を見直しましょう';

    return OpenContainer(
      transitionType: ContainerTransitionType.fade,
      transitionDuration: const Duration(milliseconds: 400),
      closedColor: colors.surface,
      openColor: colors.background,
      closedElevation: 0,
      openElevation: 0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      openBuilder: (_, _) =>
          ReportScreen(year: widget.month.year, month: widget.month.month),
      closedBuilder: (_, _) => CamillCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: const Color(0xFFFFB300),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'やりくりスコア',
                  style: camillBodyStyle(
                    14,
                    colors.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 18, color: colors.textMuted),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$score', style: camillAmountStyle(52, scoreColor)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    ' 点',
                    style: camillBodyStyle(18, colors.textMuted),
                  ),
                ),
                const Spacer(),
                Text(message, style: camillBodyStyle(12, colors.textMuted)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: colors.surfaceBorder,
                color: scoreColor,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareCard(CamillColors colors) {
    final summary = _summary!;
    final prev = _prevExpense;
    final hasPrev = prev != null;
    final diff = hasPrev ? summary.totalExpense - prev : 0;
    final isOver = diff > 0;

    return CamillCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                '先月との比較',
                style: camillBodyStyle(
                  14,
                  colors.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('今月', style: camillBodyStyle(12, colors.textMuted)),
                    Text(
                      _currencyFmt.format(summary.totalExpense),
                      style: camillAmountStyle(18, colors.textPrimary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('先月', style: camillBodyStyle(12, colors.textMuted)),
                    hasPrev
                        ? Text(
                            _currencyFmt.format(prev),
                            style: camillAmountStyle(18, colors.textPrimary),
                          )
                        : Text(
                            '---',
                            style: camillAmountStyle(18, colors.textMuted),
                          ),
                  ],
                ),
              ),
              if (hasPrev && diff != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isOver
                        ? colors.danger.withAlpha(30)
                        : colors.success.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOver ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: isOver ? colors.danger : colors.success,
                      ),
                      Text(
                        _currencyFmt.format(diff.abs()),
                        style: camillAmountStyle(
                          13,
                          isOver ? colors.danger : colors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReceipts(CamillColors colors) {
    final receipts = _summary!.recentReceipts;
    if (receipts.isEmpty) {
      return CamillCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_outlined, size: 16, color: colors.primary),
                const SizedBox(width: 6),
                Text(
                  '最近のレシート',
                  style: camillBodyStyle(
                    14,
                    colors.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 36,
                    color: colors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'まだレシートがありません',
                    style: camillBodyStyle(13, colors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }
    return OpenContainer(
      transitionType: ContainerTransitionType.fade,
      transitionDuration: const Duration(milliseconds: 400),
      closedColor: colors.surface,
      openColor: colors.background,
      closedElevation: 0,
      openElevation: 0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      tappable: false,
      onClosed: (_) => _load(silent: true),
      openBuilder: (_, _) => const ReceiptListScreen(),
      closedBuilder: (_, openContainer) => GestureDetector(
        onTap: () {
          if (_wasScrollingBeforeTap) {
            _wasScrollingBeforeTap = false;
            return;
          }
          openContainer();
        },
        child: CamillCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_outlined,
                        size: 16,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '最近のレシート',
                        style: camillBodyStyle(
                          14,
                          colors.textPrimary,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.chevron_right, size: 18, color: colors.textMuted),
                ],
              ),
              ...receipts.map(
                (r) => Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_outlined,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      r.storeName,
                      style: camillBodyStyle(14, colors.textPrimary),
                    ),
                    subtitle: Text(
                      DateFormat(
                        'M月d日',
                      ).format(DateTime.parse(r.purchasedAt).toLocal()),
                      style: camillBodyStyle(12, colors.textMuted),
                    ),
                    trailing: Text(
                      _currencyFmt.format(r.totalAmount),
                      style: camillAmountStyle(14, colors.textPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaxCard(CamillColors colors) {
    final int expense;
    final bool isLoading;
    if (_periodIndex == 0) {
      expense = _weekExpense ?? 0;
      isLoading = _weekLoading;
    } else if (_periodIndex == 2) {
      expense = _yearExpense ?? 0;
      isLoading = _yearLoading;
    } else {
      expense = _summary?.totalExpense ?? 0;
      isLoading = _loading;
    }

    // 非課税分（医療費＋請求書）を除外してから消費税推定
    final int medicalExpense;
    final int billExpense;
    if (_periodIndex == 0) {
      medicalExpense = _weekMedicalExpense ?? 0;
      billExpense = 0; // 週次は receipts のみで計算済み（請求書含まず）
    } else if (_periodIndex == 1) {
      medicalExpense = _monthMedicalExpense ?? 0;
      billExpense = _summary?.billTotal ?? 0;
    } else {
      medicalExpense = 0; // 年間は個別レシート未取得のため除外なし
      billExpense = _yearBillTotal ?? 0;
    }
    final nonTaxable = medicalExpense + billExpense;
    final taxableExpense = (expense - nonTaxable).clamp(0, expense);
    // 消費税推定（税込み金額から逆算: 税額 = 税込 × 10/110）
    final estimatedTax = (taxableExpense * 10 / 110).round();

    return CamillCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_outlined,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '消費税',
                style: camillBodyStyle(
                  14,
                  colors.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showPeriodSheet(colors),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ['週', '月', '年'][_periodIndex],
                        style: camillBodyStyle(12, colors.textPrimary),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 16,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                ),
              ),
            )
          else ...[
            Text(
              _currencyFmt.format(estimatedTax),
              style: camillAmountStyle(28, colors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              '※ 推定値のため確定ではありません',
              style: camillBodyStyle(11, colors.textMuted),
            ),
            const SizedBox(height: 8),
            // 内訳
            if (medicalExpense > 0) ...[
              _TaxBreakdownRow(
                label: '非課税（医療・介護・教育）',
                amount: medicalExpense,
                colors: colors,
                fmt: _currencyFmt,
              ),
              const SizedBox(height: 4),
            ],
            if (billExpense > 0) ...[
              _TaxBreakdownRow(
                label: '非課税（公共料金・税金等）',
                amount: billExpense,
                colors: colors,
                fmt: _currencyFmt,
              ),
              const SizedBox(height: 4),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBillsCard(CamillColors colors) {
    final bills = widget.recentBills;
    if (bills.isEmpty) return const SizedBox.shrink();
    final fmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    return OpenContainer(
      transitionType: ContainerTransitionType.fade,
      transitionDuration: const Duration(milliseconds: 400),
      closedColor: colors.surface,
      openColor: colors.background,
      closedElevation: 0,
      openElevation: 0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      tappable: false,
      onClosed: (_) => _load(silent: true),
      openBuilder: (_, _) => const BillScreen(),
      closedBuilder: (_, openContainer) => GestureDetector(
        onTap: () {
          if (_wasScrollingBeforeTap) {
            _wasScrollingBeforeTap = false;
            return;
          }
          openContainer();
        },
        child: CamillCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: colors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '請求書',
                          style: camillBodyStyle(
                            14,
                            colors.textPrimary,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.surfaceBorder),
              ...List.generate(bills.length, (i) {
                return _buildBillRow(
                  bills[i],
                  colors,
                  fmt,
                  i == bills.length - 1,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillRow(
    Bill bill,
    CamillColors colors,
    NumberFormat fmt,
    bool isLast,
  ) {
    final isPaid = bill.status == BillStatus.paid;
    final days = bill.daysUntilDue;

    String statusLabel;
    Color statusColor;
    if (isPaid) {
      statusLabel = '支払済';
      statusColor = const Color(0xFF4CAF50);
    } else if (days == null) {
      statusLabel = '未払い';
      statusColor = colors.textMuted;
    } else if (days < 0) {
      statusLabel = '期限切れ';
      statusColor = const Color(0xFFE57373);
    } else if (days == 0) {
      statusLabel = '本日まで';
      statusColor = const Color(0xFFE57373);
    } else if (days <= 3) {
      statusLabel = 'あと$days日';
      statusColor = const Color(0xFFE57373);
    } else {
      statusLabel = 'あと$days日';
      statusColor = colors.textMuted;
    }

    final dotColor = isPaid
        ? const Color(0xFF4CAF50)
        : bill.isUrgent
        ? const Color(0xFFE57373)
        : colors.textMuted.withAlpha(150);

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 12, 0, isLast ? 0 : 0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bill.title,
                  style: camillBodyStyle(
                    13,
                    isPaid ? colors.textMuted : colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                fmt.format(bill.amount),
                style: camillBodyStyle(
                  13,
                  isPaid ? colors.textMuted : colors.textPrimary,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Divider(height: 1, color: colors.surfaceBorder),
            ),
        ],
      ),
    );
  }

  @override
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.colors;

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (_isRefreshing) return false;
            if (notification is ScrollUpdateNotification) {
              final pixels = notification.metrics.pixels;
              if (pixels >= 0) {
                _ignoreUntilTop = false;
                _reachedFullPull = false;
              }
              if (_ignoreUntilTop) return false;
              if (pixels < 0) {
                final newDots = pixels < -85
                    ? 3
                    : pixels < -55
                    ? 2
                    : pixels < -25
                    ? 1
                    : 0;
                if (newDots == 3) _reachedFullPull = true;
                if (newDots != _dotsVisible) {
                  setState(() => _dotsVisible = newDots);
                }
                // 指を離した（dragDetails == null）かつ閾値到達済み → リフレッシュ発火
                if (_reachedFullPull && notification.dragDetails == null) {
                  _reachedFullPull = false;
                  _startSilentRefresh();
                }
              } else if (_dotsVisible > 0) {
                _ignoreUntilTop = true;
                _reachedFullPull = false;
                setState(() => _dotsVisible = 0);
              }
            } else if (notification is ScrollEndNotification) {
              if (!_isRefreshing) {
                if (_dotsVisible > 0) {
                  _ignoreUntilTop = true;
                  _reachedFullPull = false;
                  setState(() => _dotsVisible = 0);
                }
              }
            }
            return false;
          },
          child: Listener(
            onPointerDown: (_) {
              _wasScrollingBeforeTap =
                  _scrollController.hasClients &&
                  _scrollController.position.isScrollingNotifier.value;
            },
            behavior: HitTestBehavior.translucent,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const RefreshScrollPhysics(),
              slivers: [
                // リフレッシュ中に展開するスペーサー（コンテンツを 60px 押し下げる）
                SliverToBoxAdapter(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: SizedBox(
                      height: (_isRefreshing || _loading) ? 60.0 : 0.0,
                    ),
                  ),
                ),
                if (_summary != null) ...[
                  if (widget.billBanner != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: _buildSectionHeader('未払い請求書', colors),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: widget.billBanner,
                      ),
                    ),
                  ],
                  if (widget.couponBanner != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: _buildSectionHeader('今日使えるクーポン', colors),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: widget.couponBanner,
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 20,
                        bottom: 12,
                        left: 31.5,
                        right: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'ハイライト',
                            style: camillBodyStyle(
                              26,
                              colors.textPrimary,
                              weight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('yyyy年M月').format(widget.month),
                            style: camillBodyStyle(
                              14,
                              colors.textSecondary,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverReorderableList(
                      proxyDecorator: (child, index, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            final scale =
                                1.0 +
                                0.04 *
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOut,
                                    ).value;
                            return Transform.scale(
                              scale: scale,
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                elevation: 16 * animation.value,
                                shadowColor: Colors.black45,
                                child: Opacity(opacity: 0.92, child: child),
                              ),
                            );
                          },
                          child: child,
                        );
                      },
                      itemCount: widget.homeWidgets.length,
                      itemBuilder: (context, index) {
                        final id = widget.homeWidgets[index];
                        final card = _buildWidgetById(id, colors);
                        return Padding(
                          key: ValueKey(id),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Stack(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                                padding: widget.editMode
                                    ? const EdgeInsets.only(top: 13, left: 13)
                                    : EdgeInsets.zero,
                                child: widget.editMode
                                    ? ReorderableDelayedDragStartListener(
                                        index: index,
                                        child: card,
                                      )
                                    : card,
                              ),
                              if (widget.editMode)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      final newList = List<String>.from(
                                        widget.homeWidgets,
                                      );
                                      newList.remove(id);
                                      widget.onLayoutChanged(newList);
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF3B30),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.remove,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                      onReorderStart: (_) => HapticFeedback.mediumImpact(),
                      onReorder: (oldIndex, newIndex) {
                        HapticFeedback.selectionClick();
                        final newList = List<String>.from(widget.homeWidgets);
                        if (newIndex > oldIndex) newIndex--;
                        final item = newList.removeAt(oldIndex);
                        newList.insert(newIndex, item);
                        widget.onLayoutChanged(newList);
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      child: Column(
                        children: [
                          if (widget.editMode &&
                              widget.homeWidgets.length <
                                  _allWidgetIds.length) ...[
                            _buildAddWidgetButton(colors),
                            const SizedBox(height: 12),
                          ],
                          _buildEditButton(colors),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.background, colors.background.withAlpha(0)],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: SizedBox(
              height: 28,
              child: Center(
                child: PullRefreshDots(
                  controller: _bounceController,
                  color: colors.primary,
                  dotsVisible: _isRefreshing || _loading ? 3 : _dotsVisible,
                  isRefreshing: _isRefreshing || _loading,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TaxBreakdownRow extends StatelessWidget {
  final String label;
  final int amount;
  final CamillColors colors;
  final NumberFormat fmt;

  const _TaxBreakdownRow({
    required this.label,
    required this.amount,
    required this.colors,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colors.primary.withAlpha(160),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: camillBodyStyle(12, colors.textMuted)),
        ),
        Text(
          fmt.format(amount),
          style: camillBodyStyle(12, colors.textMuted, weight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ── 今日使えるクーポン詳細シート ──────────────────────────────────────────────
class _TodayCouponSheet extends StatelessWidget {
  final List<Coupon> coupons;
  final CamillColors colors;
  final ValueChanged<Coupon> onUsed;
  final VoidCallback onViewAll;

  const _TodayCouponSheet({
    required this.coupons,
    required this.colors,
    required this.onUsed,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              children: [
                const Icon(
                  Icons.local_offer_rounded,
                  color: Color(0xFFD4A017),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '今日使えるクーポン',
                  style: camillHeadingStyle(16, colors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: coupons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = coupons[i];
                return _CouponRow(
                  coupon: c,
                  colors: colors,
                  onUsed: () => onUsed(c),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: colors.surfaceBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onViewAll,
                child: Text(
                  'クーポン財布をすべて見る',
                  style: camillBodyStyle(14, colors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponRow extends StatelessWidget {
  final Coupon coupon;
  final CamillColors colors;
  final VoidCallback onUsed;

  const _CouponRow({
    required this.coupon,
    required this.colors,
    required this.onUsed,
  });

  @override
  Widget build(BuildContext context) {
    return coupon.isFree
        ? _FreeCouponCard(coupon: coupon, onUsed: onUsed)
        : _DiscountCouponCard(coupon: coupon, colors: colors, onUsed: onUsed);
  }
}

class _FreeCouponCard extends StatelessWidget {
  final Coupon coupon;
  final VoidCallback onUsed;
  const _FreeCouponCard({required this.coupon, required this.onUsed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B6914), Color(0xFFD4A017), Color(0xFFFFD700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -12,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      coupon.storeName,
                      style: camillBodyStyle(13, Colors.white70),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '無料クーポン',
                        style: camillBodyStyle(
                          10,
                          Colors.white,
                          weight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  coupon.description,
                  style: camillBodyStyle(
                    16,
                    Colors.white,
                    weight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      size: 24,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '無料',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onUsed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withAlpha(120),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          '使用済みにする',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (coupon.validUntil != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 12,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        coupon.validUntil != null
                            ? (coupon.daysUntilExpiry == 0
                                  ? '本日まで！'
                                  : '残り${coupon.daysUntilExpiry}日')
                            : '',
                        style: camillBodyStyle(11, Colors.white70),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountCouponCard extends StatelessWidget {
  final Coupon coupon;
  final CamillColors colors;
  final VoidCallback onUsed;
  const _DiscountCouponCard({
    required this.coupon,
    required this.colors,
    required this.onUsed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_offer_outlined,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.storeName,
                  style: camillBodyStyle(11, colors.textMuted),
                ),
                Text(
                  coupon.description,
                  style: camillBodyStyle(
                    14,
                    colors.textPrimary,
                    weight: FontWeight.bold,
                  ),
                ),
                if (coupon.validFrom != null && coupon.validUntil != null)
                  Text(
                    '${coupon.validFrom!.month}/${coupon.validFrom!.day}〜${coupon.validUntil!.month}/${coupon.validUntil!.day}',
                    style: camillBodyStyle(11, colors.textMuted),
                  )
                else if (coupon.validUntil != null)
                  Text(
                    coupon.daysUntilExpiry == 0
                        ? '本日まで！'
                        : '残り${coupon.daysUntilExpiry}日',
                    style: camillBodyStyle(11, colors.textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${coupon.discountAmount}円引き',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onUsed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '使用済みにする',
                    style: camillBodyStyle(
                      12,
                      Colors.white,
                      weight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeBillDetailSheet extends StatelessWidget {
  final Bill bill;
  final NumberFormat fmt;
  final CamillColors colors;
  final VoidCallback onPaid;

  const _HomeBillDetailSheet({
    required this.bill,
    required this.fmt,
    required this.colors,
    required this.onPaid,
  });

  @override
  Widget build(BuildContext context) {
    final catColor =
        AppConstants.categoryColors[bill.category] ?? const Color(0xFF90A4AE);
    final catLabel = AppConstants.categoryLabels[bill.category] ?? 'その他';
    final days = bill.daysUntilDue;
    final urgent = bill.isUrgent;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: Color(0xFFE53935),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill.title,
                              style: camillBodyStyle(
                                17,
                                colors.textPrimary,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: catColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                catLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: catColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('金額', style: camillBodyStyle(13, colors.textMuted)),
                      Text(
                        fmt.format(bill.amount),
                        style: camillAmountStyle(20, colors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (bill.dueDate != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '支払期限',
                          style: camillBodyStyle(13, colors.textMuted),
                        ),
                        Row(
                          children: [
                            if (urgent)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.warning_amber_outlined,
                                  size: 14,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            Text(
                              '${bill.dueDate!.year}/${bill.dueDate!.month}/${bill.dueDate!.day}',
                              style: camillBodyStyle(
                                14,
                                urgent
                                    ? const Color(0xFFE53935)
                                    : colors.textPrimary,
                                weight: FontWeight.w600,
                              ),
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
                          style: camillBodyStyle(
                            12,
                            urgent ? const Color(0xFFE53935) : colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onPaid();
                      },
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                      ),
                      label: Text(
                        '支払いました',
                        style: camillBodyStyle(
                          15,
                          Colors.white,
                          weight: FontWeight.w600,
                        ),
                      ),
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
