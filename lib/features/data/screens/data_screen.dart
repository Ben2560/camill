import 'dart:math' show max;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../shared/models/summary_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/pull_to_refresh.dart';

class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text('コミュニティ', style: camillHeadingStyle(17, colors.textPrimary)),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_outlined, size: 56, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              'ただいま準備中…',
              style: camillBodyStyle(16, colors.textMuted, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 収支グラフ専用スクリーン ─────────────────────────────────────────────────

class BalanceChartScreen extends StatelessWidget {
  const BalanceChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currencyFmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        scrolledUnderElevation: 0,
        title: Text('収支グラフ', style: camillHeadingStyle(17, colors.textPrimary)),
        iconTheme: IconThemeData(color: colors.textSecondary),
        elevation: 0,
      ),
      body: _ChartTab(currencyFmt: currencyFmt),
    );
  }
}

// ── ChartTab: period selector + view switcher ─────────────────────────────

class _ChartTab extends StatefulWidget {
  final NumberFormat currencyFmt;
  const _ChartTab({required this.currencyFmt});

  @override
  State<_ChartTab> createState() => _ChartTabState();
}

class _ChartTabState extends State<_ChartTab> {
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
                _PeriodSelector(
                  selected: _periodIndex,
                  colors: colors,
                  onChanged: (i) => setState(() => _periodIndex = i),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (_periodIndex) {
              0 => _WeekView(currencyFmt: widget.currencyFmt),
              2 => _YearView(currencyFmt: widget.currencyFmt),
              _ => _MonthView(currencyFmt: widget.currencyFmt),
            },
          ),
        ],
    );
  }
}

// ── MonthView ─────────────────────────────────────────────────────────────

class _MonthView extends StatefulWidget {
  final NumberFormat currencyFmt;
  const _MonthView({required this.currencyFmt});

