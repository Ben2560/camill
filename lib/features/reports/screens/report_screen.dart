import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/top_notification.dart';
import '../../../shared/widgets/camill_card.dart';
import '../../receipt/services/receipt_service.dart';
import '../../../shared/widgets/pull_to_refresh.dart';

// ── 外側：available months ベースの PageView ────────────────────────────────

class ReportScreen extends StatefulWidget {
  final int year;
  final int month;
  const ReportScreen({super.key, required this.year, required this.month});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  final _receiptService = ReceiptService();
  List<DateTime> _availableMonths = [];
  int _monthsVersion = 0;
  PageController _pageController = PageController();
  int _currentPage = 0;

  final _dismissOffset = ValueNotifier<double>(0);
  late final AnimationController _snapController;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dismissOffset.addListener(_onOffsetChanged);
    final initial = DateTime(widget.year, widget.month);
    _availableMonths = [initial];
    _pageController = PageController(initialPage: 0);
    _loadAvailableMonths(initial);
  }

  void _onOffsetChanged() {
    if (!mounted || _isDismissing) return;
    final limit = MediaQuery.of(context).size.height * 0.19;
    if (_dismissOffset.value >= limit) {
      _isDismissing = true;
      _dismissOffset.removeListener(_onOffsetChanged);
      _beginDismiss();
    }
  }

  void endDismiss() {
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
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableMonths(DateTime openedMonth) async {
    try {
      final rawMonths = await _receiptService.getActiveMonths();
      final months = rawMonths.map((s) {
        final parts = s.split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]));
      }).toList();

      // 開いた月は常に含める
      if (!months.any((m) => m.year == openedMonth.year && m.month == openedMonth.month)) {
        months.add(openedMonth);
      }
      months.sort((a, b) => a.compareTo(b));

      // 開いた月のインデックスを探す
      final idx = months.indexWhere(
        (m) => m.year == openedMonth.year && m.month == openedMonth.month,
      );

      if (!mounted) return;
      _pageController.dispose();
      setState(() {
        _availableMonths = months;
        _currentPage = idx;
        _pageController = PageController(initialPage: idx);
        _monthsVersion++;
      });
    } catch (e) {
      debugPrint('_loadAvailableMonths failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final current = _availableMonths[_currentPage];
    final title = '${current.year}年${current.month}月 やりくり詳細';
    final sh = MediaQuery.of(context).size.height;

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
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          scrolledUnderElevation: 0,
          title: Text(title, style: camillHeadingStyle(16, colors.textPrimary)),
          iconTheme: IconThemeData(color: colors.textSecondary),
        ),
        body: PageView.builder(
          key: ValueKey(_monthsVersion),
          controller: _pageController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: _availableMonths.length,
          onPageChanged: (page) => setState(() => _currentPage = page),
          itemBuilder: (context, page) {
            final month = _availableMonths[page];
            return _ReportPage(
              key: ValueKey(month),
              year: month.year,
              month: month.month,
              dismissOffset: _dismissOffset,
              onDismissEnd: endDismiss,
              isDismissing: () => _isDismissing,
            );
          },
        ),
      ),
    );
  }
}

// ── 各月のレポートコンテンツ ─────────────────────────────────────────────────

class _ReportPage extends StatefulWidget {
  final int year;
  final int month;
  final ValueNotifier<double> dismissOffset;
  final VoidCallback onDismissEnd;
  final bool Function() isDismissing;
  const _ReportPage({
    super.key,
    required this.year,
    required this.month,
    required this.dismissOffset,
    required this.onDismissEnd,
    required this.isDismissing,
  });

