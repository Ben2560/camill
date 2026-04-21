import 'dart:math' show max;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../shared/models/summary_model.dart';
import '../../../shared/services/api_service.dart';
import '../../receipt/services/receipt_service.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/pull_to_refresh.dart';

// ── ChartTab: period selector + view switcher ─────────────────────────────

class ChartTab extends StatefulWidget {
  final NumberFormat currencyFmt;
  final ValueNotifier<double> dismissOffset;
  final VoidCallback onDismissEnd;
  final bool Function() isDismissing;
  const ChartTab({
    super.key,
    required this.currencyFmt,
    required this.dismissOffset,
    required this.onDismissEnd,
    required this.isDismissing,
  });

  @override
  State<ChartTab> createState() => ChartTabState();
}

class ChartTabState extends State<ChartTab> {
  int _periodIndex = 1; // 0=週, 1=月, 2=年

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: colors.background,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PeriodSelector(
                selected: _periodIndex,
                colors: colors,
                onChanged: (i) => setState(() => _periodIndex = i),
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (_periodIndex) {
            0 => WeekView(
              currencyFmt: widget.currencyFmt,
              dismissOffset: widget.dismissOffset,
              onDismissEnd: widget.onDismissEnd,
              isDismissing: widget.isDismissing,
            ),
            2 => YearView(
              currencyFmt: widget.currencyFmt,
              dismissOffset: widget.dismissOffset,
              onDismissEnd: widget.onDismissEnd,
              isDismissing: widget.isDismissing,
            ),
            _ => MonthView(
              currencyFmt: widget.currencyFmt,
              dismissOffset: widget.dismissOffset,
              onDismissEnd: widget.onDismissEnd,
              isDismissing: widget.isDismissing,
            ),
          },
        ),
      ],
    );
  }
}

// ── MonthView ─────────────────────────────────────────────────────────────

class MonthView extends StatefulWidget {
  final NumberFormat currencyFmt;
  final ValueNotifier<double> dismissOffset;
  final VoidCallback onDismissEnd;
  final bool Function() isDismissing;
  const MonthView({
    super.key,
    required this.currencyFmt,
    required this.dismissOffset,
    required this.onDismissEnd,
    required this.isDismissing,
  });

  @override
  State<MonthView> createState() => MonthViewState();
}

class MonthViewState extends State<MonthView> {
  final _receiptService = ReceiptService();
  final _now = DateTime(DateTime.now().year, DateTime.now().month);
  List<DateTime> _availableMonths = [];
  int _monthsVersion = 0;
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _availableMonths = [_now];
    _pageController = PageController(initialPage: 0);
    _loadAvailableMonths();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableMonths() async {
    try {
      final rawMonths = await _receiptService.getActiveMonths();
      final months = rawMonths.map((s) {
        final parts = s.split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]));
      }).toList();
      if (!months.any((m) => m.year == _now.year && m.month == _now.month)) {
        months.add(_now);
      }
      months.sort((a, b) => a.compareTo(b));
      if (!mounted) return;
      _pageController.dispose();
      setState(() {
        _availableMonths = months;
        _pageController = PageController(initialPage: months.length - 1);
        _monthsVersion++;
      });
    } catch (e) {
      debugPrint('_loadAvailableMonths failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      key: ValueKey(_monthsVersion),
      controller: _pageController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: _availableMonths.length,
      itemBuilder: (context, page) {
        final month = _availableMonths[page];
        final isLast = page == _availableMonths.length - 1;
        return MonthPageContent(
          key: ValueKey(month),
          month: month,
          currencyFmt: widget.currencyFmt,
          dismissOffset: widget.dismissOffset,
          onDismissEnd: widget.onDismissEnd,
          isDismissing: widget.isDismissing,
          onPrev: page == 0
              ? null
              : () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                ),
          onNext: isLast
              ? null
              : () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                ),
        );
      },
    );
  }
}

// ── MonthPageContent: 各月のコンテンツ ────────────────────────────────────

class MonthPageContent extends StatefulWidget {
  final DateTime month;
  final NumberFormat currencyFmt;
  final ValueNotifier<double> dismissOffset;
  final VoidCallback onDismissEnd;
  final bool Function() isDismissing;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const MonthPageContent({
    super.key,
    required this.month,
    required this.currencyFmt,
    required this.dismissOffset,
    required this.onDismissEnd,
    required this.isDismissing,
    required this.onPrev,
    required this.onNext,
  });

