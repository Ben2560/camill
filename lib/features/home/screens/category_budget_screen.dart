import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../subscriptions/screens/subscription_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services/user_prefs.dart';
import '../../../core/constants.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/fixed_expense_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/camill_card.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../services/fixed_expense_service.dart';
import '../widgets/subscription_editor_sheet.dart';

class CategoryBudgetScreen extends StatefulWidget {
  final bool dismissible;
  const CategoryBudgetScreen({super.key, this.dismissible = true});

  @override
  State<CategoryBudgetScreen> createState() => _CategoryBudgetScreenState();
}

class _CategoryBudgetScreenState extends State<CategoryBudgetScreen>
    with TickerProviderStateMixin {
  // 固定費カテゴリ
  static const _fixedCategories = <String, ({IconData icon, String label})>{
    'housing': (icon: Icons.home_outlined, label: '住居費'),
    'utility': (icon: Icons.bolt_outlined, label: '光熱費'),
    'subscription': (icon: Icons.subscriptions_outlined, label: 'サブスク'),
  };

  // 変動費カテゴリ
  static const _variableCategories = <String, ({IconData icon, String label})>{
    'food': (icon: Icons.rice_bowl_outlined, label: '食費'),
    'dining_out': (icon: Icons.restaurant_outlined, label: '外食費'),
    'daily': (icon: Icons.shopping_basket_outlined, label: '日用品'),
    'transport': (icon: Icons.train_outlined, label: '交通費'),
    'clothing': (icon: Icons.checkroom_outlined, label: '衣服'),
    'social': (icon: Icons.people_outline, label: '交際費'),
    'hobby': (icon: Icons.sports_esports_outlined, label: '趣味'),
    'medical': (icon: Icons.local_hospital_outlined, label: '医療・健康'),
    'education': (icon: Icons.menu_book_outlined, label: '教育・書籍'),
    'other': (icon: Icons.more_horiz, label: 'その他雑費'),
  };

  // 全カテゴリ（API保存・合計計算用）
  static Map<String, ({IconData icon, String label})> get _allCategories => {
    ..._fixedCategories,
    ..._variableCategories,
  };

  static const _budgetKey = 'budget_monthly';

  final _api = ApiService();
  final _fixedSvc = FixedExpenseService();
  final _fmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
  final Map<String, int> _budgets = {};
  // 固定費: 引き落とし日設定（category → FixedExpenseSetting）
  final Map<String, FixedExpenseSetting> _fixedSettings = {};
  // 固定費: 当月支払い実績（category → FixedPayment）
  Map<String, FixedPayment> _payments = {};
  int _totalBudget = 0;
  bool _loading = true;

  // タブ: 0=固定費, 1=変動費
  int _tabIndex = 0;

  final _dismissOffset = ValueNotifier<double>(0);
  late final AnimationController _snapController;
  bool _isDismissing = false;
  final _scrollController = ScrollController();
  double _pullDistance = 0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dismissOffset.addListener(_onOffsetChanged);
    _load();
  }

  void _onOffsetChanged() {
    if (!mounted || _isDismissing) return;
    final limit = MediaQuery.of(context).size.height * 0.20;
    if (_dismissOffset.value >= limit) {
      _isDismissing = true;
      _dismissOffset.removeListener(_onOffsetChanged);
      _beginDismiss();
    }
  }

  void _endDismiss() {
    if (_isDismissing) return;
    final sh = MediaQuery.of(context).size.height;
    if (_dismissOffset.value > sh * 0.20) {
      _isDismissing = true;
      _beginDismiss();
    } else {
      _snapBack();
    }
  }

  void _beginDismiss() {
    _snapController.duration = const Duration(milliseconds: 200);
    _snapController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) Navigator.of(context, rootNavigator: false).pop();
    });
  }

  void _snapBack() {
    final start = _dismissOffset.value;
    _snapController.reset();
    final anim = Tween<double>(begin: start, end: 0).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    anim.addListener(() => _dismissOffset.value = anim.value);
    _snapController.forward();
  }

  @override
  void dispose() {
    _dismissOffset.removeListener(_onOffsetChanged);
    _dismissOffset.dispose();
    _snapController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _allCategories.keys) {
      _budgets[key] =
          (await UserPrefs.getInt(prefs, 'category_budget_$key')) ?? 0;
    }
    final ym = DateTime.now();
    final yearMonth = '${ym.year}-${ym.month.toString().padLeft(2, '0')}';
    try {
      final data = await _api.get('/budgets/$yearMonth');
      final apiBudgets = data.map((k, v) => MapEntry(k, (v as num).toInt()));
      if (apiBudgets.isNotEmpty) {
        for (final key in _allCategories.keys) {
          _budgets[key] = apiBudgets[key] ?? 0;
        }
        for (final e in _budgets.entries) {
          await UserPrefs.setInt(prefs, 'category_budget_${e.key}', e.value);
        }
      } else {
        final nonZero = {
          for (final e in _budgets.entries)
            if (e.value > 0) e.key: e.value,
        };
        if (nonZero.isNotEmpty) {
          await _api.patch('/budgets/$yearMonth', body: nonZero);
        }
      }
    } catch (_) {}

    // 固定費: 引き落とし日・支払い実績を並列取得
    try {
      final results = await Future.wait([
        _fixedSvc.getSettings(),
        _fixedSvc.getPayments(yearMonth),
      ]);
      final settings = results[0] as Map<String, FixedExpenseSetting>;
      final payments = results[1] as Map<String, FixedPayment>;
      _fixedSettings
        ..clear()
        ..addAll(settings);
      _payments = payments;
    } catch (_) {}

    final computed = _budgets.values.fold(0, (s, v) => s + v);
    _totalBudget = computed;
    await UserPrefs.setInt(
      await SharedPreferences.getInstance(),
      _budgetKey,
      _totalBudget,
    );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _persist({bool updateTotal = true}) async {
    final prefs = await SharedPreferences.getInstance();
    for (final e in _budgets.entries) {
      await UserPrefs.setInt(prefs, 'category_budget_${e.key}', e.value);
    }
    if (updateTotal) {
      final computed = _budgets.values.fold(0, (s, v) => s + v);
      _totalBudget = computed;
      await UserPrefs.setInt(prefs, _budgetKey, _totalBudget);
    }
    try {
      final ym = DateTime.now();
      final yearMonth = '${ym.year}-${ym.month.toString().padLeft(2, '0')}';
      await _api.patch('/budgets/$yearMonth', body: Map.from(_budgets));
    } catch (_) {}
  }

  Future<void> _openSubscriptionEditor() async {
    final colors = context.colors;
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SubscriptionEditorSheet(
        initialBudget: _budgets['subscription'] ?? 0,
        colors: colors,
        api: _api,
      ),
    );

    if (result != null) {
      setState(() => _budgets['subscription'] = result);
      await _persist();
    }
  }

  void _openEditor(String key) {
    final colors = context.colors;
    final meta = _allCategories[key]!;
    final ctrl = TextEditingController(
      text: (_budgets[key] ?? 0) > 0 ? (_budgets[key]!).toString() : '',
    );
    final isFixed = AppConstants.fixedCategories.contains(key);
    final existing = _fixedSettings[key];
    // 末日(32)の場合は dayCtrl を空にして isLastDay フラグで管理
    bool isLastDay = existing?.billingDay == 32;
    final dayCtrl = TextEditingController(
      text: (existing?.billingDay != null && existing!.billingDay != 32)
          ? existing.billingDay.toString()
          : '',
    );
    String? selectedHolidayRule = existing?.holidayRule;

    showModalBottomSheet(
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
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(meta.icon, color: colors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meta.label,
                          style: camillBodyStyle(
                            20,
                            colors.textPrimary,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          isFixed ? '固定費' : '変動費',
                          style: camillBodyStyle(12, colors.textMuted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if ((_budgets[key] ?? 0) > 0)
                      GestureDetector(
                        onTap: () {
                          ctrl.clear();
                          setSheet(() {});
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.surfaceBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '¥',
                          style: camillBodyStyle(
                            26,
                            colors.textMuted,
                            weight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Theme(
                            data: Theme.of(ctx).copyWith(
                              splashFactory: NoSplash.splashFactory,
                              highlightColor: Colors.transparent,
                            ),
                            child: TextField(
                              controller: ctrl,
                              autofocus: true,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: false,
                                    signed: false,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: camillBodyStyle(
                                32,
                                colors.textPrimary,
                                weight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: camillBodyStyle(
                                  32,
                                  colors.textMuted,
                                  weight: FontWeight.w700,
                                ),
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setSheet(() {}),
                            ),
                          ),
                        ),
                        if (ctrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              ctrl.clear();
                              setSheet(() {});
                            },
                            child: Icon(
                              Icons.cancel,
                              color: colors.textMuted,
                              size: 22,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // 固定費のみ: 引き落とし日 + 休日ルール
              if (isFixed) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.surfaceBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 引き落とし日入力 ──
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 15,
                              color: colors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '引き落とし日',
                              style: camillBodyStyle(13, colors.textSecondary),
                            ),
                            const SizedBox(width: 12),
                            // 数字入力（末日トグル時はdisable）
                            SizedBox(
                              width: 48,
                              child: TextField(
                                controller: dayCtrl,
                                enabled: !isLastDay,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                textAlign: TextAlign.center,
                                style: camillBodyStyle(
                                  15,
                                  colors.textPrimary,
                                  weight: FontWeight.w700,
                                ),
                                decoration: InputDecoration(
                                  hintText: '--',
                                  hintStyle: camillBodyStyle(
                                    15,
                                    colors.textMuted,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 4,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: colors.surfaceBorder,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: colors.surfaceBorder,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: colors.primary,
                                    ),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: colors.surfaceBorder.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                onChanged: (_) => setSheet(() {}),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '日',
                              style: camillBodyStyle(13, colors.textSecondary),
                            ),
                            const Spacer(),
                            // 末日トグル
                            GestureDetector(
                              onTap: () => setSheet(() {
                                isLastDay = !isLastDay;
                                if (isLastDay) dayCtrl.clear();
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isLastDay
                                      ? colors.primary
                                      : colors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isLastDay
                                        ? colors.primary
                                        : colors.surfaceBorder,
                                  ),
                                ),
                                child: Text(
                                  '末日',
                                  style: camillBodyStyle(
                                    12,
                                    isLastDay ? Colors.white : colors.textMuted,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // 休日ルール（引き落とし日が設定されている場合のみ表示）
                        if (isLastDay || dayCtrl.text.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Divider(height: 1, color: colors.surfaceBorder),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.event_busy_outlined,
                                size: 15,
                                color: colors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '休日の場合',
                                style: camillBodyStyle(
                                  13,
                                  colors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              HolidayRulePill(
                                label: '前営業日',
                                selected: selectedHolidayRule == 'before',
                                colors: colors,
                                onTap: () => setSheet(
                                  () => selectedHolidayRule =
                                      selectedHolidayRule == 'before'
                                      ? null
                                      : 'before',
                                ),
                              ),
                              const SizedBox(width: 6),
                              HolidayRulePill(
                                label: '翌営業日',
                                selected: selectedHolidayRule == 'after',
                                colors: colors,
                                onTap: () => setSheet(
                                  () => selectedHolidayRule =
                                      selectedHolidayRule == 'after'
                                      ? null
                                      : 'after',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if (key == 'subscription') ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SubscriptionScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: colors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.subscriptions_outlined,
                              size: 18,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'サブスクを登録・確認する',
                                  style: camillBodyStyle(
                                    14,
                                    colors.textPrimary,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Netflix・Spotify などを個別に管理',
                                  style: camillBodyStyle(12, colors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: colors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final val = int.tryParse(ctrl.text) ?? 0;
                      int? billingDay;
                      if (isFixed) {
                        if (isLastDay) {
                          billingDay = 32;
                        } else {
                          final d = int.tryParse(dayCtrl.text);
                          billingDay = (d != null && d >= 1 && d <= 31)
                              ? d
                              : null;
                        }
                      }
                      setState(() {
                        _budgets[key] = val;
                        if (isFixed) {
                          _fixedSettings[key] = FixedExpenseSetting(
                            category: key,
                            billingDay: billingDay,
                            holidayRule: billingDay != null
                                ? selectedHolidayRule
                                : null,
                          );
                        }
                      });
                      await _persist();
                      if (isFixed) {
                        try {
                          await _fixedSvc.updateBillingDay(
                            key,
                            billingDay: billingDay,
                            holidayRule: billingDay != null
                                ? selectedHolidayRule
                                : null,
                          );
                        } catch (_) {}
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      '設定する',
                      style: camillBodyStyle(
                        16,
                        Colors.white,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sh = MediaQuery.of(context).size.height;

    final scaffold = Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'カテゴリ予算',
          style: camillBodyStyle(
            17,
            colors.textPrimary,
            weight: FontWeight.w600,
          ),
        ),
        leading: widget.dismissible
            ? IconButton(
                icon: Icon(Icons.close, color: colors.textSecondary),
                onPressed: () =>
                    Navigator.of(context, rootNavigator: false).pop(),
              )
            : IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: colors.textPrimary,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: widget.dismissible
            ? Listener(
                onPointerMove: (e) {
                  if (_isDismissing) return;
                  if (_scrollController.hasClients &&
                      _scrollController.position.pixels <= 0 &&
                      e.delta.dy > 0) {
                    _pullDistance += e.delta.dy;
                    _dismissOffset.value = _pullDistance;
                  } else if (e.delta.dy < 0 && _pullDistance > 0) {
                    _pullDistance = 0;
                    _dismissOffset.value = 0;
                  }
                },
                onPointerUp: (_) {
                  if (_isDismissing) return;
                  _endDismiss();
                  _pullDistance = 0;
                },
                onPointerCancel: (_) {
                  if (_isDismissing) return;
                  _pullDistance = 0;
                  _dismissOffset.value = 0;
                },
                child: ListView(
                  controller: _scrollController,
                  physics: const DismissScrollPhysicsWithTopBounce(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
                  children: _buildListItems(colors),
                ),
              )
            : ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
                children: _buildListItems(colors),
              ),
      ),
    );

    if (!widget.dismissible) return scaffold;

    return AnimatedBuilder(
      animation: Listenable.merge([_dismissOffset, _snapController]),
      builder: (ctx, child) {
        final progress = (_dismissOffset.value / (sh * 0.20)).clamp(0.0, 1.0);
        final blur = _isDismissing ? _snapController.value * 12.0 : 0.0;
        Widget content = child!;
        if (blur > 0.1) {
          content = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: content,
          );
        }
        return Stack(
          children: [
            Container(color: colors.background),
            Container(color: Colors.black.withValues(alpha: 0.28 * progress)),
            Transform.translate(
              offset: Offset(0, _dismissOffset.value),
              child: Transform.scale(
                scale: 1.0 - progress * 0.07,
                alignment: Alignment.topCenter,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(progress * 22.0),
                  ),
                  child: content,
                ),
              ),
            ),
          ],
        );
      },
      child: scaffold,
    );
  }

  List<Widget> _buildListItems(CamillColors colors) {
    final isFixed = _tabIndex == 0;
    final currentCategories = isFixed ? _fixedCategories : _variableCategories;

    final fixedTotal = _fixedCategories.keys.fold(
      0,
      (s, k) => s + (_budgets[k] ?? 0),
    );
    final variableTotal = _variableCategories.keys.fold(
      0,
      (s, k) => s + (_budgets[k] ?? 0),
    );
    final totalAllocated = fixedTotal + variableTotal;

    final setItems = currentCategories.entries
        .where(
          (e) =>
              (_budgets[e.key] ?? 0) > 0 ||
              (isFixed ? false : e.key == 'other'),
        )
        .toList();
    final unsetItems = currentCategories.entries
        .where(
          (e) =>
              (_budgets[e.key] ?? 0) == 0 &&
              !(isFixed ? false : e.key == 'other'),
        )
        .toList();

    return [
      // ── 月の予算ヘッダー ──
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wallet_outlined, size: 14, color: colors.textMuted),
                const SizedBox(width: 5),
                Text(
                  '月に使えるお金',
                  style: camillBodyStyle(
                    12,
                    colors.textMuted,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              totalAllocated > 0 ? _fmt.format(_totalBudget) : '¥ ---',
              style: camillBodyStyle(
                32,
                colors.textPrimary,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            // 固定費 / 変動費 内訳バー
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8D6E63),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '固定費',
                            style: camillBodyStyle(11, colors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fmt.format(fixedTotal),
                        style: camillBodyStyle(
                          13,
                          colors.textPrimary,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: colors.surfaceBorder),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '変動費',
                              style: camillBodyStyle(11, colors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fmt.format(variableTotal),
                          style: camillBodyStyle(
                            13,
                            colors.textPrimary,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // ── 固定費/変動費 タブ ──
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.surfaceBorder),
        ),
        child: Row(
          children: [
            _buildTab(0, '固定費', Icons.lock_outline, colors),
            _buildTab(1, '変動費', Icons.shuffle, colors),
          ],
        ),
      ),

      // ── 固定費タブの説明 ──
      if (isFixed)
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Text(
            '家賃・光熱費・サブスクなど毎月ほぼ一定の支出',
            style: camillBodyStyle(12, colors.textMuted),
          ),
        ),

      if (setItems.isNotEmpty) ...[
        _sectionLabel('設定済み (${setItems.length})', colors),
        ...setItems.map((e) => _buildRow(e.key, e.value, colors)),
        const SizedBox(height: 20),
      ],
      _sectionLabel(
        unsetItems.isEmpty ? '未設定 (0)' : '未設定 (${unsetItems.length})',
        colors,
      ),
      if (unsetItems.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              '全カテゴリ設定済みです',
              style: camillBodyStyle(13, colors.textMuted),
            ),
          ),
        )
      else
        ...unsetItems.map((e) => _buildRow(e.key, e.value, colors)),
    ];
  }

  Widget _buildTab(
    int index,
    String label,
    IconData icon,
    CamillColors colors,
  ) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_tabIndex != index) setState(() => _tabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : colors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: camillBodyStyle(
                  13,
                  selected ? Colors.white : colors.textMuted,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, CamillColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        text,
        style: camillBodyStyle(12, colors.textMuted, weight: FontWeight.w600),
      ),
    );
  }

  // 固定費の支払い状態バッジを生成
  Widget? _buildPaymentBadge(String key, CamillColors colors) {
    final isFixed = AppConstants.fixedCategories.contains(key);
    if (!isFixed) return null;

    final payment = _payments[key];
    if (payment != null) {
      // 支払い済み
      return GestureDetector(
        onTap: () async {
          // 長押しで取り消し確認
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF34C759).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 13,
                color: Color(0xFF34C759),
              ),
              const SizedBox(width: 4),
              Text(
                '引き落とし済',
                style: camillBodyStyle(
                  12,
                  const Color(0xFF34C759),
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final billingDay = _fixedSettings[key]?.billingDay;
    if (billingDay == null) return null;

    final today = DateTime.now().day;
    final isOverdue = billingDay == 32
        ? today >= _lastDayOfMonth()
        : today >= billingDay;

    if (isOverdue) {
      // 引き落とし日到来・未確認
      return GestureDetector(
        onTap: () async {
          final ym = DateTime.now();
          final yearMonth = '${ym.year}-${ym.month.toString().padLeft(2, '0')}';
          try {
            await _fixedSvc.markPaid(yearMonth, key);
            final payments = await _fixedSvc.getPayments(yearMonth);
            if (mounted) setState(() => _payments = payments);
          } catch (_) {}
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9500).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 13,
                color: Color(0xFFFF9500),
              ),
              const SizedBox(width: 4),
              Text(
                '未確認  タップで済',
                style: camillBodyStyle(
                  12,
                  const Color(0xFFFF9500),
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 引き落とし日は未到来
    final dayLabel = billingDay == 32 ? '末日' : '$billingDay日';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Text('$dayLabel 予定', style: camillBodyStyle(12, colors.textMuted)),
    );
  }

  int _lastDayOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0).day;
  }

  Widget _buildRow(
    String key,
    ({IconData icon, String label}) meta,
    CamillColors colors,
  ) {
    final budget = _budgets[key] ?? 0;
    final hasValue = budget > 0;
    final paymentBadge = _buildPaymentBadge(key, colors);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CamillCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => key == 'subscription'
            ? _openSubscriptionEditor()
            : _openEditor(key),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: hasValue ? colors.primaryLight : colors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    meta.icon,
                    color: hasValue ? colors.primary : colors.textMuted,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    meta.label,
                    style: camillBodyStyle(14, colors.textPrimary),
                  ),
                ),
                if (hasValue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _fmt.format(budget),
                      style: camillBodyStyle(
                        13,
                        colors.primary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 13, color: colors.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          '設定する',
                          style: camillBodyStyle(13, colors.textMuted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (paymentBadge != null) ...[
              const SizedBox(height: 8),
              paymentBadge,
            ],
            if (key == 'subscription') ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.list_alt_outlined,
                        size: 13,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'サブスクを管理',
                        style: camillBodyStyle(
                          12,
                          colors.primary,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