  @override
  State<_MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends State<_MonthView> {
  late final PageController _pageController;
  static const _centerPage = 500;
  final _now = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _centerPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) =>
      DateTime(_now.year, _now.month - (_centerPage - page));

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      // centerPage+1 まで itemCount を設定し翌月以降を自然にブロック
      itemCount: _centerPage + 1,
      itemBuilder: (context, page) {
          final month = _monthForPage(page);
          final isCurrentMonth = page == _centerPage;
          return _MonthPageContent(
            key: ValueKey(month),
            month: month,
            currencyFmt: widget.currencyFmt,

            onPrev: () => _pageController.previousPage(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
            ),
            onNext: isCurrentMonth
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

class _MonthPageContent extends StatefulWidget {
  final DateTime month;
  final NumberFormat currencyFmt;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _MonthPageContent({
    super.key,
    required this.month,
    required this.currencyFmt,
    required this.onPrev,
    required this.onNext,
  });

  @override
  State<_MonthPageContent> createState() => _MonthPageContentState();
}

class _MonthPageContentState extends State<_MonthPageContent>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  MonthlySummary? _summary;
  bool _loading = true;
  int _dotsVisible = 0;
  bool _isRefreshing = false;
  bool _ignoreUntilTop = false;
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _load();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _loading = true);
    try {
      final yearMonth = DateFormat('yyyy-MM').format(widget.month);
      final data =
          await _api.get('/summary/monthly', query: {'year_month': yearMonth});
      if (!mounted) return;
      setState(() {
        _summary = MonthlySummary.fromJson(data);
        if (!silent) _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (!silent) setState(() => _loading = false);
    }
  }

  void _startSilentRefresh() {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _dotsVisible = 3;
      _ignoreUntilTop = true;
    });
    if (!_bounceController.isAnimating) _bounceController.repeat();
    _load(silent: true).then((_) {
      if (!mounted) return;
      _bounceController.stop();
      _bounceController.reset();
      setState(() {
        _isRefreshing = false;
        _dotsVisible = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    final categories = _summary?.byCategory ?? [];
    final recentReceipts = _summary?.recentReceipts ?? [];
    final total = categories.fold(0, (s, e) => s + e.amount);

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (_isRefreshing) return false;
            if (notification is ScrollUpdateNotification) {
              final pixels = notification.metrics.pixels;
              if (pixels >= 0) _ignoreUntilTop = false;
              if (_ignoreUntilTop) return false;
              if (pixels < 0) {
                final newDots =
                    pixels < -85 ? 3 : pixels < -55 ? 2 : pixels < -25 ? 1 : 0;
                if (newDots != _dotsVisible) {
                  setState(() => _dotsVisible = newDots);
                }
              } else if (_dotsVisible > 0) {
                _ignoreUntilTop = true;
                setState(() => _dotsVisible = 0);
              }
            } else if (notification is ScrollEndNotification) {
              if (!_isRefreshing) {
                if (_dotsVisible == 3) {
                  _startSilentRefresh();
                } else if (_dotsVisible > 0) {
                  _ignoreUntilTop = true;
                  setState(() => _dotsVisible = 0);
                }
              }
            }
            return false;
          },
          child: ListView(
            physics: const RefreshScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              _DateNavRow(
                label: DateFormat('yyyy年M月').format(widget.month),
                onPrev: widget.onPrev,
                onNext: widget.onNext,
                colors: colors,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                totalExpense: _summary?.totalExpense ?? 0,
                totalIncome: _summary?.totalIncome ?? 0,
                currencyFmt: widget.currencyFmt,
                colors: colors,
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 12),
                _CategoryPieCard(
                  categories: categories,
                  total: total,
                  currencyFmt: widget.currencyFmt,
                  colors: colors,
                ),
              ],
              if (recentReceipts.isNotEmpty) ...[
                const SizedBox(height: 12),
                _RecentReceiptsCard(
                  receipts: recentReceipts,
                  currencyFmt: widget.currencyFmt,
                  colors: colors,
                ),
              ],
              if (categories.isEmpty && recentReceipts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: _EmptyState()),
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
                  colors: [
                    colors.background,
                    colors.background.withAlpha(0),
                  ],
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
                  dotsVisible: _dotsVisible,
                  isRefreshing: _isRefreshing,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── WeekView ──────────────────────────────────────────────────────────────

class _WeekView extends StatefulWidget {
  final NumberFormat currencyFmt;
  const _WeekView({required this.currencyFmt});

  @override
  State<_WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<_WeekView>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late DateTime _weekStart;
  WeeklySummary? _summary;
  bool _loading = true;
  int _dotsVisible = 0;
  bool _isRefreshing = false;
  bool _ignoreUntilTop = false;
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    final now = DateTime.now();
    _weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    _load();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _loading = true);
    try {
      final startDate = DateFormat('yyyy-MM-dd').format(_weekStart);
      final data =
          await _api.get('/summary/weekly', query: {'start_date': startDate});
      if (!mounted) return;
      setState(() {
        _summary = WeeklySummary.fromJson(data);
        if (!silent) _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (!silent) setState(() => _loading = false);
    }
  }

  void _startSilentRefresh() {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _dotsVisible = 3;
      _ignoreUntilTop = true;
    });
    if (!_bounceController.isAnimating) _bounceController.repeat();
    _load(silent: true).then((_) {
      if (!mounted) return;
      _bounceController.stop();
      _bounceController.reset();
      setState(() {
        _isRefreshing = false;
        _dotsVisible = 0;
      });
    });
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
    final current = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return _weekStart.isAtSameMomentAs(current);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DateNavRow(
          label: _weekLabel,
          fontSize: 13,
          onPrev: () {
            _bounceController.stop();
            setState(() {
              _weekStart = _weekStart.subtract(const Duration(days: 7));
              _dotsVisible = 0;
              _isRefreshing = false;
              _ignoreUntilTop = false;
            });
            _load();
          },
          onNext: _isCurrentWeek
              ? null
              : () {
                  _bounceController.stop();
                  setState(() {
                    _weekStart = _weekStart.add(const Duration(days: 7));
                    _dotsVisible = 0;
                    _isRefreshing = false;
                    _ignoreUntilTop = false;
                  });
                  _load();
                },
          colors: colors,
        ),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: colors.primary))
              : Stack(
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (_isRefreshing) return false;
                        if (notification is ScrollUpdateNotification) {
                          final pixels = notification.metrics.pixels;
                          if (pixels >= 0) _ignoreUntilTop = false;
                          if (_ignoreUntilTop) return false;
                          if (pixels < 0) {
                            final newDots = pixels < -85
                                ? 3
                                : pixels < -55
                                    ? 2
                                    : pixels < -25
                                        ? 1
                                        : 0;
                            if (newDots != _dotsVisible) {
                              setState(() => _dotsVisible = newDots);
                            }
                                      } else if (_dotsVisible > 0) {
                            _ignoreUntilTop = true;
                            setState(() => _dotsVisible = 0);
                          }
                        } else if (notification is ScrollEndNotification) {
                          if (!_isRefreshing) {
                            if (_dotsVisible == 3) {
                              _startSilentRefresh();
                            } else if (_dotsVisible > 0) {
                              _ignoreUntilTop = true;
                              setState(() => _dotsVisible = 0);
                            }
                          }
                        }
                        return false;
                      },
                      child: ListView(
                        physics: const RefreshScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        children: [
                          if (_summary == null) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 48),
                              child: Center(child: _EmptyState()),
                            ),
                          ] else ...[
                            _SummaryCard(
                              totalExpense: _summary!.totalExpense,
                              totalIncome: _summary!.totalIncome,
                              currencyFmt: widget.currencyFmt,
                              colors: colors,
                            ),
                            if (_summary!.byDay.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _DayBarChartCard(
                                days: _summary!.byDay,
                                weekStart: _weekStart,
                                colors: colors,
                              ),
                            ],
                            if (_summary!.byCategory.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _CategoryPieCard(
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
                              dotsVisible: _dotsVisible,
                              isRefreshing: _isRefreshing,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ── YearView ──────────────────────────────────────────────────────────────

class _YearView extends StatefulWidget {
  final NumberFormat currencyFmt;
  const _YearView({required this.currencyFmt});

  @override
  State<_YearView> createState() => _YearViewState();
}

class _YearViewState extends State<_YearView>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  int _year = DateTime.now().year;
  YearlySummary? _summary;
  bool _loading = true;
  int _dotsVisible = 0;
  bool _isRefreshing = false;
  bool _ignoreUntilTop = false;
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _load();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _loading = true);
    try {
      final data =
          await _api.get('/summary/yearly', query: {'year': _year.toString()});
      if (!mounted) return;
      setState(() {
        _summary = YearlySummary.fromJson(data);
        if (!silent) _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (!silent) setState(() => _loading = false);
    }
  }

  void _startSilentRefresh() {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _dotsVisible = 3;
      _ignoreUntilTop = true;
    });
    if (!_bounceController.isAnimating) _bounceController.repeat();
    _load(silent: true).then((_) {
      if (!mounted) return;
      _bounceController.stop();
      _bounceController.reset();
      setState(() {
        _isRefreshing = false;
        _dotsVisible = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentYear = DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DateNavRow(
          label: '$_year年',
          onPrev: () {
            _bounceController.stop();
            setState(() {
              _year--;
              _dotsVisible = 0;
              _isRefreshing = false;
              _ignoreUntilTop = false;
            });
            _load();
          },
          onNext: _year >= currentYear
              ? null
              : () {
                  _bounceController.stop();
                  setState(() {
                    _year++;
                    _dotsVisible = 0;
                    _isRefreshing = false;
                    _ignoreUntilTop = false;
                  });
                  _load();
                },
          colors: colors,
        ),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: colors.primary))
              : Stack(
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (_isRefreshing) return false;
                        if (notification is ScrollUpdateNotification) {
                          final pixels = notification.metrics.pixels;
                          if (pixels >= 0) _ignoreUntilTop = false;
                          if (_ignoreUntilTop) return false;
                          if (pixels < 0) {
                            final newDots = pixels < -85
                                ? 3
                                : pixels < -55
                                    ? 2
                                    : pixels < -25
                                        ? 1
                                        : 0;
                            if (newDots != _dotsVisible) {
                              setState(() => _dotsVisible = newDots);
                            }
                                      } else if (_dotsVisible > 0) {
                            _ignoreUntilTop = true;
                            setState(() => _dotsVisible = 0);
                          }
                        } else if (notification is ScrollEndNotification) {
                          if (!_isRefreshing) {
                            if (_dotsVisible == 3) {
                              _startSilentRefresh();
                            } else if (_dotsVisible > 0) {
                              _ignoreUntilTop = true;
                              setState(() => _dotsVisible = 0);
                            }
                          }
                        }
                        return false;
                      },
                      child: ListView(
                        physics: const RefreshScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        children: [
                          if (_summary == null) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 48),
                              child: Center(child: _EmptyState()),
                            ),
                          ] else ...[
                            _SummaryCard(
                              totalExpense: _summary!.totalExpense,
                              totalIncome: _summary!.totalIncome,
                              currencyFmt: widget.currencyFmt,
                              colors: colors,
                            ),
                            if (_summary!.byMonth.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _MonthBarChartCard(
                                months: _summary!.byMonth,
                                colors: colors,
                              ),
                            ],
                            if (_summary!.byCategory.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _CategoryPieCard(
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
                              dotsVisible: _dotsVisible,
                              isRefreshing: _isRefreshing,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────

class _DateNavRow extends StatelessWidget {
  final String label;
  final double fontSize;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final CamillColors colors;

  const _DateNavRow({
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
          icon: Icon(Icons.chevron_left, color: colors.textSecondary),
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

class _SummaryCard extends StatelessWidget {
  final int totalExpense;
  final int totalIncome;
  final NumberFormat currencyFmt;
  final CamillColors colors;

  const _SummaryCard({
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
            child: _SummaryItem(
              label: '支出',
              amount: totalExpense,
              color: expenseColor,
              currencyFmt: currencyFmt,
              colors: colors,
            ),
          ),
          Container(width: 1, height: 36, color: colors.surfaceBorder),
          Expanded(
            child: _SummaryItem(
              label: '収入',
              amount: totalIncome,
              color: incomeColor,
              currencyFmt: currencyFmt,
              colors: colors,
            ),
          ),
          Container(width: 1, height: 36, color: colors.surfaceBorder),
          Expanded(
            child: _SummaryItem(
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

class _SummaryItem extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final NumberFormat currencyFmt;
  final CamillColors colors;
  final String prefix;

  const _SummaryItem({
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

class _CategoryPieCard extends StatelessWidget {
  final List<CategorySummary> categories;
  final int total;
  final NumberFormat currencyFmt;
  final CamillColors colors;

  const _CategoryPieCard({
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
          Text('カテゴリ別支出',
              style: camillBodyStyle(14, colors.textPrimary,
                  weight: FontWeight.bold)),
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
                          color: AppConstants.categoryColors[
                                  categories[i].category] ??
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
                  children: List.generate(
                    categories.length.clamp(0, 6),
                    (i) {
                      final c = categories[i];
                      final pct =
                          total > 0 ? (c.amount / total * 100).round() : 0;
                      final color = AppConstants.categoryColors[c.category] ??
                          Colors.grey;
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
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentReceiptsCard extends StatelessWidget {
  final List<RecentReceipt> receipts;
  final NumberFormat currencyFmt;
  final CamillColors colors;

  const _RecentReceiptsCard({
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
          Text('最近の支出',
              style: camillBodyStyle(14, colors.textPrimary,
                  weight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...receipts.map((r) {
            final dt = DateTime.tryParse(r.purchasedAt);
            final dateStr =
                dt != null ? DateFormat('M/d').format(dt) : '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.storeName,
                            style: camillBodyStyle(13, colors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (dateStr.isNotEmpty)
                          Text(dateStr,
                              style: camillBodyStyle(11, colors.textMuted)),
                      ],
                    ),
                  ),
                  Text(currencyFmt.format(r.totalAmount),
                      style: camillAmountStyle(13, colors.textPrimary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DayBarChartCard extends StatelessWidget {
  final List<DailySummary> days;
  final DateTime weekStart;
  final CamillColors colors;

  const _DayBarChartCard({
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
          Text('曜日別支出',
              style: camillBodyStyle(14, colors.textPrimary,
                  weight: FontWeight.bold)),
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
                  final dayData =
                      days.where((d) => d.date == dateStr).firstOrNull;
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
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colors.surfaceBorder,
                    strokeWidth: 1,
                  ),
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

class _MonthBarChartCard extends StatelessWidget {
  final List<MonthlyPoint> months;
  final CamillColors colors;

  const _MonthBarChartCard({
    required this.months,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    const monthLabels = [
      '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'
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
              Text('月別収支',
                  style: camillBodyStyle(14, colors.textPrimary,
                      weight: FontWeight.bold)),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                    color: expenseColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text('支出', style: camillBodyStyle(11, colors.textMuted)),
              const SizedBox(width: 10),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                    color: incomeColor, shape: BoxShape.circle),
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
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colors.surfaceBorder,
                    strokeWidth: 1,
                  ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text('データがありません', style: camillBodyStyle(14, colors.textMuted));
  }
}

// ── PeriodSelector ────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final int selected;
  final CamillColors colors;
  final ValueChanged<int> onChanged;

  const _PeriodSelector({
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
