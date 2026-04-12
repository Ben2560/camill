import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/camill_card.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/pull_to_refresh.dart';

class CategoryBudgetScreen extends StatefulWidget {
  final bool dismissible;
  const CategoryBudgetScreen({super.key, this.dismissible = true});

  @override
  State<CategoryBudgetScreen> createState() => _CategoryBudgetScreenState();
}

class _CategoryBudgetScreenState extends State<CategoryBudgetScreen>
    with SingleTickerProviderStateMixin {
  static const _categories = <String, ({IconData icon, String label})>{
    'food':         (icon: Icons.rice_bowl_outlined,       label: '食費'),
    'dining_out':   (icon: Icons.restaurant_outlined,      label: '外食費'),
    'daily':        (icon: Icons.shopping_basket_outlined, label: '日用品'),
    'transport':    (icon: Icons.train_outlined,           label: '交通費'),
    'clothing':     (icon: Icons.checkroom_outlined,       label: '衣服'),
    'social':       (icon: Icons.people_outline,           label: '交際費'),
    'hobby':        (icon: Icons.sports_esports_outlined,  label: '趣味'),
    'medical':      (icon: Icons.local_hospital_outlined,  label: '医療・健康'),
    'education':    (icon: Icons.menu_book_outlined,       label: '教育・書籍'),
    'utility':      (icon: Icons.bolt_outlined,            label: '光熱費'),
    'subscription': (icon: Icons.subscriptions_outlined,  label: 'サブスク'),
    'other':        (icon: Icons.more_horiz,               label: 'その他雑費'),
  };

  static const _budgetKey = 'budget_monthly';

  final _api = ApiService();
  final _fmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
  final Map<String, int> _budgets = {};
  int _totalBudget = 0;
  bool _loading = true;

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
    // まずSharedPrefsから読み込む
    for (final key in _categories.keys) {
      _budgets[key] = prefs.getInt('category_budget_$key') ?? 0;
    }
    // APIから取得してSharedPrefsを上書き（マイグレーション兼同期）
    try {
      final ym = DateTime.now();
      final yearMonth = '${ym.year}-${ym.month.toString().padLeft(2, '0')}';
      final data = await _api.get('/budgets/$yearMonth');
      final apiBudgets = data.map((k, v) => MapEntry(k, (v as num).toInt()));
      if (apiBudgets.isNotEmpty) {
        for (final key in _categories.keys) {
          _budgets[key] = apiBudgets[key] ?? 0;
        }
        // SharedPrefsにも反映
        for (final e in _budgets.entries) {
          await prefs.setInt('category_budget_${e.key}', e.value);
        }
      } else {
        // DBが空 → ローカルデータをAPIへ初回アップロード
        final nonZero = {
          for (final e in _budgets.entries) if (e.value > 0) e.key: e.value
        };
        if (nonZero.isNotEmpty) {
          await _api.patch('/budgets/$yearMonth', body: nonZero);
        }
      }
    } catch (_) {
      // API失敗時はSharedPrefsのままで続行
    }
    // カテゴリ予算の合計を月の予算として自動反映
    final computed = _budgets.values.fold(0, (s, v) => s + v);
    _totalBudget = computed;
    await prefs.setInt(_budgetKey, _totalBudget);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _persist({bool updateTotal = true}) async {
    final prefs = await SharedPreferences.getInstance();
    for (final e in _budgets.entries) {
      await prefs.setInt('category_budget_${e.key}', e.value);
    }
    if (updateTotal) {
      // カテゴリ合計を月の予算として保存
      final computed = _budgets.values.fold(0, (s, v) => s + v);
      _totalBudget = computed;
      await prefs.setInt(_budgetKey, _totalBudget);
    }
    // APIにも保存
    try {
      final ym = DateTime.now();
      final yearMonth = '${ym.year}-${ym.month.toString().padLeft(2, '0')}';
      await _api.patch('/budgets/$yearMonth', body: Map.from(_budgets));
    } catch (_) {
      // API失敗時はローカル保存のみで続行
    }
  }

  void _openTotalBudgetEditor() {
    final colors = context.colors;
    final ctrl = TextEditingController(
      text: _totalBudget > 0 ? _totalBudget.toString() : '',
    );

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
                      child: Icon(Icons.wallet_outlined,
                          color: colors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Text('月に使えるお金',
                        style: camillBodyStyle(20, colors.textPrimary,
                            weight: FontWeight.w700)),
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
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.surfaceBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('¥',
                            style: camillBodyStyle(26, colors.textMuted,
                                weight: FontWeight.w500)),
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
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: false, signed: false),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              style: camillBodyStyle(32, colors.textPrimary,
                                  weight: FontWeight.w700),
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: camillBodyStyle(32, colors.textMuted,
                                    weight: FontWeight.w700),
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
                            child: Icon(Icons.cancel,
                                color: colors.textMuted, size: 22),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final val = int.tryParse(ctrl.text) ?? 0;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt(_budgetKey, val);
                      if (mounted) setState(() => _totalBudget = val);
                      await _persist(updateTotal: false);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text('設定する',
                        style: camillBodyStyle(16, Colors.white,
                            weight: FontWeight.w600)),
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

  void _openEditor(String key) {
    final colors = context.colors;
    final meta = _categories[key]!;
    final ctrl = TextEditingController(
      text: (_budgets[key] ?? 0) > 0 ? (_budgets[key]!).toString() : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AnimatedPadding(
        // キーボード表示でシートが押し上がる
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ハンドル
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // カテゴリヘッダー
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
                    Text(meta.label,
                        style: camillBodyStyle(20, colors.textPrimary,
                            weight: FontWeight.w700)),
                    const Spacer(),
                    if ((_budgets[key] ?? 0) > 0)
                      GestureDetector(
                        onTap: () {
                          ctrl.clear();
                          setSheet(() {});
                        },
                        child: Text('削除',
                            style: camillBodyStyle(14, const Color(0xFFFF3B30))),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 大きな入力欄
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  // フォーカスリングがはみ出さないよう clip
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.surfaceBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('¥',
                          style: camillBodyStyle(26, colors.textMuted,
                              weight: FontWeight.w500)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Theme(
                          // スプラッシュ・フォーカスアニメを消す
                          data: Theme.of(ctx).copyWith(
                            splashFactory: NoSplash.splashFactory,
                            highlightColor: Colors.transparent,
                          ),
                          child: TextField(
                            controller: ctrl,
                            autofocus: true,
                            // 純粋な数字キーパッド（電話キーパッドでない）
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: false, signed: false),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: camillBodyStyle(32, colors.textPrimary,
                                weight: FontWeight.w700),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: camillBodyStyle(32, colors.textMuted,
                                  weight: FontWeight.w700),
                              // 全ボーダー状態を none にしてフォーカスリング消去
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
                          child: Icon(Icons.cancel,
                              color: colors.textMuted, size: 22),
                        ),
                    ],
                  ),
                ),
                ), // ClipRRect
              ),
              const SizedBox(height: 20),
              // 決定ボタン
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final val = int.tryParse(ctrl.text) ?? 0;
                      setState(() => _budgets[key] = val);
                      await _persist();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text('設定する',
                        style: camillBodyStyle(16, Colors.white,
                            weight: FontWeight.w600)),
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

    // 'other'(その他雑費)は予算未設定でも必ず設定済みセクションに表示
    final setItems = _categories.entries
        .where((e) => (_budgets[e.key] ?? 0) > 0 || e.key == 'other')
        .toList();
    final unsetItems = _categories.entries
        .where((e) => (_budgets[e.key] ?? 0) == 0 && e.key != 'other')
        .toList();

    final totalAllocated = _budgets.values.fold(0, (s, v) => s + v);

    final scaffold = Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('カテゴリ予算',
            style: camillBodyStyle(17, colors.textPrimary,
                weight: FontWeight.w600)),
        leading: widget.dismissible
            ? IconButton(
                icon: Icon(Icons.close, color: colors.textSecondary),
                onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
              )
            : IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: colors.textPrimary, size: 20),
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
                  children: _buildListItems(colors, totalAllocated, setItems, unsetItems),
                ),
              )
            : ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
                children: _buildListItems(colors, totalAllocated, setItems, unsetItems),
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

  List<Widget> _buildListItems(
    CamillColors colors,
    int totalAllocated,
    List<MapEntry<String, ({IconData icon, String label})>> setItems,
    List<MapEntry<String, ({IconData icon, String label})>> unsetItems,
  ) {
    return [
          // ── Monthly budget header ───────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 20),
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
                    Icon(Icons.wallet_outlined,
                        size: 14, color: colors.textMuted),
                    const SizedBox(width: 5),
                    Text('月に使えるお金',
                        style: camillBodyStyle(12, colors.textMuted,
                            weight: FontWeight.w500)),
                    const Spacer(),
                    GestureDetector(
                      onTap: _openTotalBudgetEditor,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('変更',
                            style: camillBodyStyle(12, colors.primary,
                                weight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  totalAllocated > 0
                      ? _fmt.format(_totalBudget)
                      : '¥ ---',
                  style: camillBodyStyle(32, colors.textPrimary,
                      weight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 11, color: colors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'カテゴリ予算の合計から自動計算',
                      style: camillBodyStyle(11, colors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (setItems.isNotEmpty) ...[
            _sectionLabel('設定済み (${setItems.length})', colors),
            ...setItems.map((e) => _buildRow(e.key, e.value, colors)),
            const SizedBox(height: 20),
          ],
          _sectionLabel(
              unsetItems.isEmpty
                  ? '未設定 (0)'
                  : '未設定 (${unsetItems.length})',
              colors),
          if (unsetItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('全カテゴリ設定済みです',
                    style: camillBodyStyle(13, colors.textMuted)),
              ),
            )
          else
            ...unsetItems.map((e) => _buildRow(e.key, e.value, colors)),
    ];
  }

  Widget _sectionLabel(String text, CamillColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(text,
          style: camillBodyStyle(12, colors.textMuted,
              weight: FontWeight.w600)),
    );
  }

  Widget _buildRow(
      String key, ({IconData icon, String label}) meta, CamillColors colors) {
    final budget = _budgets[key] ?? 0;
    final hasValue = budget > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CamillCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => _openEditor(key),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: hasValue ? colors.primaryLight : colors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(meta.icon,
                  color: hasValue ? colors.primary : colors.textMuted,
                  size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(meta.label,
                  style: camillBodyStyle(14, colors.textPrimary)),
            ),
            if (hasValue)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_fmt.format(budget),
                    style: camillBodyStyle(13, colors.primary,
                        weight: FontWeight.w600)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.surfaceBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 13, color: colors.textMuted),
                    const SizedBox(width: 3),
                    Text('設定する',
                        style: camillBodyStyle(13, colors.textMuted)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