  @override
  State<MonthPageContent> createState() => MonthPageContentState();
}

class MonthPageContentState extends State<MonthPageContent> {
  final _api = ApiService();
  MonthlySummary? _summary;
  bool _loading = true;
  final _scrollController = ScrollController();
  double _pullDistance = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final yearMonth = DateFormat('yyyy-MM').format(widget.month);
      final data = await _api.get(
        '/summary/monthly',
        query: {'year_month': yearMonth},
      );
      if (!mounted) return;
      setState(() {
        _summary = MonthlySummary.fromJson(data);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final categories = _summary?.byCategory ?? [];
    final recentReceipts = _summary?.recentReceipts ?? [];
    // totalExpense を使うことでカテゴリ合計と支出合計を一致させる
    final int total =
        _summary?.totalExpense ??
        categories.fold<int>(0, (s, e) => s + e.amount);

    return LoadingOverlay(
      isLoading: _loading,
      child: Stack(
        children: [
          Listener(
            onPointerMove: (e) {
              if (widget.isDismissing()) return;
              if (_scrollController.hasClients &&
                  _scrollController.position.pixels <= 0 &&
                  e.delta.dy > 0) {
                _pullDistance += e.delta.dy;
                widget.dismissOffset.value = _pullDistance;
              } else if (e.delta.dy < 0 && _pullDistance > 0) {
                _pullDistance = 0;
                widget.dismissOffset.value = 0;
              }
            },
            onPointerUp: (_) {
              if (widget.isDismissing()) return;
              widget.onDismissEnd();
              _pullDistance = 0;
            },
            onPointerCancel: (_) {
              if (widget.isDismissing()) return;
              _pullDistance = 0;
              widget.dismissOffset.value = 0;
            },
            child: ListView(
              controller: _scrollController,
              physics: const DismissScrollPhysicsWithTopBounce(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              children: [
                DateNavRow(
                  label: DateFormat('yyyy年M月').format(widget.month),
                  onPrev: widget.onPrev,
                  onNext: widget.onNext,
                  colors: colors,
                ),
                const SizedBox(height: 12),
                SummaryCard(
                  totalExpense: _summary?.totalExpense ?? 0,
                  totalIncome: _summary?.totalIncome ?? 0,
                  currencyFmt: widget.currencyFmt,
                  colors: colors,
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  CategoryPieCard(
                    categories: categories,
                    total: total,
                    currencyFmt: widget.currencyFmt,
                    colors: colors,
                  ),
                ],
                if (recentReceipts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  RecentReceiptsCard(
                    receipts: recentReceipts,
                    currencyFmt: widget.currencyFmt,
                    colors: colors,
                  ),
                ],
                if (categories.isEmpty && recentReceipts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: EmptyState()),
                  ),
              ],
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
        ],
      ), // Stack
    ); // LoadingOverlay
  }
}

// ── WeekView ──────────────────────────────────────────────────────────────

class WeekView extends StatefulWidget {
  final NumberFormat currencyFmt;
  final ValueNotifier<double> dismissOffset;
  final VoidCallback onDismissEnd;
  final bool Function() isDismissing;
  const WeekView({
    super.key,
    required this.currencyFmt,
    required this.dismissOffset,
    required this.onDismissEnd,
    required this.isDismissing,
  });

  @override
  State<WeekView> createState() => WeekViewState();
}

class WeekViewState extends State<WeekView> {
  final _api = ApiService();
  late DateTime _weekStart;
  WeeklySummary? _summary;
  bool _loading = true;
  final _scrollController = ScrollController();
  double _pullDistance = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final startDate = DateFormat('yyyy-MM-dd').format(_weekStart);
      final data = await _api.get(
        '/summary/weekly',
        query: {'start_date': startDate},
      );
      if (!mounted) return;
      setState(() {
        _summary = WeeklySummary.fromJson(data);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String get _weekLabel {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    if (_weekStart.month == weekEnd.month) {
      return '${DateFormat('yyyy年M月d日').format(_weekStart)}〜${DateFormat('d日').format(weekEnd)}';
    }
    return '${DateFormat('M月d日').format(_weekStart)}〜${DateFormat('M月d日').format(weekEnd)}';
  }

  bool get _isCurrentWeek {
    final now = DateTime.now();
    final current = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return _weekStart.isAtSameMomentAs(current);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DateNavRow(
          label: _weekLabel,
          fontSize: 13,
          onPrev: () {
            setState(
              () => _weekStart = _weekStart.subtract(const Duration(days: 7)),
            );
            _load();
          },
          onNext: _isCurrentWeek
              ? null
              : () {
                  setState(
                    () => _weekStart = _weekStart.add(const Duration(days: 7)),
                  );
                  _load();
                },
          colors: colors,
        ),
        Expanded(
          child: LoadingOverlay(
            isLoading: _loading,
            child: Stack(
              children: [
                Listener(
                  onPointerMove: (e) {
                    if (widget.isDismissing()) return;
                    if (_scrollController.hasClients &&
                        _scrollController.position.pixels <= 0 &&
                        e.delta.dy > 0) {
                      _pullDistance += e.delta.dy;
                      widget.dismissOffset.value = _pullDistance;
                    } else if (e.delta.dy < 0 && _pullDistance > 0) {
                      _pullDistance = 0;
                      widget.dismissOffset.value = 0;
                    }
                  },
                  onPointerUp: (_) {
                    if (widget.isDismissing()) return;
                    widget.onDismissEnd();
                    _pullDistance = 0;
                  },
                  onPointerCancel: (_) {
                    if (widget.isDismissing()) return;
                    _pullDistance = 0;
                    widget.dismissOffset.value = 0;
                  },
                  child: ListView(
                    controller: _scrollController,
                    physics: const DismissScrollPhysicsWithTopBounce(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    children: [
                      if (_summary == null) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: EmptyState()),
                        ),
                      ] else ...[
                        SummaryCard(
                          totalExpense: _summary!.totalExpense,
                          totalIncome: _summary!.totalIncome,
                          currencyFmt: widget.currencyFmt,
                          colors: colors,
                        ),
                        if (_summary!.byDay.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          DayBarChartCard(
                            days: _summary!.byDay,
                            weekStart: _weekStart,
                            colors: colors,
                          ),
                        ],
                        if (_summary!.byCategory.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          CategoryPieCard(
                            categories: _summary!.byCategory,
                            total: _summary!.totalExpense,
                            currencyFmt: widget.currencyFmt,
                            colors: colors,
                          ),
                        ],
                      ],
                    ],
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
                          colors: [
                            colors.background,
                            colors.background.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ), // Stack
          ), // LoadingOverlay
        ), // Expanded
      ],
    );
  }
}

// ── YearView ──────────────────────────────────────────────────────────────

class YearView extends StatefulWidget {
  final NumberFormat currencyFmt;
  final ValueNotifier<double> dismissOffset;
  final VoidCallback onDismissEnd;
  final bool Function() isDismissing;
  const YearView({
    super.key,
    required this.currencyFmt,
    required this.dismissOffset,
    required this.onDismissEnd,
    required this.isDismissing,
  });

  @override
  State<YearView> createState() => YearViewState();
}

class YearViewState extends State<YearView> {
  final _api = ApiService();
  int _year = DateTime.now().year;
  YearlySummary? _summary;
  bool _loading = true;
  final _scrollController = ScrollController();
  double _pullDistance = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await _api.get(
        '/summary/yearly',
        query: {'year': _year.toString()},
      );
      if (!mounted) return;
      setState(() {
        _summary = YearlySummary.fromJson(data);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentYear = DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DateNavRow(
          label: '$_year年',
          onPrev: () {
            setState(() => _year--);
            _load();
          },
          onNext: _year >= currentYear
              ? null
              : () {
                  setState(() => _year++);
                  _load();
                },
          colors: colors,
        ),
        Expanded(
          child: LoadingOverlay(
            isLoading: _loading,
            child: Stack(
              children: [
                Listener(
                  onPointerMove: (e) {
                    if (widget.isDismissing()) return;
                    if (_scrollController.hasClients &&
                        _scrollController.position.pixels <= 0 &&
                        e.delta.dy > 0) {
                      _pullDistance += e.delta.dy;
                      widget.dismissOffset.value = _pullDistance;
                    } else if (e.delta.dy < 0 && _pullDistance > 0) {
                      _pullDistance = 0;
                      widget.dismissOffset.value = 0;
                    }
                  },
                  onPointerUp: (_) {
                    if (widget.isDismissing()) return;
                    widget.onDismissEnd();
                    _pullDistance = 0;
                  },
                  onPointerCancel: (_) {
                    if (widget.isDismissing()) return;
                    _pullDistance = 0;
                    widget.dismissOffset.value = 0;
                  },
                  child: ListView(
                    controller: _scrollController,
                    physics: const DismissScrollPhysicsWithTopBounce(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    children: [
                      if (_summary == null) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: EmptyState()),
                        ),
                      ] else ...[
                        SummaryCard(
                          totalExpense: _summary!.totalExpense,
                          totalIncome: _summary!.totalIncome,
                          currencyFmt: widget.currencyFmt,
                          colors: colors,
                        ),
                        if (_summary!.byMonth.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          MonthBarChartCard(
                            months: _summary!.byMonth,
                            colors: colors,
                          ),
                        ],
                        if (_summary!.byCategory.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          CategoryPieCard(
                            categories: _summary!.byCategory,
                            total: _summary!.totalExpense,
                            currencyFmt: widget.currencyFmt,
                            colors: colors,
                          ),
                        ],
                      ],
                    ],
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
                          colors: [
                            colors.background,
                            colors.background.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ), // Stack
          ), // LoadingOverlay
        ), // Expanded
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────

class DateNavRow extends StatelessWidget {
  final String label;
  final double fontSize;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final CamillColors colors;

  const DateNavRow({
    super.key,
    required this.label,
    this.fontSize = 16,
    required this.onPrev,
    required this.onNext,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.chevron_left,
            color: onPrev == null ? colors.surfaceBorder : colors.textSecondary,
          ),
          onPressed: onPrev,
        ),
        Text(label, style: camillHeadingStyle(fontSize, colors.textPrimary)),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: onNext == null ? colors.surfaceBorder : colors.textSecondary,
          ),
          onPressed: onNext,
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  final int totalExpense;
  final int totalIncome;
  final NumberFormat currencyFmt;
  final CamillColors colors;

  const SummaryCard({
    super.key,
    required this.totalExpense,
    required this.totalIncome,
    required this.currencyFmt,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final net = totalIncome - totalExpense;
    const expenseColor = Color(0xFFE53935);
    const incomeColor = Color(0xFF43A047);
    final netColor = net >= 0 ? incomeColor : expenseColor;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.surfaceBorder),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: SummaryItem(
              label: '支出',
              amount: totalExpense,
              color: expenseColor,
              currencyFmt: currencyFmt,
              colors: colors,
            ),
          ),
          Container(width: 1, height: 36, color: colors.surfaceBorder),
          Expanded(
            child: SummaryItem(
              label: '収入',
              amount: totalIncome,
              color: incomeColor,
              currencyFmt: currencyFmt,
              colors: colors,
            ),
          ),
          Container(width: 1, height: 36, color: colors.surfaceBorder),
          Expanded(
            child: SummaryItem(
              label: '収支',
              amount: net,
              color: netColor,
              currencyFmt: currencyFmt,
              colors: colors,
              prefix: net > 0 ? '+' : '',
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryItem extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final NumberFormat currencyFmt;
  final CamillColors colors;
  final String prefix;

  const SummaryItem({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    required this.currencyFmt,
    required this.colors,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: camillBodyStyle(11, colors.textMuted)),
        const SizedBox(height: 4),
        Text(
          '$prefix${currencyFmt.format(amount.abs())}',
          style: camillAmountStyle(13, color),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class CategoryPieCard extends StatelessWidget {
  final List<CategorySummary> categories;
  final int total;
  final NumberFormat currencyFmt;
  final CamillColors colors;

  const CategoryPieCard({
    super.key,
    required this.categories,
    required this.total,
    required this.currencyFmt,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'カテゴリ別支出',
            style: camillBodyStyle(
              14,
              colors.textPrimary,
              weight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: List.generate(
                        categories.length,
                        (i) => PieChartSectionData(
                          value: categories[i].amount.toDouble(),
                          color:
                              AppConstants.categoryColors[categories[i]
                                  .category] ??
                              Colors.grey,
                          radius: 45,
                          showTitle: false,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(categories.length.clamp(0, 6), (i) {
                    final c = categories[i];
                    final pct = total > 0
                        ? (c.amount / total * 100).round()
                        : 0;
                    final color =
                        AppConstants.categoryColors[c.category] ?? Colors.grey;
                    final label =
                        AppConstants.categoryLabels[c.category] ?? c.category;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$label $pct%',
                            style: camillBodyStyle(11, colors.textPrimary),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecentReceiptsCard extends StatelessWidget {
  final List<RecentReceipt> receipts;
  final NumberFormat currencyFmt;
  final CamillColors colors;

  const RecentReceiptsCard({
    super.key,
    required this.receipts,
    required this.currencyFmt,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            '最近の支出',
            style: camillBodyStyle(
              14,
              colors.textPrimary,
              weight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...receipts.map((r) {
            final dt = DateTime.tryParse(r.purchasedAt);
            final dateStr = dt != null ? DateFormat('M/d').format(dt) : '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.storeName,
                          style: camillBodyStyle(13, colors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (dateStr.isNotEmpty)
                          Text(
                            dateStr,
                            style: camillBodyStyle(11, colors.textMuted),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFmt.format(r.totalAmount),
                    style: camillAmountStyle(13, colors.textPrimary),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class DayBarChartCard extends StatelessWidget {
  final List<DailySummary> days;
  final DateTime weekStart;
  final CamillColors colors;

  const DayBarChartCard({
    super.key,
    required this.days,
    required this.weekStart,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['月', '火', '水', '木', '金', '土', '日'];
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final maxVal = days.fold(0.0, (m, d) => max(m, d.expense.toDouble()));
    final maxY = (maxVal > 0 ? maxVal * 1.25 : 1000).toDouble();

    return Container(
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
            '曜日別支出',
            style: camillBodyStyle(
              14,
              colors.textPrimary,
              weight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: List.generate(7, (i) {
                  final date = weekStart.add(Duration(days: i));
                  final isToday = date.isAtSameMomentAs(todayDate);
                  final dateStr = DateFormat('yyyy-MM-dd').format(date);
                  final dayData = days
                      .where((d) => d.date == dateStr)
                      .firstOrNull;
                  final expense = dayData?.expense.toDouble() ?? 0.0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: expense,
                        color: isToday
                            ? colors.primary
                            : colors.primary.withAlpha(100),
                        width: 22,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          dayLabels[value.toInt() % 7],
                          style: camillBodyStyle(11, colors.textMuted),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: colors.surfaceBorder, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthBarChartCard extends StatelessWidget {
  final List<MonthlyPoint> months;
  final CamillColors colors;

  const MonthBarChartCard({
    super.key,
    required this.months,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    const monthLabels = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
      '12',
    ];
    const expenseColor = Color(0xFFE53935);
    const incomeColor = Color(0xFF43A047);

    double maxVal = 0;
    for (final m in months) {
      maxVal = max(maxVal, max(m.expense.toDouble(), m.income.toDouble()));
    }
    final maxY = (maxVal > 0 ? maxVal * 1.25 : 1000).toDouble();

    return Container(
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
              Text(
                '月別収支',
                style: camillBodyStyle(
                  14,
                  colors.textPrimary,
                  weight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: expenseColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text('支出', style: camillBodyStyle(11, colors.textMuted)),
              const SizedBox(width: 10),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: incomeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text('収入', style: camillBodyStyle(11, colors.textMuted)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: List.generate(12, (i) {
                  final m = months.where((p) => p.month == i + 1).firstOrNull;
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 2,
                    barRods: [
                      BarChartRodData(
                        toY: m?.expense.toDouble() ?? 0,
                        color: expenseColor,
                        width: 8,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      BarChartRodData(
                        toY: m?.income.toDouble() ?? 0,
                        color: incomeColor,
                        width: 8,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          monthLabels[value.toInt() % 12],
                          style: camillBodyStyle(10, colors.textMuted),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: colors.surfaceBorder, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text('データがありません', style: camillBodyStyle(14, colors.textMuted));
  }
}

// ── PeriodSelector ────────────────────────────────────────────────────────

class PeriodSelector extends StatelessWidget {
  final int selected;
  final CamillColors colors;
  final ValueChanged<int> onChanged;

  const PeriodSelector({
    super.key,
    required this.selected,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['週', '月', '年'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final active = i == selected;
        return GestureDetector(
          onTap: () => onChanged(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: active ? colors.primary : colors.surfaceBorder,
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(left: 4),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 12,
                color: active ? colors.fabIcon : colors.textMuted,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}
