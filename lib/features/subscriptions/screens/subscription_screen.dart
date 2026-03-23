import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../../../shared/widgets/camill_card.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {
  final _api = ApiService();
  final _currencyFmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
  late TabController _tabCtrl;
  bool _loading = true;
  List<Map<String, dynamic>> _confirmed = [];
  List<Map<String, dynamic>> _candidates = [];
  int _dotsVisible = 0;
  bool _isRefreshing = false;
  bool _ignoreUntilTop = false;
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _loadAll({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getAny('/subscriptions'),
        _api.getAny('/subscriptions/candidates'),
      ]);
      if (!mounted) return;
      setState(() {
        _confirmed = (results[0] as List).cast<Map<String, dynamic>>();
        _candidates = (results[1] as List).cast<Map<String, dynamic>>();
        if (!silent) _loading = false;
      });
    } catch (e) {
      // silently swallow
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  void _startSilentRefresh() {
    if (_isRefreshing) return;
    setState(() { _isRefreshing = true; _dotsVisible = 3; _ignoreUntilTop = true; });
    if (!_bounceController.isAnimating) _bounceController.repeat();
    _loadAll(silent: true).then((_) {
      if (!mounted) return;
      _bounceController.stop();
      _bounceController.reset();
      setState(() { _isRefreshing = false; _dotsVisible = 0; });
    });
  }

  Future<void> _confirmSubscription(String id) async {
    try {
      await _api.postAny('/subscriptions/$id/confirm', body: {});
      await _loadAll();
    } catch (e) {
      // silently swallow
    }
  }

  Future<void> _deleteSubscription(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('このサブスクリプションを削除しますか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('削除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.delete('/subscriptions/$id');
      await _loadAll();
    } catch (e) {
      // silently swallow
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          title: Text('サブスク管理', style: camillHeadingStyle(17, colors.textPrimary)),
          iconTheme: IconThemeData(color: colors.textSecondary),
          bottom: TabBar(
            controller: _tabCtrl,
            labelColor: colors.primary,
            unselectedLabelColor: colors.textMuted,
            indicatorColor: colors.primary,
            tabs: [
              Tab(text: '登録済み (${_confirmed.length})'),
              Tab(text: '候補 (${_candidates.length})'),
            ],
          ),
        ),
        body: Stack(
          children: [
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
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildConfirmedTab(colors),
                  _buildCandidatesTab(colors),
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

  Widget _buildConfirmedTab(CamillColors colors) {
    if (_confirmed.isEmpty) {
      return _EmptyState(
        icon: Icons.subscriptions_outlined,
        message: '登録済みのサブスクはありません',
        colors: colors,
      );
    }

    final total = _confirmed.fold<int>(
        0, (s, e) => s + ((e['monthly_amount'] as num?)?.toInt() ?? 0));

    return ListView(
      physics: const RefreshScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        CamillCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('月額合計',
                    style: camillBodyStyle(14, colors.textPrimary,
                        weight: FontWeight.bold)),
                Text(_currencyFmt.format(total),
                    style: camillAmountStyle(20, colors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._confirmed.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ConfirmedCard(
                  sub: s,
                  currencyFmt: _currencyFmt,
                  colors: colors,
                  onDelete: () =>
                      _deleteSubscription(s['subscription_id'] as String),
                ),
              )),
        ],
      );
  }

  Widget _buildCandidatesTab(CamillColors colors) {
    if (_candidates.isEmpty) {
      return _EmptyState(
        icon: Icons.search,
        message: '自動検出されたサブスク候補はありません\n3ヶ月以上同じ金額の支払いが検出されると表示されます',
        colors: colors,
      );
    }

    return ListView(
      physics: const RefreshScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '以下の支払いは定期的なサブスクの可能性があります。\n登録すると月額管理に追加されます。',
              style: camillBodyStyle(13, colors.textMuted),
            ),
          ),
          ..._candidates.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CandidateCard(
                  candidate: c,
                  currencyFmt: _currencyFmt,
                  colors: colors,
                  onConfirm: () =>
                      _confirmSubscription(c['subscription_id'] as String),
                ),
              )),
        ],
      );
  }
}

class _ConfirmedCard extends StatelessWidget {
  final Map<String, dynamic> sub;
  final NumberFormat currencyFmt;
  final CamillColors colors;
  final VoidCallback onDelete;

  const _ConfirmedCard({
    required this.sub,
    required this.currencyFmt,
    required this.colors,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final storeName = sub['store_name'] as String? ?? '';
    final amount = (sub['monthly_amount'] as num?)?.toInt() ?? 0;
    final detectedAt = sub['detected_at'] as String? ?? '';
    DateTime? date;
    try {
      date = DateTime.parse(detectedAt);
    } catch (_) {}

    return CamillCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.autorenew, color: colors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(storeName,
                    style: camillBodyStyle(15, colors.textPrimary,
                        weight: FontWeight.w600)),
                if (date != null)
                  Text('検出: ${DateFormat('yyyy年M月').format(date)}',
                      style: camillBodyStyle(12, colors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(currencyFmt.format(amount),
                  style: camillAmountStyle(16, colors.primary)),
              Text('/月', style: camillBodyStyle(11, colors.textMuted)),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colors.textMuted, size: 20),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final Map<String, dynamic> candidate;
  final NumberFormat currencyFmt;
  final CamillColors colors;
  final VoidCallback onConfirm;

  const _CandidateCard({
    required this.candidate,
    required this.currencyFmt,
    required this.colors,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final storeName = candidate['store_name'] as String? ?? '';
    final amount = (candidate['monthly_amount'] as num?)?.toInt() ?? 0;
    final occurrences = (candidate['occurrences'] as num?)?.toInt() ?? 0;

    return CamillCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.danger.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.help_outline,
                    color: colors.danger, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(storeName,
                        style: camillBodyStyle(15, colors.textPrimary,
                            weight: FontWeight.w600)),
                    Text('$occurrences ヶ月連続で同額支払い',
                        style: camillBodyStyle(12, colors.textMuted)),
                  ],
                ),
              ),
              Text(currencyFmt.format(amount),
                  style: camillAmountStyle(16, colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onConfirm,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary),
              ),
              child: Text('サブスクとして登録',
                  style: camillBodyStyle(13, colors.primary,
                      weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final CamillColors colors;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colors.textMuted.withAlpha(100)),
          const SizedBox(height: 16),
          Text(
            message,
            style: camillBodyStyle(14, colors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
