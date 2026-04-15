import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _showAnnual = false;

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

  Future<void> _devSetPlan(String plan) async {
    try {
      await _api.post('/billing/dev-set-plan', body: {'plan': plan});
      await _loadBilling();
      if (mounted) showTopNotification(context, 'プランを $plan に変更しました');
    } catch (e) {
      debugPrint('devSetPlan: $e');
      if (mounted) showTopNotification(context, 'プラン変更に失敗しました');
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    await _purchaseService.restorePurchases();
  }

  Future<void> _openSubscriptionManagement() async {
    final Uri uri;
    if (Platform.isIOS) {
      uri = Uri.parse('https://apps.apple.com/account/subscriptions');
    } else {
      uri = Uri.parse('https://play.google.com/store/account/subscriptions');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String get _currentPlan => _billing?['plan'] as String? ?? 'free';
  int get _usedCount => _billing?['analysis_count_this_month'] as int? ?? 0;
  int get _limitCount => _billing?['analysis_limit'] as int? ?? 10;
  bool get _isDeveloper => _billing?['is_developer'] as bool? ?? false;
  bool get _isPaying => _currentPlan != 'free';

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
                      isDeveloper: _isDeveloper,
                      colors: colors,
                    ),
                    const SizedBox(height: 20),

                    // デベロッパーモード: プラン即切替
                    if (_isDeveloper) ...[
                      _DevPlanSwitcher(
                        currentPlan: _currentPlan,
                        onSelect: _devSetPlan,
                        colors: colors,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 1ヶ月無料キャンペーンバナー（無料プランユーザーのみ）
                    if (!_isPaying) ...[
                      _TrialBanner(colors: colors),
                      const SizedBox(height: 20),
                    ],

                    // プラン一覧
                    _CardLabel(icon: Icons.compare_outlined,
                        title: 'プランを選択', colors: colors),
                    const SizedBox(height: 8),

                    // 無料プランカード（非課金者 or デベロッパーのみ）
                    if (!_isPaying || _isDeveloper) ...[
                      _PlanCard(
                        planId: 'free',
                        name: '無料プラン',
                        price: '無料',
                        features: const ['月10回スキャン', '基本レシート管理', 'カレンダー表示'],
                        isCurrent: !_isDeveloper && _currentPlan == 'free',
                        colors: colors,
                      ),
                      const SizedBox(height: 16),
                      Divider(color: colors.surfaceBorder, height: 1),
                      const SizedBox(height: 16),
                    ],

                    // 月払い / 年払い トグル（共通）
                    Row(
                      children: [
                        Expanded(
                          child: _ToggleTab(
                            label: '月払い',
                            selected: !_showAnnual,
                            colors: colors,
                            onTap: () => setState(() => _showAnnual = false),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _ToggleTab(
                            label: '年払い',
                            selected: _showAnnual,
                            colors: colors,
                            onTap: () => setState(() => _showAnnual = true),
                            badge: 'お得',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Pro プラン
                    if (!_showAnnual)
                      _PlanCard(
                        planId: 'pro',
                        name: 'Pro プラン',
                        price: _purchaseService.product(PurchaseService.proMonthlyId)?.price ?? '¥480/月',
                        priceNote: '月50枚スキャン可能',
                        features: const [
                          '月50枚スキャン',
                          '全機能利用可能',
                          '医療明細・請求書対応',
                          '優先サポート',
                        ],
                        isCurrent: !_isDeveloper && _currentPlan == 'pro',
                        showTrial: !_isPaying,
                        isPurchasing: _purchasing,
                        colors: colors,
                        onBuy: () => _buy(PurchaseService.proMonthlyId),
                      )
                    else
                      _PlanCard(
                        planId: 'pro_annual',
                        name: 'Pro プラン',
                        price: _purchaseService.product(PurchaseService.proAnnualId)?.price ?? '¥4,600/年',
                        priceNote: '月60枚スキャン可能',
                        annualBadge: '¥383/月相当',
                        features: const [
                          '月60枚スキャン',
                          '全機能利用可能',
                          '医療明細・請求書対応',
                          '優先サポート',
                        ],
                        isCurrent: !_isDeveloper && _currentPlan == 'pro_annual',
                        showTrial: !_isPaying,
                        isPurchasing: _purchasing,
                        colors: colors,
                        onBuy: () => _buy(PurchaseService.proAnnualId),
                      ),
                    const SizedBox(height: 10),

                    // ファミリープラン
                    if (!_showAnnual)
                      _PlanCard(
                        planId: 'family',
                        name: 'ファミリープラン',
                        price: _purchaseService.product(PurchaseService.familyMonthlyId)?.price ?? '¥980/月',
                        priceNote: 'ファミリー共有150枚/月',
                        features: const [
                          'ファミリー共有150枚/月',
                          '家族で共有・財布管理',
                          '振り分けルール',
                          '全機能利用可能',
                        ],
                        isCurrent: !_isDeveloper && _currentPlan == 'family',
                        showTrial: !_isPaying,
                        isPurchasing: _purchasing,
                        colors: colors,
                        onBuy: () => _buy(PurchaseService.familyMonthlyId),
                      )
                    else
                      _PlanCard(
                        planId: 'family_annual',
                        name: 'ファミリープラン',
                        price: _purchaseService.product(PurchaseService.familyAnnualId)?.price ?? '¥11,100/年',
                        priceNote: 'ファミリー共有200枚/月',
                        annualBadge: '¥925/月相当',
                        features: const [
                          'ファミリー共有200枚/月',
                          '家族で共有・財布管理',
                          '振り分けルール',
                          '全機能利用可能',
                        ],
                        isCurrent: !_isDeveloper && _currentPlan == 'family_annual',
                        showTrial: !_isPaying,
                        isPurchasing: _purchasing,
                        colors: colors,
                        onBuy: () => _buy(PurchaseService.familyAnnualId),
                      ),

                    // 解約ボタン（課金中ユーザーのみ）
                    if (_isPaying) ...[
                      const SizedBox(height: 24),
                      _CancelSection(
                        colors: colors,
                        onCancel: _openSubscriptionManagement,
                      ),
                    ],

                    const SizedBox(height: 16),
                    Text(
                      'サブスクリプションは月単位または年単位で自動更新されます。App Store / Google Playの設定からいつでもキャンセル可能です。',
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


class _ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final CamillColors colors;
  final VoidCallback onTap;
  final String? badge;

  const _ToggleTab({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? colors.primary : colors.surfaceBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: camillBodyStyle(
                13,
                selected ? colors.fabIcon : colors.textSecondary,
                weight: FontWeight.w600,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? colors.fabIcon.withAlpha(40)
                      : colors.danger.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: camillBodyStyle(
                    9,
                    selected ? colors.fabIcon : colors.danger,
                    weight: FontWeight.w700,
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

// ── 現在のプランカード ────────────────────────────────────────────────────────
class _CurrentPlanCard extends StatelessWidget {
  final String plan;
  final int usedCount;
  final int limitCount;
  final bool isDeveloper;
  final CamillColors colors;

  const _CurrentPlanCard({
    required this.plan,
    required this.usedCount,
    required this.limitCount,
    required this.colors,
    this.isDeveloper = false,
  });

  static const _planLabels = {
    'free': '無料プラン',
    'pro': 'Pro プラン（月払い）',
    'pro_annual': 'Pro プラン（年払い）',
    'family': 'ファミリープラン（月払い）',
    'family_annual': 'ファミリープラン（年払い）',
  };

  @override
  Widget build(BuildContext context) {
    final label = isDeveloper ? 'デベロッパーモード' : (_planLabels[plan] ?? plan);
    final progress = isDeveloper ? 0.0 : (limitCount > 0 ? (usedCount / limitCount).clamp(0.0, 1.0) : 0.0);
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
          if (!isDeveloper) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('今月のスキャン', style: camillBodyStyle(12, colors.textMuted)),
                Text('$usedCount / $limitCount 枚',
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
              remaining > 0 ? '残り$remaining枚' : '今月の上限に達しました',
              style: camillBodyStyle(11,
                  isNearLimit ? colors.danger : colors.textMuted),
            ),
          ],
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
  final String? priceNote;
  final String? annualBadge;
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
    this.priceNote,
    this.annualBadge,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(price, style: camillBodyStyle(14, colors.textMuted)),
              if (annualBadge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(annualBadge!,
                      style: camillBodyStyle(10, colors.primary, weight: FontWeight.w600)),
                ),
              ],
            ],
          ),
          if (priceNote != null) ...[
            const SizedBox(height: 2),
            Text(priceNote!,
                style: camillBodyStyle(11, colors.textMuted)),
          ],
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 15,
                    color: isCurrent ? colors.primary : colors.textMuted),
                const SizedBox(width: 6),
                Expanded(child: Text(f, style: camillBodyStyle(13, colors.textSecondary))),
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

// ── 解約セクション ────────────────────────────────────────────────────────────
class _CancelSection extends StatelessWidget {
  final CamillColors colors;
  final VoidCallback onCancel;

  const _CancelSection({required this.colors, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(color: colors.surfaceBorder),
        const SizedBox(height: 8),
        Text(
          'サブスクリプションの解約',
          style: camillBodyStyle(13, colors.textMuted, weight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          Platform.isIOS
              ? 'App Storeのサブスクリプション管理画面で解約できます。'
              : 'Google Playのサブスクリプション管理画面で解約できます。',
          style: camillBodyStyle(11, colors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onCancel,
            icon: Icon(
              Platform.isIOS ? Icons.apple : Icons.android,
              size: 16,
              color: colors.textMuted,
            ),
            label: Text(
              Platform.isIOS
                  ? 'App Storeで解約する'
                  : 'Google Playで解約する',
              style: camillBodyStyle(14, colors.textMuted, weight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: colors.surfaceBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── デベロッパー用プラン切替 ──────────────────────────────────────────────────
class _DevPlanSwitcher extends StatelessWidget {
  final String currentPlan;
  final void Function(String) onSelect;
  final CamillColors colors;

  const _DevPlanSwitcher({
    required this.currentPlan,
    required this.onSelect,
    required this.colors,
  });

  static const _plans = [
    ('free', '無料'),
    ('pro', 'Pro月'),
    ('pro_annual', 'Pro年'),
    ('family', 'Family月'),
    ('family_annual', 'Family年'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.purple.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.developer_mode, size: 15, color: Colors.purple),
              const SizedBox(width: 6),
              Text('DEV: プラン即切替',
                  style: camillBodyStyle(13, Colors.purple,
                      weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _plans.map((p) {
              final isCurrent = currentPlan == p.$1;
              return GestureDetector(
                onTap: isCurrent ? null : () => onSelect(p.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCurrent ? Colors.purple : Colors.purple.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.purple.withAlpha(isCurrent ? 255 : 80)),
                  ),
                  child: Text(
                    p.$2,
                    style: camillBodyStyle(
                      13,
                      isCurrent ? Colors.white : Colors.purple,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
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
