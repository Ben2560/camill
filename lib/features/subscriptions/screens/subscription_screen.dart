import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../../../shared/widgets/camill_card.dart';

// サブスク種別の定義
const _subTypeLabel = {
  'streaming': '動画・音楽',
  'app': 'アプリ・クラウド',
  'shopping': '通販・EC',
  'news': 'ニュース・書籍',
  'game': 'ゲーム',
  'fitness': 'フィットネス',
  'other': 'その他',
};

const _subTypeIcon = {
  'streaming': Icons.play_circle_outline,
  'app': Icons.cloud_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'news': Icons.article_outlined,
  'game': Icons.sports_esports_outlined,
  'fitness': Icons.fitness_center_outlined,
  'other': Icons.subscriptions_outlined,
};

const _subTypeColor = {
  'streaming': Color(0xFFE50914), // 赤
  'app': Color(0xFF007AFF), // 青
  'shopping': Color(0xFFFF9500), // オレンジ
  'news': Color(0xFF34C759), // 緑
  'game': Color(0xFF5856D6), // 紫
  'fitness': Color(0xFFFF2D55), // ピンク
  'other': Color(0xFF8E8E93), // グレー
};

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
      debugPrint('loadAll error: $e');
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
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
    _loadAll(silent: true).then((_) {
      if (!mounted) return;
      _bounceController.stop();
      _bounceController.reset();
      setState(() {
        _isRefreshing = false;
        _dotsVisible = 0;
      });
    });
  }

  Future<void> _confirmSubscription(String id) async {
    try {
      await _api.postAny('/subscriptions/$id/confirm', body: {});
      await _loadAll();
    } catch (e) {
      debugPrint('confirm error: $e');
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
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.delete('/subscriptions/$id');
      await _loadAll();
    } catch (e) {
      debugPrint('delete error: $e');
    }
  }

  // ---- スキャン ----

  Future<void> _scanFromImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final colors = context.colors;

    // スキャン中ダイアログ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ScanningDialog(),
    );

    final tempFile = File(picked.path);
    try {
      final bytes =
          await FlutterImageCompress.compressWithFile(
            picked.path,
            minWidth: 1000,
            quality: 75,
          ) ??
          await tempFile.readAsBytes();

      final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final result = await _api.postAny(
        '/subscriptions/scan',
        body: {'image_base64': b64},
      );

      if (!mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).pop(); // dismiss scanning dialog

      final items = (result as List).cast<Map<String, dynamic>>();
      if (items.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('サブスクが検出されませんでした')));
        return;
      }

      // 結果シートを表示
      final added = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: colors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => _ScanResultSheet(
          items: items,
          currencyFmt: _currencyFmt,
          colors: colors,
          onSave: (selected) async {
            await _api.postAny(
              '/subscriptions/scan/add',
              body: {'subscriptions': selected},
            );
          },
        ),
      );

      if (added == true) {
        await _loadAll();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('サブスクを登録しました')));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('解析に失敗しました: $e')));
      }
    } finally {
      if (tempFile.existsSync()) tempFile.deleteSync();
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
          title: Text(
            'サブスク管理',
            style: camillHeadingStyle(17, colors.textPrimary),
          ),
          iconTheme: IconThemeData(color: colors.textSecondary),
          actions: [
            IconButton(
              icon: Icon(
                Icons.document_scanner_outlined,
                color: colors.primary,
              ),
              tooltip: 'スクショから追加',
              onPressed: _scanFromImage,
            ),
          ],
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
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildConfirmedTab(colors),
                  _buildCandidatesTab(colors),
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
    );
  }

  Widget _buildConfirmedTab(CamillColors colors) {
    if (_confirmed.isEmpty) {
      return _EmptyState(
        icon: Icons.subscriptions_outlined,
        message: 'サブスクはまだ登録されていません\n右上のアイコンからスクショで一括追加できます',
        colors: colors,
      );
    }

    final total = _confirmed.fold<int>(
      0,
      (s, e) => s + ((e['monthly_amount'] as num?)?.toInt() ?? 0),
    );

    return ListView(
      physics: const RefreshScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        CamillCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '月額合計',
                style: camillBodyStyle(
                  14,
                  colors.textPrimary,
                  weight: FontWeight.bold,
                ),
              ),
              Text(
                _currencyFmt.format(total),
                style: camillAmountStyle(20, colors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._confirmed.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ConfirmedCard(
              sub: s,
              currencyFmt: _currencyFmt,
              colors: colors,
              onDelete: () =>
                  _deleteSubscription(s['subscription_id'] as String),
            ),
          ),
        ),
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
        ..._candidates.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CandidateCard(
              candidate: c,
              currencyFmt: _currencyFmt,
              colors: colors,
              onConfirm: () =>
                  _confirmSubscription(c['subscription_id'] as String),
            ),
          ),
        ),
      ],
    );
  }
}

