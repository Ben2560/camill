import 'package:flutter/material.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/coupon_model.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../services/coupon_service.dart';

// 曜日ラベル（0=月〜6=日）
const _dayLabels = ['月', '火', '水', '木', '金', '土', '日'];

class CouponWalletScreen extends StatefulWidget {
  const CouponWalletScreen({super.key});

  @override
  State<CouponWalletScreen> createState() => _CouponWalletScreenState();
}

class _CouponWalletScreenState extends State<CouponWalletScreen>
    with SingleTickerProviderStateMixin {
  final _service = CouponService();
  List<Coupon> _coupons = [];
  bool _loading = true;
  String _sortMode = 'expiry';
  bool _showExpired = false;
  int _dotsVisible = 0;
  bool _isRefreshing = false;
  bool _ignoreUntilTop = false;
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _loadCoupons();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _startSilentRefresh() {
    if (_isRefreshing) return;
    setState(() { _isRefreshing = true; _dotsVisible = 3; _ignoreUntilTop = true; });
    if (!_bounceController.isAnimating) _bounceController.repeat();
    _loadCoupons(silent: true).then((_) {
      if (!mounted) return;
      _bounceController.stop(); _bounceController.reset();
      setState(() { _isRefreshing = false; _dotsVisible = 0; });
    });
  }

  Future<void> _loadCoupons({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final all = await _service.fetchCoupons();
      setState(() => _coupons = all);
    } catch (e) {
      // silently swallow
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Coupon> get _activeCoupons => _coupons
      .where((c) => !c.isUsed && !c.isExpired)
      .toList()
    ..sort(_compareCoupon);

  List<Coupon> get _expiredCoupons =>
      _coupons.where((c) => c.isUsed || c.isExpired).toList();

  int _compareCoupon(Coupon a, Coupon b) {
    switch (_sortMode) {
      case 'store':
        return a.storeName.compareTo(b.storeName);
      case 'amount':
        return b.discountAmount.compareTo(a.discountAmount);
      default:
        if (a.validUntil == null) return 1;
        if (b.validUntil == null) return -1;
        return a.validUntil!.compareTo(b.validUntil!);
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
          title: Text('クーポン財布', style: camillHeadingStyle(17, colors.textPrimary)),
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: colors.textSecondary),
              onPressed: _showAddDialog,
            ),
          ],
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
              child: ListView(
                physics: const RefreshScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
              Row(
                children: [
                  Text('並び順:', style: camillBodyStyle(13, colors.textMuted)),
                  const SizedBox(width: 8),
                  _SortButton(
                    label: '有効期限',
                    active: _sortMode == 'expiry',
                    colors: colors,
                    onTap: () => setState(() => _sortMode = 'expiry'),
                  ),
                  const SizedBox(width: 6),
                  _SortButton(
                    label: '店舗',
                    active: _sortMode == 'store',
                    colors: colors,
                    onTap: () => setState(() => _sortMode = 'store'),
                  ),
                  const SizedBox(width: 6),
                  _SortButton(
                    label: '金額',
                    active: _sortMode == 'amount',
                    colors: colors,
                    onTap: () => setState(() => _sortMode = 'amount'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('有効中 (${_activeCoupons.length}枚)',
                  style: camillBodyStyle(14, colors.textPrimary, weight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_activeCoupons.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('有効なクーポンはありません',
                        style: camillBodyStyle(14, colors.textMuted)),
                  ),
                )
              else
                ..._activeCoupons.map((c) => _CouponCard(
                      coupon: c,
                      onTap: () => _showEditDialog(c),
                    )),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _showExpired = !_showExpired),
                child: Row(
                  children: [
                    Text('使用済み・期限切れ (${_expiredCoupons.length}枚)',
                        style: camillBodyStyle(14, colors.textPrimary,
                            weight: FontWeight.bold)),
                    const Spacer(),
                    Icon(
                      _showExpired ? Icons.expand_less : Icons.expand_more,
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ),
              if (_showExpired)
                ..._expiredCoupons.map((c) => _CouponCard(
                      coupon: c,
                      dimmed: true,
                      onTap: () => _showEditDialog(c),
                    )),
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

  Future<void> _markUsed(Coupon coupon) async {
    try {
      await _service.useCoupon(coupon.couponId);
      await _loadCoupons();
    } catch (e) {
      // silently swallow
    }
  }

  Future<void> _markSurveyAnswered(Coupon coupon) async {
    try {
      await _service.markSurveyAnswered(coupon.couponId);
      await _loadCoupons();
    } catch (e) {
      // silently swallow
    }
  }

  Future<void> _deleteCoupon(Coupon coupon) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('削除確認', style: camillHeadingStyle(16, colors.textPrimary)),
        content: Text('このクーポンを削除しますか？',
            style: camillBodyStyle(14, colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('キャンセル',
                style: camillBodyStyle(14, colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('削除',
                style: camillBodyStyle(14, colors.danger,
                    weight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _service.deleteCoupon(coupon.couponId);
        await _loadCoupons();
      } catch (e) {
        // silently swallow
      }
    }
  }

  Future<void> _showAddDialog() async {
    final colors = context.colors;
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime? validFrom;
    DateTime? validUntil;
    List<int> availableDays = [];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colors.surface,
          title: Text('クーポンを追加', style: camillHeadingStyle(16, colors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: camillBodyStyle(14, colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: '店名',
                    labelStyle: camillBodyStyle(13, colors.textMuted),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  style: camillBodyStyle(14, colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: '内容',
                    labelStyle: camillBodyStyle(13, colors.textMuted),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: camillBodyStyle(14, colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: '割引額（円）※無料は0',
                    labelStyle: camillBodyStyle(13, colors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('使用可能曜日（未選択=毎日）',
                      style: camillBodyStyle(12, colors.textMuted)),
                ),
                const SizedBox(height: 6),
                _DayPicker(
                  selected: availableDays,
                  colors: colors,
                  onChanged: (days) => setDialogState(() => availableDays = days),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => validFrom = picked);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: colors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        validFrom != null
                            ? '開始: ${validFrom!.year}/${validFrom!.month}/${validFrom!.day}'
                            : '開始日を選択（任意）',
                        style: camillBodyStyle(13, colors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => validUntil = picked);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.event_available, size: 16, color: colors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        validUntil != null
                            ? '有効期限: ${validUntil!.year}/${validUntil!.month}/${validUntil!.day}'
                            : '有効期限を選択（任意）',
                        style: camillBodyStyle(13, colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('キャンセル',
                  style: camillBodyStyle(14, colors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && descCtrl.text.isNotEmpty) {
                  Navigator.pop(ctx);
                  try {
                    await _service.createCoupon(
                      storeName: nameCtrl.text,
                      description: descCtrl.text,
                      discountAmount: int.tryParse(amountCtrl.text) ?? 0,
                      validFrom: validFrom?.toIso8601String(),
                      validUntil: validUntil?.toIso8601String(),
                      availableDays: availableDays.isEmpty ? null : availableDays,
                    );
                    await _loadCoupons();
                  } catch (e) {
                    // silently swallow
                  }
                }
              },
              child: Text('追加', style: camillBodyStyle(14, colors.fabIcon)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Coupon coupon) {
    final colors = context.colors;
    final nameCtrl = TextEditingController(text: coupon.storeName);
    final descCtrl = TextEditingController(text: coupon.description);
    final amountCtrl = TextEditingController(
      text: coupon.discountAmount > 0 ? coupon.discountAmount.toString() : '',
    );
    DateTime? validFrom = coupon.validFrom;
    DateTime? validUntil = coupon.validUntil;
    List<int> availableDays = List.from(coupon.availableDays ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => AnimatedPadding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ハンドル
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: colors.textMuted.withAlpha(80),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // ヘッダー：タイトル + 削除
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text('クーポンを編集',
                            style: camillBodyStyle(17, colors.textPrimary,
                                weight: FontWeight.w700)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () { Navigator.pop(ctx); _deleteCoupon(coupon); },
                          child: Text('削除',
                              style: camillBodyStyle(14, colors.danger)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 使用済みにする
                  if (!coupon.isUsed && !coupon.isExpired) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () { Navigator.pop(ctx); _markUsed(coupon); },
                          icon: const Icon(Icons.check_circle_outline,
                              color: Colors.white, size: 18),
                          label: Text('使用済みにする',
                              style: camillBodyStyle(15, Colors.white,
                                  weight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // アンケート
                  if (coupon.requiresSurvey && !coupon.surveyAnswered) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF43A047),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () { Navigator.pop(ctx); _markSurveyAnswered(coupon); },
                          icon: const Icon(Icons.assignment_turned_in_outlined,
                              color: Colors.white, size: 18),
                          label: Text('アンケート回答済みにする',
                              style: camillBodyStyle(15, Colors.white,
                                  weight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // コミュニティ共有
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: coupon.isCommunityShared
                        ? Row(
                            children: [
                              Icon(Icons.people, size: 14,
                                  color: colors.textMuted),
                              const SizedBox(width: 6),
                              Text('コミュニティに公開済み',
                                  style: camillBodyStyle(13, colors.textMuted)),
                            ],
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: colors.surfaceBorder),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _shareToCommunity(coupon);
                              },
                              icon: Icon(Icons.people_outline,
                                  size: 18, color: colors.textSecondary),
                              label: Text('コミュニティに共有',
                                  style: camillBodyStyle(
                                      14, colors.textSecondary)),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // フォーム
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('店名', style: camillBodyStyle(13, colors.textMuted)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameCtrl,
                          style: camillBodyStyle(14, colors.textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: colors.surfaceBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: colors.surfaceBorder),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('内容', style: camillBodyStyle(13, colors.textMuted)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descCtrl,
                          style: camillBodyStyle(14, colors.textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: colors.surfaceBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: colors.surfaceBorder),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('割引額（円）',
                            style: camillBodyStyle(13, colors.textMuted)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          style: camillBodyStyle(14, colors.textPrimary),
                          decoration: InputDecoration(
                            hintText: '0で無料クーポン',
                            hintStyle: camillBodyStyle(13, colors.textMuted),
                            filled: true,
                            fillColor: colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: colors.surfaceBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: colors.surfaceBorder),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('使用可能曜日（未選択=毎日）',
                            style: camillBodyStyle(13, colors.textMuted)),
                        const SizedBox(height: 8),
                        _DayPicker(
                          selected: availableDays,
                          colors: colors,
                          onChanged: (days) =>
                              setSheet(() => availableDays = days),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: validFrom ?? DateTime.now(),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 365)),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setSheet(() => validFrom = picked);
                            }
                          },
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 16, color: colors.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                validFrom != null
                                    ? '開始: ${validFrom!.year}/${validFrom!.month}/${validFrom!.day}'
                                    : '開始日を選択（任意）',
                                style: camillBodyStyle(13, colors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: validUntil ??
                                  DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setSheet(() => validUntil = picked);
                            }
                          },
                          child: Row(
                            children: [
                              Icon(Icons.event_available,
                                  size: 16, color: colors.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                validUntil != null
                                    ? '有効期限: ${validUntil!.year}/${validUntil!.month}/${validUntil!.day}'
                                    : '有効期限を選択（任意）',
                                style: camillBodyStyle(13, colors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              try {
                                await _service.deleteCoupon(coupon.couponId);
                                await _service.createCoupon(
                                  storeName: nameCtrl.text,
                                  description: descCtrl.text,
                                  discountAmount:
                                      int.tryParse(amountCtrl.text) ?? 0,
                                  validFrom: validFrom?.toIso8601String(),
                                  validUntil: validUntil?.toIso8601String(),
                                  availableDays: availableDays.isEmpty
                                      ? null
                                      : availableDays,
                                  isFromOcr: coupon.isFromOcr,
                                );
                                await _loadCoupons();
                              } catch (e) {
                                // silently swallow
                              }
                            },
                            child: Text('保存',
                                style: camillBodyStyle(16, colors.fabIcon,
                                    weight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareToCommunity(Coupon coupon) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('コミュニティに共有',
            style: camillHeadingStyle(16, colors.textPrimary)),
        content: Text(
          'このクーポン情報をコミュニティに公開しますか？\n一度公開すると取り消せません。',
          style: camillBodyStyle(14, colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('キャンセル',
                style: camillBodyStyle(14, colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('公開する',
                style: camillBodyStyle(14, colors.primary,
                    weight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _service.shareToCommunity(coupon.couponId);
        await _loadCoupons();
      } catch (e) {
        // silently swallow
      }
    }
  }
}

// ── クーポンカード（リスト用）────────────────────────────────────────────────
class _CouponCard extends StatelessWidget {
  final Coupon coupon;
  final bool dimmed;
  final VoidCallback onTap;

  const _CouponCard({
    required this.coupon,
    this.dimmed = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Opacity(
      opacity: dimmed ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: coupon.isFree && !dimmed
            ? _FreeCard(coupon: coupon)
            : _RegularCard(coupon: coupon, colors: colors, dimmed: dimmed),
      ),
    );
  }
}

// ── 無料クーポン（ゴールドカード）────────────────────────────────────────────
class _FreeCard extends StatelessWidget {
  final Coupon coupon;
  const _FreeCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B6914), Color(0xFFD4A017), Color(0xFFFFD700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -12,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(coupon.storeName,
                        style: camillBodyStyle(13, Colors.white70)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('無料クーポン',
                          style: camillBodyStyle(10, Colors.white,
                              weight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  coupon.description,
                  style: camillBodyStyle(16, Colors.white,
                      weight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.card_giftcard,
                        size: 28, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      '無料',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    if (coupon.availableDays != null &&
                        coupon.availableDays!.isNotEmpty)
                      _DayDotsSmall(availableDays: coupon.availableDays!),
                  ],
                ),
                if (coupon.validUntil != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        coupon.isExpired
                            ? Icons.cancel_outlined
                            : coupon.isExpiringSoon
                                ? Icons.warning_amber_outlined
                                : Icons.schedule,
                        size: 12,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _validityText(coupon),
                        style: camillBodyStyle(11, Colors.white70),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 通常クーポンカード ───────────────────────────────────────────────────────
class _RegularCard extends StatelessWidget {
  final Coupon coupon;
  final CamillColors colors;
  final bool dimmed;

  const _RegularCard({
    required this.coupon,
    required this.colors,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final expired = coupon.isExpired;
    final expiringSoon = coupon.isExpiringSoon;

    Color borderColor = colors.surfaceBorder;
    if (expiringSoon && !dimmed) borderColor = colors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: borderColor, width: expiringSoon && !dimmed ? 1.5 : 1),
        boxShadow: colors.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store_outlined,
                    size: 14, color: colors.textMuted),
                const SizedBox(width: 4),
                Text(coupon.storeName,
                    style: camillBodyStyle(13, colors.textMuted)),
                const SizedBox(width: 6),
                if (coupon.isFromOcr)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('OCR自動',
                        style: camillBodyStyle(9, colors.primary)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: colors.surfaceBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('手動',
                        style: camillBodyStyle(9, colors.textMuted)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(coupon.description,
                style: camillBodyStyle(15, colors.textPrimary,
                    weight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  coupon.discountAmount > 0
                      ? '${coupon.discountAmount}円引き'
                      : '無料',
                  style: camillAmountStyle(20, colors.primary),
                ),
                const Spacer(),
                if (coupon.availableDays != null &&
                    coupon.availableDays!.isNotEmpty)
                  _DayDotsSmall(availableDays: coupon.availableDays!),
              ],
            ),
            if (coupon.validUntil != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    expired
                        ? Icons.cancel_outlined
                        : expiringSoon
                            ? Icons.warning_amber_outlined
                            : Icons.schedule,
                    size: 13,
                    color: expired || expiringSoon
                        ? colors.danger
                        : colors.textMuted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _validityText(coupon),
                    style: camillBodyStyle(
                      12,
                      expired || expiringSoon
                          ? colors.danger
                          : colors.textMuted,
                      weight: expiringSoon
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _validityText(Coupon coupon) {
  final from = coupon.validFrom;
  final until = coupon.validUntil;
  final days = coupon.daysUntilExpiry;
  final expired = coupon.isExpired;

  String range = '';
  if (from != null && until != null) {
    range = '${from.month}/${from.day}〜${until.month}/${until.day}  ';
  }

  if (expired) return '$range期限切れ';
  if (days != null) return '$range残り$days日';
  return range.trim();
}

// ── 曜日ドット（カード内小表示）────────────────────────────────────────────
class _DayDotsSmall extends StatelessWidget {
  final List<int> availableDays;
  const _DayDotsSmall({required this.availableDays});

  @override
  Widget build(BuildContext context) {
    final todayIdx = DateTime.now().weekday - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        final isAvailable = availableDays.contains(i);
        final isToday = i == todayIdx;
        return Container(
          margin: const EdgeInsets.only(left: 2),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAvailable
                ? isToday
                    ? const Color(0xFFFF6B00)
                    : const Color(0xFF4CAF50).withAlpha(180)
                : Colors.transparent,
            border: isAvailable
                ? null
                : Border.all(
                    color: Colors.grey.withAlpha(80), width: 1),
          ),
          child: Center(
            child: Text(
              _dayLabels[i],
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isAvailable ? Colors.white : Colors.grey,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── 曜日ピッカー（追加・編集ダイアログ用）──────────────────────────────────
class _DayPicker extends StatelessWidget {
  final List<int> selected;
  final CamillColors colors;
  final ValueChanged<List<int>> onChanged;

  const _DayPicker({
    required this.selected,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final isSelected = selected.contains(i);
        return GestureDetector(
          onTap: () {
            final next = List<int>.from(selected);
            isSelected ? next.remove(i) : next.add(i);
            onChanged(next);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? colors.primary : colors.surfaceBorder,
            ),
            child: Center(
              child: Text(
                _dayLabels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? colors.fabIcon : colors.textMuted,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final bool active;
  final CamillColors colors;
  final VoidCallback onTap;

  const _SortButton({
    required this.label,
    required this.active,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? colors.primary : colors.surfaceBorder,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: camillBodyStyle(
                12, active ? colors.fabIcon : colors.textMuted,
                weight: active ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
