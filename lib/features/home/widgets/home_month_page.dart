import 'dart:ui' show ImageFilter;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/services/cache_service.dart';
import '../../../shared/services/error_reporter.dart';
import '../../../shared/models/bill_model.dart';
import '../../../shared/models/family_model.dart';
import '../../../shared/models/summary_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/user_prefs.dart';
import '../../../shared/widgets/animated_counter.dart';
import '../../../shared/widgets/camill_card.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../../bill/screens/bill_screen.dart';
import '../../bill/services/bill_service.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../coupon/services/coupon_service.dart';
import '../../family/screens/family_management_screen.dart';
import '../../family/services/family_service.dart';
import '../../receipt/screens/receipt_list_screen.dart';
import '../../receipt/services/receipt_service.dart';
import '../../reports/screens/report_screen.dart';
import '../widgets/overseas_rate_card.dart';
import '../widgets/tax_breakdown_row.dart';
import '../widgets/today_coupon_sheet.dart';
import '../screens/category_budget_screen.dart';
import '../../data/screens/data_screen.dart';

// ignore_for_file: unused_import

class HomeMonthPage extends StatefulWidget {
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
  final String plan;
  final bool isOverseas;
  final String overseasCurrency;
  final double overseasRate;

  const HomeMonthPage({
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
    this.plan = 'free',
    this.isOverseas = false,
    this.overseasCurrency = 'JPY',
    this.overseasRate = 1.0,
  });

  @override
  State<HomeMonthPage> createState() => HomeMonthPageState();
}