// ---- スキャン中ダイアログ ----

class _ScanningDialog extends StatelessWidget {
  const _ScanningDialog();

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('解析中...'),
        ],
      ),
    );
  }
}

// ---- スキャン結果シート ----

class _ScanResultSheet extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final NumberFormat currencyFmt;
  final CamillColors colors;
  final Future<void> Function(List<Map<String, dynamic>>) onSave;

  const _ScanResultSheet({
    required this.items,
    required this.currencyFmt,
    required this.colors,
    required this.onSave,
  });

  @override
  State<_ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends State<_ScanResultSheet> {
  late final Set<int> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // confidence >= 0.7 のものを初期選択
    _selected = {
      for (var i = 0; i < widget.items.length; i++)
        if ((widget.items[i]['confidence'] as num? ?? 0) >= 0.7) i,
    };
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final toSave = [
      for (var i = 0; i < widget.items.length; i++)
        if (_selected.contains(i)) widget.items[i],
    ];
    try {
      await widget.onSave(toSave);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final fmt = widget.currencyFmt;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // ドラッグハンドル
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '検出されたサブスク',
                  style: camillBodyStyle(
                    18,
                    colors.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selected.length}件選択',
                  style: camillBodyStyle(13, colors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '追加したいサブスクにチェックを入れてください',
              style: camillBodyStyle(12, colors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final item = widget.items[i];
                final isSelected = _selected.contains(i);
                final subType = item['subscription_type'] as String? ?? 'other';
                final typeColor =
                    _subTypeColor[subType] ?? const Color(0xFF8E8E93);
                final typeIcon =
                    _subTypeIcon[subType] ?? Icons.subscriptions_outlined;
                final typeLabel = _subTypeLabel[subType] ?? 'その他';
                final cycle = item['billing_cycle'] as String? ?? 'monthly';

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(i);
                      } else {
                        _selected.add(i);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primaryLight : colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? colors.primary
                            : colors.surfaceBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: typeColor.withAlpha(24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(typeIcon, color: typeColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['service_name'] as String? ?? '',
                                style: camillBodyStyle(
                                  15,
                                  colors.textPrimary,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: typeColor.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      typeLabel,
                                      style: camillBodyStyle(
                                        10,
                                        typeColor,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (cycle == 'annual') ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.textMuted.withAlpha(20),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '年払い',
                                        style: camillBodyStyle(
                                          10,
                                          colors.textMuted,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              fmt.format(item['monthly_amount'] as int? ?? 0),
                              style: camillAmountStyle(15, colors.textPrimary),
                            ),
                            Text(
                              '/月',
                              style: camillBodyStyle(11, colors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected ? colors.primary : colors.textMuted,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_selected.isEmpty || _saving) ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '${_selected.length}件を登録する',
                        style: camillBodyStyle(
                          15,
                          Colors.white,
                          weight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- 登録済みカード ----

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
    final subType = sub['subscription_type'] as String? ?? 'other';
    final typeColor = _subTypeColor[subType] ?? const Color(0xFF8E8E93);
    final typeIcon = _subTypeIcon[subType] ?? Icons.subscriptions_outlined;
    final typeLabel = _subTypeLabel[subType] ?? 'その他';
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
              color: typeColor.withAlpha(24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(typeIcon, color: typeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  style: camillBodyStyle(
                    15,
                    colors.textPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeLabel,
                        style: camillBodyStyle(
                          10,
                          typeColor,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (date != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '検出: ${DateFormat('yyyy年M月').format(date)}',
                        style: camillBodyStyle(11, colors.textMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFmt.format(amount),
                style: camillAmountStyle(16, colors.primary),
              ),
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

// ---- 候補カード ----

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
                child: Icon(Icons.help_outline, color: colors.danger, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: camillBodyStyle(
                        15,
                        colors.textPrimary,
                        weight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$occurrences ヶ月連続で同額支払い',
                      style: camillBodyStyle(12, colors.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                currencyFmt.format(amount),
                style: camillAmountStyle(16, colors.textPrimary),
              ),
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
              child: Text(
                'サブスクとして登録',
                style: camillBodyStyle(
                  13,
                  colors.primary,
                  weight: FontWeight.w600,
                ),
              ),
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
