import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/top_notification.dart';
import '../../../shared/widgets/camill_card.dart';
import '../../../shared/widgets/pull_to_refresh.dart';

class ReportScreen extends StatefulWidget {
  final int year;
  final int month;
  const ReportScreen({super.key, required this.year, required this.month});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _currencyFmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
  bool _loading = true;
  Map<String, dynamic>? _report;
  int _dotsVisible = 0;
  bool _isRefreshing = false;
  bool _ignoreUntilTop = false;
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _loadReport();
  }

  @override
  void dispose() {
    _bounceController.dispose();
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

  void _startSilentRefresh() {
    if (_isRefreshing) return;
    setState(() { _isRefreshing = true; _dotsVisible = 3; _ignoreUntilTop = true; });
    if (!_bounceController.isAnimating) _bounceController.repeat();
    _loadReport(silent: true).then((_) {
      if (!mounted) return;
      _bounceController.stop(); _bounceController.reset();
      setState(() { _isRefreshing = false; _dotsVisible = 0; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title =
        '${widget.year}年${widget.month}月 やりくり詳細';

    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          scrolledUnderElevation: 0,
          title: Text(title,
              style: camillHeadingStyle(16, colors.textPrimary)),
          iconTheme: IconThemeData(color: colors.textSecondary),
        ),
        body: Stack(
          children: [
            if (_report != null)
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (_isRefreshing) return false;
                  if (notification is ScrollUpdateNotification) {
                    final pixels = notification.metrics.pixels;
                    if (pixels >= 0) _ignoreUntilTop = false;
                    if (_ignoreUntilTop) return false;
                    if (pixels < 0) {
                      final newDots = pixels < -85 ? 3 : pixels < -55 ? 2 : pixels < -25 ? 1 : 0;
                      if (newDots != _dotsVisible) setState(() => _dotsVisible = newDots);
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
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummaryCard(colors),
                    const SizedBox(height: 12),
                    _buildCouponCard(colors),
                    const SizedBox(height: 12),
                    _buildCategoryRanking(colors),
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
            Positioned(
              top: 4, left: 0, right: 0,
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

  Widget _buildCouponCard(CamillColors colors) {
    final r = _report!;
    final savings = (r['coupon_savings'] as num?)?.toInt() ?? 0;
    final count = (r['coupon_count'] as num?)?.toInt() ?? 0;
    final loss = (r['unused_coupon_loss'] as num?)?.toInt() ?? 0;

    return CamillCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('クーポン実績',
              style: camillBodyStyle(14, colors.textPrimary,
                  weight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: '節約',
                  value: _currencyFmt.format(savings),
                  color: colors.success,
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
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  label: '未使用損失',
                  value: _currencyFmt.format(loss),
                  color: loss > 0 ? colors.danger : colors.textMuted,
                ),
              ),
            ],
          ),
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
