import 'package:flutter/material.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/camill_card.dart';
import '../../../shared/widgets/top_notification.dart';
import '../services/purchase_service.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final _api = ApiService();
  final _purchaseService = PurchaseService();

  Map<String, dynamic>? _billing;
  bool _loadingBilling = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _purchaseService.onPurchaseComplete = _onPurchaseComplete;
    _purchaseService.onPurchaseError = _onPurchaseError;
    _purchaseService.init().then((_) { if (mounted) setState(() {}); });
    _loadBilling();
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }

  Future<void> _loadBilling() async {
    setState(() => _loadingBilling = true);
    try {
      final data = await _api.get('/billing/status');
      if (mounted) setState(() { _billing = data; _loadingBilling = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingBilling = false);
    }
  }

  void _onPurchaseComplete() {
    if (!mounted) return;
    setState(() => _purchasing = false);
    _loadBilling();
    showTopNotification(context, 'プランが更新されました！');
  }

  void _onPurchaseError(String message) {
    if (!mounted) return;
    setState(() => _purchasing = false);
    showTopNotification(context, message);
  }

  Future<void> _buy(String productId) async {
    setState(() => _purchasing = true);
    await _purchaseService.buy(productId);
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    await _purchaseService.restorePurchases();
    // 完了は onPurchaseComplete で受け取る
  }

  String get _currentPlan => _billing?['plan'] as String? ?? 'free';
  int get _usedCount => _billing?['analysis_count_this_month'] as int? ?? 0;
  int get _limitCount => _billing?['analysis_limit'] as int? ?? 10;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('プランと課金', style: camillHeadingStyle(17, colors.textPrimary)),
        actions: [
          TextButton(
            onPressed: _purchasing ? null : _restore,
            child: Text('復元', style: camillBodyStyle(14, colors.textMuted)),
          ),
        ],
      ),
      body: _loadingBilling
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                  children: [
                    // 現在のプランカード
                    _CardLabel(icon: Icons.workspace_premium_outlined,
                        title: '現在のプラン', colors: colors),
                    const SizedBox(height: 8),
                    _CurrentPlanCard(
                      plan: _currentPlan,
                      usedCount: _usedCount,
                      limitCount: _limitCount,
                      colors: colors,
                    ),
                    const SizedBox(height: 20),

                    // 1ヶ月無料キャンペーンバナー（無料プランユーザーのみ）
                    if (_currentPlan == 'free') ...[
                      _TrialBanner(colors: colors),
                      const SizedBox(height: 20),
                    ],

                    // プラン一覧
                    _CardLabel(icon: Icons.compare_outlined,
                        title: 'プランを選択', colors: colors),
                    const SizedBox(height: 8),
                    _PlanCard(
                      planId: 'free',
                      name: '無料プラン',
                      price: '無料',
                      features: const ['月10回スキャン', '基本レシート管理', 'カレンダー表示'],
                      isCurrent: _currentPlan == 'free',
                      colors: colors,
                    ),
                    const SizedBox(height: 10),
                    _PlanCard(
                      planId: 'pro',
                      name: 'Pro プラン',
                      price: _purchaseService.product(PurchaseService.proMonthlyId)?.price ?? '¥500/月',
                      features: const ['月600回スキャン', '全機能利用可能', '医療明細・請求書対応', '優先サポート'],
                      isCurrent: _currentPlan == 'pro',
                      showTrial: _currentPlan == 'free',
                      isPurchasing: _purchasing,
                      colors: colors,
                      onBuy: () => _buy(PurchaseService.proMonthlyId),
                    ),
                    const SizedBox(height: 10),
                    _PlanCard(
                      planId: 'family',
                      name: 'ファミリープラン',
                      price: _purchaseService.product(PurchaseService.familyMonthlyId)?.price ?? '¥800/月',
                      features: const ['人数 × 月30回スキャン', '家族で共有', '財布管理・振り分けルール', '全機能利用可能'],
                      isCurrent: _currentPlan == 'family',
                      showTrial: _currentPlan == 'free',
                      isPurchasing: _purchasing,
                      colors: colors,
                      onBuy: () => _buy(PurchaseService.familyMonthlyId),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'サブスクリプションは月単位で自動更新されます。App Storeの設定からいつでもキャンセル可能です。',
                      style: camillBodyStyle(11, colors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                if (_purchasing)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }
}

// ── 現在のプランカード ────────────────────────────────────────────────────────
class _CurrentPlanCard extends StatelessWidget {
  final String plan;
  final int usedCount;
  final int limitCount;
  final CamillColors colors;

  const _CurrentPlanCard({
    required this.plan,
    required this.usedCount,
    required this.limitCount,
    required this.colors,
  });

  static const _planLabels = {
    'free': '無料プラン',
    'pro': 'Pro プラン',
    'family': 'ファミリープラン',
  };

  @override
  Widget build(BuildContext context) {
    final label = _planLabels[plan] ?? plan;
    final progress = limitCount > 0 ? (usedCount / limitCount).clamp(0.0, 1.0) : 0.0;
    final remaining = limitCount - usedCount;
    final isNearLimit = progress >= 0.8;

    return CamillCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: camillHeadingStyle(18, colors.textPrimary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('現在のプラン',
                    style: camillBodyStyle(11, colors.primary, weight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('今月のスキャン', style: camillBodyStyle(12, colors.textMuted)),
              Text('$usedCount / $limitCount 回',
                  style: camillBodyStyle(12, colors.textSecondary, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colors.surfaceBorder,
              valueColor: AlwaysStoppedAnimation(
                isNearLimit ? colors.danger : colors.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            remaining > 0 ? '残り$remaining回' : '今月の上限に達しました',
            style: camillBodyStyle(11,
                isNearLimit ? colors.danger : colors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── 1ヶ月無料キャンペーンバナー ──────────────────────────────────────────────
class _TrialBanner extends StatelessWidget {
  final CamillColors colors;
  const _TrialBanner({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withAlpha(180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.celebration_outlined, color: colors.fabIcon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今なら1ヶ月無料！',
                    style: camillHeadingStyle(15, colors.fabIcon)),
                const SizedBox(height: 2),
                Text('有料プランを初めてご利用の方が対象です',
                    style: camillBodyStyle(11, colors.fabIcon.withAlpha(200))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── プランカード ──────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final String planId;
  final String name;
  final String price;
  final List<String> features;
  final bool isCurrent;
  final bool showTrial;
  final bool isPurchasing;
  final CamillColors colors;
  final VoidCallback? onBuy;

  const _PlanCard({
    required this.planId,
    required this.name,
    required this.price,
    required this.features,
    required this.isCurrent,
    required this.colors,
    this.showTrial = false,
    this.isPurchasing = false,
    this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = planId != 'free';

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? colors.primary : colors.surfaceBorder,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent
            ? [BoxShadow(
                color: colors.primary.withAlpha(30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )]
            : null,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name, style: camillHeadingStyle(16, colors.textPrimary)),
              ),
              if (isPaid && showTrial)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.danger.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.danger.withAlpha(80)),
                  ),
                  child: Text('初月無料',
                      style: camillBodyStyle(11, colors.danger, weight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(price, style: camillBodyStyle(14, colors.textMuted)),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 15,
                    color: isCurrent ? colors.primary : colors.textMuted),
                const SizedBox(width: 6),
                Text(f, style: camillBodyStyle(13, colors.textSecondary)),
              ],
            ),
          )),
          if (isPaid && !isCurrent) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPurchasing ? null : onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  showTrial ? '1ヶ月無料で始める' : 'このプランへ',
                  style: camillBodyStyle(14, colors.fabIcon, weight: FontWeight.bold),
                ),
              ),
            ),
          ],
          if (isCurrent)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Text('現在のプランです',
                    style: camillBodyStyle(12, colors.primary, weight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── ラベル ───────────────────────────────────────────────────────────────────
class _CardLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final CamillColors colors;

  const _CardLabel({required this.icon, required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: colors.textMuted),
        const SizedBox(width: 6),
        Text(title,
            style: camillBodyStyle(13, colors.textMuted, weight: FontWeight.w600)),
      ],
    );
  }
}