  @override
  State<_ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<_ReportPage> {
  final _api = ApiService();
  final _currencyFmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
  bool _loading = true;
  Map<String, dynamic>? _report;
  final _scrollController = ScrollController();
  double _pullDistance = 0;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReport({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final data = await _api.get(
          '/reports/monthly/${widget.year}/${widget.month}');
      setState(() => _report = data);
    } catch (e) {
      if (mounted) {
        showTopNotification(context, '読み込みに失敗しました: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LoadingOverlay(
      isLoading: _loading,
      child: Stack(
        children: [
          if (_report != null)
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
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(colors),
                  const SizedBox(height: 12),
                  _buildSavingsCard(colors),
                  const SizedBox(height: 12),
                  _buildScanCard(colors),
                  const SizedBox(height: 12),
                  _buildCategoryRanking(colors),
                  const SizedBox(height: 12),
                  _buildTopStoresCard(colors),
                  if (_isAiAvailable()) ...[
                    const SizedBox(height: 12),
                    _buildAiCard(colors),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: IgnorePointer(
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [colors.background, colors.background.withAlpha(0)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(CamillColors colors) {
    final r = _report!;
    final total = (r['total_expense'] as num?)?.toInt() ?? 0;
    final rate = (r['budget_achievement_rate'] as num?)?.toInt() ?? 0;
    final score = (r['score'] as num?)?.toInt() ?? 0;

    return CamillCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('収支サマリー',
                  style: camillBodyStyle(14, colors.textPrimary,
                      weight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('スコア $score点',
                    style: camillBodyStyle(12, colors.primary,
                        weight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AnimatedAmount(
            label: '総支出',
            amount: total,
            style: camillAmountStyle(32, colors.textPrimary),
            currencyFmt: _currencyFmt,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                rate >= 80 ? Icons.check_circle : Icons.warning_amber,
                color: rate >= 80 ? colors.success : colors.danger,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text('予算達成率 $rate%',
                  style: camillBodyStyle(
                      13, rate >= 80 ? colors.success : colors.danger,
                      weight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsCard(CamillColors colors) {
    final r = _report!;
    final discountSavings = (r['discount_savings'] as num?)?.toInt() ?? 0;
    final couponSavings = (r['coupon_savings'] as num?)?.toInt() ?? 0;
    final count = (r['coupon_count'] as num?)?.toInt() ?? 0;
    final loss = (r['unused_coupon_loss'] as num?)?.toInt() ?? 0;

    return CamillCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('割引・クーポン実績',
              style: camillBodyStyle(14, colors.textPrimary,
                  weight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: '割引節約',
                  value: _currencyFmt.format(discountSavings),
                  color: colors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  label: 'クーポン節約',
                  value: _currencyFmt.format(couponSavings),
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  label: '使用枚数',
                  value: '$count枚',
                  color: colors.primary,
                ),
              ),
            ],
          ),
          if (loss > 0) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: colors.danger),
                  const SizedBox(width: 6),
                  Text('未使用クーポン損失',
                      style: camillBodyStyle(12, colors.danger)),
                  const Spacer(),
                  Text(_currencyFmt.format(loss),
                      style: camillAmountStyle(13, colors.danger)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanCard(CamillColors colors) {
    final r = _report!;
    final count = (r['receipt_count'] as num?)?.toInt() ?? 0;
    final avg = (r['avg_per_day'] as num?)?.toInt() ?? 0;
    final max = (r['max_single_amount'] as num?)?.toInt() ?? 0;

    return CamillCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('スキャン実績',
              style: camillBodyStyle(14, colors.textPrimary,
                  weight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: '登録枚数',
                  value: '$count枚',
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  label: '1日平均',
                  value: _currencyFmt.format(avg),
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  label: '最大単価',
                  value: _currencyFmt.format(max),
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopStoresCard(CamillColors colors) {
    final r = _report!;
    final stores = (r['top_stores'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (stores.isEmpty) return const SizedBox.shrink();

    return CamillCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('よく使ったお店',
              style: camillBodyStyle(14, colors.textPrimary,
                  weight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...stores.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            final name = s['store_name'] as String? ?? '';
            final amount = (s['amount'] as num?)?.toInt() ?? 0;
            final visits = (s['visit_count'] as num?)?.toInt() ?? 0;
            final rankColors = [colors.primary, colors.textSecondary, colors.textMuted];
            final color = rankColors[i < 3 ? i : 2];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${i + 1}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(name,
                        style: camillBodyStyle(13, colors.textPrimary),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('$visits回',
                      style: camillBodyStyle(12, colors.textMuted)),
                  const SizedBox(width: 10),
                  Text(_currencyFmt.format(amount),
                      style: camillAmountStyle(14, colors.textPrimary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static const _kQuotaSentinel = '__quota__';

  bool _isAiAvailable() {
    final comment = _report!['ai_comment'] as String? ?? '';
    return comment.isNotEmpty;
  }

  Widget _buildAiCard(CamillColors colors) {
    final r = _report!;
    final comment = r['ai_comment'] as String? ?? '';
    final goal = r['next_month_advice'] as String? ?? '';
    final isQuotaError = comment == _kQuotaSentinel;

    return CamillCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16,
                  color: isQuotaError ? colors.textMuted : colors.primary),
              const SizedBox(width: 6),
              Text('AIアドバイス',
                  style: camillBodyStyle(14, colors.textPrimary,
                      weight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          if (isQuotaError)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.danger.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.danger.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: colors.danger),
                  const SizedBox(width: 8),
                  Text('APIの上限に達しました。しばらくお待ちください。',
                      style: camillBodyStyle(12, colors.danger)),
                ],
              ),
            )
          else ...[
            Text(comment, style: camillBodyStyle(13, colors.textPrimary)),
            if (goal.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.flag_outlined, size: 14, color: colors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(goal,
                          style: camillBodyStyle(12, colors.primary)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  static const _categoryLabels = <String, String>{
    'food': '食費',
    'dining_out': '外食費',
    'daily': '日用品',
    'transport': '交通費',
    'clothing': '衣服',
    'social': '交際費',
    'hobby': '趣味',
    'medical': '医療・健康',
    'education': '教育・書籍',
    'subscription': 'サブスク',
    'utility': '光熱費',
    'other': 'その他',
  };

  Widget _buildCategoryRanking(CamillColors colors) {
    final r = _report!;
    final cats = (r['top_categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final medals = ['🥇', '🥈', '🥉'];
    final medalColors = [
      const Color(0xFFFFB300),
      const Color(0xFF9E9E9E),
      const Color(0xFF8D6E63),
    ];

    return CamillCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('支出TOP3',
              style: camillBodyStyle(14, colors.textPrimary,
                  weight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...cats.asMap().entries.map((e) {
            final i = e.key;
            final cat = e.value;
            final amount = (cat['amount'] as num?)?.toInt() ?? 0;
            final key = cat['category'] as String? ?? '';
            final label = _categoryLabels[key] ?? key;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(medals[i < 3 ? i : 2],
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(label,
                        style: camillBodyStyle(14, colors.textPrimary)),
                  ),
                  Text(_currencyFmt.format(amount),
                      style: camillAmountStyle(
                          15, i < 3 ? medalColors[i] : colors.textPrimary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

}

class _AnimatedAmount extends StatefulWidget {
  final String label;
  final int amount;
  final TextStyle style;
  final NumberFormat currencyFmt;

  const _AnimatedAmount({
    required this.label,
    required this.amount,
    required this.style,
    required this.currencyFmt,
  });

  @override
  State<_AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<_AnimatedAmount>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: camillBodyStyle(12, colors.textMuted)),
        AnimatedBuilder(
          animation: _anim,
          builder: (context2, child) => Text(
            widget.currencyFmt
                .format((_anim.value * widget.amount).toInt()),
            style: widget.style,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: camillBodyStyle(11, colors.textMuted)),
        ],
      ),
    );
  }
}