class HomeMonthPageState extends State<HomeMonthPage>
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

  // ファミリープラン用
  Family? _family;
  Map<String, dynamic>? _partnerSummary; // null = 権限未付与
  List<Map<String, dynamic>> _childrenData = [];
  bool _familyLoaded = false;
  final _familyService = FamilyService();

  String? _selectedCategory;

  late final ScrollController _scrollController;
  GoRouterDelegate? _routerDelegate;
  bool _wasScrollingBeforeTap = false;

  // pull-to-refresh のドット表示閾値（overscroll px）
  static const _kPullDot1 = 25.0;
  static const _kPullDot2 = 55.0;
  static const _kPullFull = 85.0;

  static const _baseWidgetIds = [
    'budget',
    'category',
    'score',
    'compare',
    'recent',
    'tax',
    'bills',
  ];
  List<String> get _allWidgetIds => [
    ..._baseWidgetIds,
    if (widget.plan == 'family') 'family_management',
    if (widget.plan == 'family') 'family_partner',
    if (widget.plan == 'family') 'family_savings',
  ];
  static const _widgetLabels = <String, ({String title, IconData icon})>{
    'budget': (title: '収支', icon: Icons.account_balance_wallet_outlined),
    'category': (title: '使いみち', icon: Icons.pie_chart_outline),
    'score': (title: 'やりくりスコア', icon: Icons.emoji_events_outlined),
    'compare': (title: '先月との比較', icon: Icons.compare_arrows),
    'recent': (title: '最近のレシート', icon: Icons.receipt_outlined),
    'tax': (title: '消費税', icon: Icons.account_balance_outlined),
    'bills': (title: '請求書', icon: Icons.receipt_long_outlined),
    'family_management': (title: 'ファミリー管理', icon: Icons.group_outlined),
    'family_partner': (title: 'パートナー支出', icon: Icons.people_outline),
    'family_savings': (title: '子供の貯金', icon: Icons.savings_outlined),
  };

  static const categoryMeta = <String, ({IconData icon, String label})>{
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
    'housing': (icon: Icons.home_outlined, label: '住居費'),
    'other': (icon: Icons.more_horiz, label: 'その他雑費'),
  };

  // 固定費カテゴリキー
  static const _fixedCategoryKeys = {'housing', 'utility', 'subscription'};

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
      if (!mounted) return;
      _routerDelegate = GoRouter.of(context).routerDelegate;
      _routerDelegate?.addListener(_onRouteChanged);
    });
  }

  @override
  void didUpdateWidget(covariant HomeMonthPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plan != 'family' && widget.plan == 'family') {
      _loadFamilySummaries();
    }
  }

  @override
  void dispose() {
    CalendarScreen.receiptRefreshSignal.removeListener(_onReceiptChanged);
    _routerDelegate?.removeListener(_onRouteChanged);
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
    final path = _routerDelegate?.currentConfiguration.uri.path;
    if (path == '/') {
      _load(silent: true);
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    final yearMonth = DateFormat('yyyy-MM').format(widget.month);
    final prevMonth = DateTime(widget.month.year, widget.month.month - 1);
    final prevYearMonth = DateFormat('yyyy-MM').format(prevMonth);

    // キャッシュがあれば先に表示してローディングを隠す
    if (!silent) {
      final cached = await CacheService.loadSummary(yearMonth);
      if (cached != null && mounted) {
        setState(() {
          _summary = MonthlySummary.fromJson(cached);
          _loading = false;
        });
      } else {
        setState(() => _loading = true);
      }
    }

    final sw = ErrorReporter.startTimer();
    try {
      final results = await Future.wait([
        _api.get('/summary/monthly', query: {'year_month': yearMonth}),
        _api.get('/summary/monthly', query: {'year_month': prevYearMonth}),
      ]);
      ErrorReporter.checkSlow(sw, 'home_summary/$yearMonth');

      if (!mounted) return;
      // 取得成功したらキャッシュを更新
      CacheService.saveSummary(yearMonth, results[0]);
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
      if (widget.plan == 'family') _loadFamilySummaries();
    } catch (e, st) {
      ErrorReporter.checkSlow(sw, 'home_summary/$yearMonth');
      ErrorReporter.report(e, st, endpoint: 'home_summary/$yearMonth');
      debugPrint('_load error: $e');
      if (!mounted) return;
      if (!silent) {
        setState(() {
          // キャッシュがあれば既に表示済みなのでゼロリセットしない
          _summary ??= MonthlySummary(
            yearMonth: yearMonth,
            totalExpense: 0,
            totalIncome: 0,
            score: 0,
            byCategory: [],
            recentReceipts: [],
            allReceipts: [],
          );
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
    } catch (e) {
      debugPrint('_loadMonthMedicalExpense error: $e');
      if (mounted) setState(() => _monthMedicalExpense = null);
    }
  }

  Future<void> _loadFamilySummaries() async {
    try {
      final results = await Future.wait([
        _familyService.fetchMyFamily(),
        _api.getAny('/families/summary/partner'),
        _api.getAny('/families/summary/children'),
      ]);
      if (!mounted) return;
      setState(() {
        _family = results[0] as Family?;
        _partnerSummary = results[1] as Map<String, dynamic>?;
        _childrenData = ((results[2] as List<dynamic>?) ?? [])
            .cast<Map<String, dynamic>>();
        _familyLoaded = true;
      });
    } catch (e) {
      debugPrint('_loadFamilySummaries error: $e');
      if (mounted) setState(() => _familyLoaded = true);
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
    } catch (e) {
      debugPrint('_loadWeekExpense error: $e');
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
    } catch (e) {
      debugPrint('_loadYearExpense error: $e');
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
    for (final key in categoryMeta.keys) {
      budgets[key] =
          (await UserPrefs.getInt(prefs, 'category_budget_$key')) ?? 0;
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
      case 'family_management':
        return widget.plan == 'family'
            ? _buildFamilyManagementCard(colors)
            : const SizedBox.shrink();
      case 'family_partner':
        return widget.plan == 'family'
            ? _buildFamilyPartnerCard(colors)
            : const SizedBox.shrink();
      case 'family_savings':
        return widget.plan == 'family'
            ? _buildFamilySavingsCard(colors)
            : const SizedBox.shrink();
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

  // ボトムシートの共通構造（ハンドル＋タイトル＋アイテムリスト）
  void _showRadioSheet({
    required CamillColors colors,
    required String title,
    required List<Widget> items,
  }) {
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
                title,
                style: camillBodyStyle(
                  17,
                  colors.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...items,
            const SizedBox(height: 8),
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
    _showRadioSheet(
      colors: colors,
      title: 'カテゴリ',
      items: [
        ListTile(
          title: Text('合計', style: camillBodyStyle(15, colors.textPrimary)),
          leading: Icon(
            catKey == null ? Icons.check_circle : Icons.radio_button_unchecked,
            color: catKey == null ? colors.primary : colors.textMuted,
          ),
          onTap: () {
            Navigator.pop(context);
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
              Navigator.pop(context);
              setState(() => _selectedCategory = e.key);
            },
          ),
        ),
      ],
    );
  }

  void _showPeriodSheet(CamillColors colors) {
    _showRadioSheet(
      colors: colors,
      title: '期間',
      items: ['週', '月', '年']
          .asMap()
          .entries
          .map(
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
                Navigator.pop(context);
                setState(() => _periodIndex = e.key);
                if (e.key == 0) _loadWeekExpense();
                if (e.key == 2) _loadYearExpense();
              },
            ),
          )
          .toList(),
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
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/plan');
                },
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
      budgetLabel = categoryMeta[catKey]?.label ?? catKey;
    }

    final remaining = budget > 0 ? budget - expense : 0;
    final ratio = budget > 0 ? (expense / budget).clamp(0.0, 1.0) : 0.0;

    // カテゴリチップ用リスト（データがあるカテゴリのみ）
    final availableCats = categoryMeta.entries
        .where((e) => cats.any((c) => c.category == e.key))
        .toList();

    final selectedLabel = catKey == null
        ? '合計'
        : (categoryMeta[catKey]?.label ?? catKey);

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
                      width: _sp(100),
                      height: _sp(100),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              startDegreeOffset: -90,
                              sectionsSpace: 0,
                              centerSpaceRadius: _sp(32),
                              sections: budget > 0
                                  ? [
                                      PieChartSectionData(
                                        value: ratio,
                                        color: ratio > 0.8
                                            ? colors.danger
                                            : colors.primary,
                                        radius: _sp(18),
                                        showTitle: false,
                                      ),
                                      PieChartSectionData(
                                        value: 1 - ratio,
                                        color: colors.surfaceBorder,
                                        radius: _sp(18),
                                        showTitle: false,
                                      ),
                                    ]
                                  : [
                                      PieChartSectionData(
                                        value: 1,
                                        color: colors.surfaceBorder,
                                        radius: _sp(18),
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
                            style: camillAmountStyle(
                              _sp(28),
                              colors.textPrimary,
                            ),
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

  Widget _buildFixedVarChip(
    String label,
    int amount,
    Color color,
    CamillColors colors,
  ) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: camillBodyStyle(11, colors.textMuted)),
          const Spacer(),
          Text(
            _currencyFmt.format(amount),
            style: camillBodyStyle(
              12,
              colors.textPrimary,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySummary(CamillColors colors) {
    final cats = _summary!.byCategory;
    // カテゴリ別データは月次のみ取得しているため常に月次合計を使う
    // 週/年モードでも「月」ラベルで月次データを表示
    final total = _summary!.totalExpense;
    const periodLabel = '月';

    // 支出があるカテゴリの行（予算未設定でも表示）
    final rows =
        categoryMeta.entries
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
    final otherMeta = categoryMeta['other']!;

    // 固定費 / 変動費 合計
    final fixedTotal = rows
        .where((r) => _fixedCategoryKeys.contains(r.key))
        .fold(0, (s, r) => s + r.amount);
    final variableTotal = total - fixedTotal;

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
        final newBudget =
            (await UserPrefs.getInt(prefs, 'budget_monthly')) ?? 0;
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
                    final newBudget =
                        (await UserPrefs.getInt(prefs, 'budget_monthly')) ?? 0;
                    if (mounted) widget.onBudgetChanged(newBudget);
                    _loadCategoryBudgets();
                    _load(silent: true);
                  },
                  child: Icon(Icons.tune, size: 18, color: colors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 固定費 / 変動費 サマリー行
            if (total > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildFixedVarChip(
                      '固定費',
                      fixedTotal,
                      const Color(0xFF8D6E63),
                      colors,
                    ),
                    const SizedBox(width: 8),
                    _buildFixedVarChip(
                      '変動費',
                      variableTotal,
                      colors.primary,
                      colors,
                    ),
                  ],
                ),
              ),
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
                Text('$score', style: camillAmountStyle(_sp(52), scoreColor)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    ' 点',
                    style: camillBodyStyle(_sp(18), colors.textMuted),
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
            if ((_summary?.totalSavings ?? 0) > 0) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.success.withValues(alpha: 0.3),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      size: 15,
                      color: colors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '今月の節約合計',
                      style: camillBodyStyle(
                        12,
                        colors.success,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _currencyFmt.format(_summary!.totalSavings),
                      style: camillAmountStyle(14, colors.success),
                    ),
                  ],
                ),
              ),
            ],
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
              TaxBreakdownRow(
                label: '非課税（医療・介護・教育）',
                amount: medicalExpense,
                colors: colors,
                fmt: _currencyFmt,
              ),
              const SizedBox(height: 4),
            ],
            if (billExpense > 0) ...[
              TaxBreakdownRow(
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
  bool get wantKeepAlive => true;

  /// スクリーン幅に応じてサイズをスケーリング（390px基準）
  /// 600px超（iPad等）では最大1.5倍まで拡大を許容
  double _sp(double base) {
    final w = MediaQuery.of(context).size.width;
    final maxScale = w > 600 ? 1.5 : 1.22;
    return (base * w / 390.0).clamp(base * 0.82, base * maxScale);
  }

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
                final newDots = pixels < -_kPullFull
                    ? 3
                    : pixels < -_kPullDot2
                    ? 2
                    : pixels < -_kPullDot1
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
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'ハイライト',
                            style: camillBodyStyle(
                              _sp(26),
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
                        final newList = List<String>.from(widget.homeWidgets);
                        if (newIndex > oldIndex) newIndex--;
                        final item = newList.removeAt(oldIndex);
                        newList.insert(newIndex, item);
                        widget.onLayoutChanged(newList);
                      },
                    ),
                  ),
                  // 海外モード中のみレートカードをハイライト最下部に表示
                  if (widget.isOverseas)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: OverseasRateCard(
                          currency: widget.overseasCurrency,
                          rate: widget.overseasRate,
                          colors: colors,
                        ),
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

  // ── ファミリーカード ──────────────────────────────────────────────────────
  Widget _buildFamilyManagementCard(CamillColors colors) {
    final family = _family;

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
      openBuilder: (_, _) => const FamilyManagementScreen(),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.group_outlined,
                        color: colors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ファミリー管理',
                        style: camillBodyStyle(
                          14,
                          colors.textPrimary,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (family != null)
                    Text(
                      '${family.members.length} / ${family.maxMembers}人',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              if (family == null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '読み込み中...',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  family.name,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (family.members.length <= 1) ...[
                  // 自分だけの場合 → 招待を促すボタン
                  GestureDetector(
                    onTap: openContainer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.primary.withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_outlined,
                            size: 14,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '家族を招待する',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // メンバーのアバター一覧
                  Row(
                    children: [
                      ...family.members.take(5).map((m) {
                        final roleColor = switch (m.role) {
                          'owner' => colors.primary,
                          'parent' => Colors.teal,
                          _ => Colors.orange,
                        };
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: roleColor.withAlpha(30),
                                child: Text(
                                  m.displayName.isNotEmpty
                                      ? m.displayName[0]
                                      : '?',
                                  style: TextStyle(
                                    color: roleColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m.displayName.length > 4
                                    ? '${m.displayName.substring(0, 4)}…'
                                    : m.displayName,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (family.members.length < family.maxMembers)
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: colors.surfaceBorder,
                              child: Icon(
                                Icons.person_add_outlined,
                                size: 16,
                                color: colors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '招待',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyPartnerCard(CamillColors colors) {
    final summary = _partnerSummary;

    Widget content;
    if (!_familyLoaded) {
      // ローディング中
      content = const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (summary == null) {
      // 権限未付与
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.primary.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: colors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'カテゴリ・金額のみ共有',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'パートナーから権限をもらうと\n今月の支出サマリーが表示されます',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      // データあり
      final partnerName = summary['partner_name'] as String? ?? 'パートナー';
      final total = (summary['total_expense'] as num?)?.toInt() ?? 0;
      final catTotals =
          (summary['category_totals'] as Map<String, dynamic>?) ?? {};

      // 上位3カテゴリを金額降順で表示
      final topCats = catTotals.entries.toList()
        ..sort((a, b) => (b.value as int).compareTo(a.value as int));

      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                partnerName,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
              Text(
                _currencyFmt.format(total),
                style: camillBodyStyle(
                  18,
                  colors.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...topCats.take(3).map((e) {
            final meta = categoryMeta[e.key];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(
                    meta?.icon ?? Icons.more_horiz,
                    size: 13,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      meta?.label ?? e.key,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    _currencyFmt.format(e.value as int),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    }

    return CamillCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.people_outline, color: colors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'パートナー支出',
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
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildFamilySavingsCard(CamillColors colors) {
    Widget content;
    if (!_familyLoaded) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (_childrenData.isEmpty) {
      // 子供アカウントなし
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.primary.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.child_care_outlined,
                  size: 14,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '子供アカウントを追加してください',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push('/family'),
            child: Text(
              'ファミリー管理 →',
              style: TextStyle(
                color: colors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    } else {
      // 子供ごとの今月支出を表示
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: _childrenData.map((child) {
          final name = child['child_name'] as String? ?? '子供';
          final total = (child['total_expense'] as num?)?.toInt() ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                const Icon(Icons.child_care_outlined, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFmt.format(total),
                      style: camillBodyStyle(
                        14,
                        colors.textPrimary,
                        weight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '今月の支出',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return CamillCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.savings_outlined, color: colors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '子供の支出',
                    style: camillBodyStyle(
                      14,
                      colors.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.push('/family'),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}
