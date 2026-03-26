import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/summary_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/pull_to_refresh.dart';

class ReceiptListScreen extends StatefulWidget {
  const ReceiptListScreen({super.key});

  @override
  State<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends State<ReceiptListScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _currencyFmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');

  List<ReceiptListItem> _allReceipts = [];
  bool _loading = true;
  String? _errorMessage;
  bool _searchOpen = false;
  String _searchQuery = '';

  // フィルタ状態
  Set<String> _selectedCategories = {};
  String? _amountRange; // null / under500 / 500to2000 / over2000

  // 展開状態
  final Set<String> _expandedIds = {};
  final Map<String, List<ReceiptItem>> _loadedItems = {};
  final Set<String> _loadingItems = {};
  final Map<String, GlobalKey> _cardKeys = {};

  // pull-to-dismiss
  final _dismissOffset = ValueNotifier<double>(0);
  late final AnimationController _snapController;
  bool _isDismissing = false;
  double _pullDistance = 0;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dismissOffset.addListener(_onOffsetChanged);
    _loadReceipts();
  }

  void _onOffsetChanged() {
    if (!mounted || _isDismissing) return;
    final limit = MediaQuery.of(context).size.height * 0.19;
    if (_dismissOffset.value >= limit) {
      _isDismissing = true;
      _dismissOffset.removeListener(_onOffsetChanged);
      _dismissOffset.value = limit;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context, rootNavigator: false).pop();
      });
    }
  }

  void endDismiss() {
    if (_isDismissing) return;
    final sh = MediaQuery.of(context).size.height;
    if (_dismissOffset.value > sh * 0.20) {
      _isDismissing = true;
      Navigator.of(context, rootNavigator: false).pop();
    } else {
      _snapBack();
    }
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

  Future<void> _loadReceipts({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final yearMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final data = await _api.get(
        '/receipts',
        query: {'year_month': yearMonth},
      );
      final list = (data['receipts'] as List<dynamic>)
          .map((e) => ReceiptListItem.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      for (final r in list) {
        _cardKeys.putIfAbsent(r.receiptId, () => GlobalKey());
      }
      setState(() {
        _allReceipts = list;
        _errorMessage = null;
        if (!silent) _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _allReceipts = [];
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<ReceiptListItem> get _filtered {
    var list = _allReceipts;

    // 検索
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((r) =>
              r.storeName.contains(_searchQuery))
          .toList();
    }

    // カテゴリフィルタ
    if (_selectedCategories.isNotEmpty) {
      list = list.where((r) => _selectedCategories.contains(r.category)).toList();
    }

    // 金額フィルタ
    if (_amountRange != null) {
      list = list.where((r) {
        switch (_amountRange) {
          case 'under500':
            return r.totalAmount < 500;
          case '500to2000':
            return r.totalAmount >= 500 && r.totalAmount <= 2000;
          case 'over2000':
            return r.totalAmount > 2000;
          default:
            return true;
        }
      }).toList();
    }

    return list;
  }

  /// カテゴリ別グループ（支出合計の多い順）
  List<MapEntry<String, List<ReceiptListItem>>> get _grouped {
    final Map<String, List<ReceiptListItem>> map = {};
    for (final r in _filtered) {
      map.putIfAbsent(r.category, () => []).add(r);
    }
    // 各カテゴリ内は新しい順
    for (final key in map.keys) {
      map[key]!.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
    }
    // カテゴリは合計金額の多い順
    final entries = map.entries.toList()
      ..sort((a, b) {
        final sumA = a.value.fold(0, (s, r) => s + r.totalAmount);
        final sumB = b.value.fold(0, (s, r) => s + r.totalAmount);
        return sumB.compareTo(sumA);
      });
    return entries;
  }

  bool get _hasFilter =>
      _selectedCategories.isNotEmpty || _amountRange != null;

  Set<String> get _bottomThreeIds {
    final all = _grouped.expand((e) => e.value).toList();
    return all.reversed.take(3).map((r) => r.receiptId).toSet();
  }

  void _clearFilter() {
    setState(() {
      _selectedCategories = {};
      _amountRange = null;
    });
  }

  void _scrollToCard(String id) {
    final ctx = _cardKeys[id]?.currentContext;
    if (ctx == null) return;
    final renderBox = ctx.findRenderObject() as RenderBox?;
    final cardHeight = renderBox?.size.height ?? 0;
    final viewportHeight = MediaQuery.of(context).size.height;
    // カードが画面に収まるなら上端基準でカードを上に表示、
    // 収まらないなら下端基準で品目が見えるように表示
    final alignment = cardHeight < viewportHeight * 0.8 ? 0.0 : 1.0;
    Scrollable.ensureVisible(
      ctx,
      alignment: alignment,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _toggleExpand(String id) async {
    final isExpanding = !_expandedIds.contains(id);
    setState(() {
      if (isExpanding) {
        _expandedIds.add(id);
      } else {
        _expandedIds.remove(id);
      }
    });
    if (!isExpanding) return;
    // 下から3件のみスクロール
    final shouldScroll = _bottomThreeIds.contains(id);
    if (shouldScroll) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _scrollToCard(id);
      });
    }
    if (_loadedItems.containsKey(id)) return;
    setState(() => _loadingItems.add(id));
    try {
      final data = await _api.get('/receipts/$id');
      final items = (data['items'] as List<dynamic>)
          .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() => _loadedItems[id] = items);
        // アイテム読み込み完了後にも再スクロール（下から3件のみ）
        if (shouldScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _scrollToCard(id);
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingItems.remove(id));
    }
  }

  Future<void> _deleteReceipt(ReceiptListItem receipt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('このレシートを削除しますか？この操作は元に戻せません。'),
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
    if (confirmed == true) {
      try {
        await _api.delete('/receipts/${receipt.receiptId}');
        await _loadReceipts();
      } catch (e) {
        // silently swallow
      }
    }
  }

  void _editReceipt(ReceiptListItem receipt) {
    context.push('/receipt-edit', extra: receipt).then((_) => _loadReceipts());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sh = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _dismissOffset,
      builder: (ctx, child) {
        final progress = (_dismissOffset.value / (sh * 0.20)).clamp(0.0, 1.0);
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
                  child: child,
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
          elevation: 0,
          scrolledUnderElevation: 0,
          title: _searchOpen
              ? TextField(
                  autofocus: true,
                  style: camillBodyStyle(15, colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '店名で検索...',
                    hintStyle: camillBodyStyle(15, colors.textMuted),
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                )
              : Text('レシート一覧', style: camillHeadingStyle(17, colors.textPrimary)),
          iconTheme: IconThemeData(color: colors.textSecondary),
          actions: [
            IconButton(
              icon: Icon(
                _searchOpen ? Icons.close : Icons.search,
                color: colors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _searchOpen = !_searchOpen;
                  if (!_searchOpen) _searchQuery = '';
                });
              },
            ),
          ],
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: colors.primary))
            : Stack(
                children: [
                  Listener(
                    onPointerMove: (e) {
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
                      endDismiss();
                      _pullDistance = 0;
                    },
                    onPointerCancel: (_) {
                      _pullDistance = 0;
                      _dismissOffset.value = 0;
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const DismissScrollPhysicsWithTopBounce(),
                      slivers: [
                        // フィルタバー
                        SliverToBoxAdapter(
                          child: _FilterBar(
                            colors: colors,
                            selectedCategories: _selectedCategories,
                            amountRange: _amountRange,
                            hasFilter: _hasFilter,
                            onCategoryToggle: (cat) {
                              setState(() {
                                if (_selectedCategories.contains(cat)) {
                                  _selectedCategories.remove(cat);
                                } else {
                                  _selectedCategories.add(cat);
                                }
                              });
                            },
                            onAmountRangeChanged: (v) =>
                                setState(() => _amountRange = v),
                            onClearFilter: _clearFilter,
                          ),
                        ),
                        // フィルタ適用中バッジ
                        if (_hasFilter)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withAlpha(20),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('フィルタ適用中',
                                            style: camillBodyStyle(
                                                12, colors.primary)),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: _clearFilter,
                                          child: Icon(Icons.close,
                                              size: 14, color: colors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // レシートリスト（カテゴリ別グループ）
                        if (_grouped.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: _errorMessage != null
                                  ? Text('エラー: $_errorMessage',
                                      style: camillBodyStyle(13, colors.danger),
                                      textAlign: TextAlign.center)
                                  : Text('レシートがありません',
                                      style: camillBodyStyle(14, colors.textMuted)),
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final entry = _grouped[index];
                                return _CategoryGroup(
                                  category: entry.key,
                                  receipts: entry.value,
                                  colors: colors,
                                  currencyFmt: _currencyFmt,
                                  expandedIds: _expandedIds,
                                  loadedItems: _loadedItems,
                                  loadingItems: _loadingItems,
                                  cardKeys: _cardKeys,
                                  onToggleExpand: _toggleExpand,
                                  onDelete: _deleteReceipt,
                                  onEdit: _editReceipt,
                                );
                              },
                              childCount: _grouped.length,
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
              ),
      ),
    );
  }
}

// ── フィルタバー ─────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final CamillColors colors;
  final Set<String> selectedCategories;
  final String? amountRange;
  final bool hasFilter;
  final void Function(String) onCategoryToggle;
  final void Function(String?) onAmountRangeChanged;
  final VoidCallback onClearFilter;

  const _FilterBar({
    required this.colors,
    required this.selectedCategories,
    required this.amountRange,
    required this.hasFilter,
    required this.onCategoryToggle,
    required this.onAmountRangeChanged,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // カテゴリチップ（主要カテゴリのみ）
          ...AppConstants.categoryLabels.entries.map((e) {
            final selected = selectedCategories.contains(e.key);
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(e.value,
                    style: camillBodyStyle(
                        12,
                        selected ? colors.fabIcon : colors.textPrimary)),
                selected: selected,
                backgroundColor: colors.surface,
                selectedColor: colors.primary,
                checkmarkColor: colors.fabIcon,
                side: BorderSide(color: colors.surfaceBorder),
                onSelected: (_) => onCategoryToggle(e.key),
              ),
            );
          }),
          const SizedBox(width: 8),
          // 金額ドロップダウン
          _DropdownChip(
            label: '金額',
            value: amountRange,
            colors: colors,
            items: const {
              'under500': '〜¥500',
              '500to2000': '¥500〜¥2,000',
              'over2000': '¥2,000〜',
            },
            onChanged: onAmountRangeChanged,
          ),
        ],
      ),
    );
  }
}

class _DropdownChip extends StatelessWidget {
  final String label;
  final String? value;
  final CamillColors colors;
  final Map<String, String> items;
  final void Function(String?) onChanged;

  const _DropdownChip({
    required this.label,
    required this.value,
    required this.colors,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value != null;
    return GestureDetector(
      onTap: () async {
        final colors = this.colors;
        await showModalBottomSheet(
          context: context,
          backgroundColor: colors.background,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: colors.surfaceBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Text(label, style: camillBodyStyle(17, colors.textPrimary, weight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text('すべて', style: camillBodyStyle(15, colors.textPrimary)),
                  leading: Icon(
                    value == null ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: value == null ? colors.primary : colors.textMuted,
                  ),
                  onTap: () { Navigator.pop(ctx); onChanged(null); },
                ),
                ...items.entries.map((e) => ListTile(
                  title: Text(e.value, style: camillBodyStyle(15, colors.textPrimary)),
                  leading: Icon(
                    value == e.key ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: value == e.key ? colors.primary : colors.textMuted,
                  ),
                  onTap: () { Navigator.pop(ctx); onChanged(e.key); },
                )),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected ? (items[value!] ?? label) : label,
              style: camillBodyStyle(
                  12, selected ? colors.fabIcon : colors.textPrimary),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down,
                size: 16,
                color: selected ? colors.fabIcon : colors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── カテゴリグループ ────────────────────────────────────────────────────────
class _CategoryGroup extends StatelessWidget {
  final String category;
  final List<ReceiptListItem> receipts;
  final CamillColors colors;
  final NumberFormat currencyFmt;
  final Set<String> expandedIds;
  final Map<String, List<ReceiptItem>> loadedItems;
  final Set<String> loadingItems;
  final Map<String, GlobalKey> cardKeys;
  final void Function(String) onToggleExpand;
  final void Function(ReceiptListItem) onDelete;
  final void Function(ReceiptListItem) onEdit;

  const _CategoryGroup({
    required this.category,
    required this.receipts,
    required this.colors,
    required this.currencyFmt,
    required this.expandedIds,
    required this.loadedItems,
    required this.loadingItems,
    required this.cardKeys,
    required this.onToggleExpand,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        AppConstants.categoryLabels[category] ?? category;
    final total = receipts.fold(0, (s, r) => s + r.totalAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // カテゴリヘッダー
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(label,
                  style: camillBodyStyle(13, colors.textMuted,
                      weight: FontWeight.w600)),
              const Spacer(),
              Text(currencyFmt.format(total),
                  style: camillAmountStyle(13, colors.textMuted)),
            ],
          ),
        ),
        // レシートカード一覧
        ...receipts.map((r) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _ReceiptCard(
                key: cardKeys[r.receiptId],
                receipt: r,
                colors: colors,
                currencyFmt: currencyFmt,
                isExpanded: expandedIds.contains(r.receiptId),
                isLoadingItems: loadingItems.contains(r.receiptId),
                loadedItems: loadedItems[r.receiptId],
                onTap: () => onToggleExpand(r.receiptId),
                onDelete: () => onDelete(r),
                onEdit: () => onEdit(r),
              ),
            )),
      ],
    );
  }
}

// ── レシートカード（インライン展開） ─────────────────────────────────────────
class _ReceiptCard extends StatefulWidget {
  final ReceiptListItem receipt;
  final CamillColors colors;
  final NumberFormat currencyFmt;
  final bool isExpanded;
  final bool isLoadingItems;
  final List<ReceiptItem>? loadedItems;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ReceiptCard({
    super.key,
    required this.receipt,
    required this.colors,
    required this.currencyFmt,
    required this.isExpanded,
    required this.isLoadingItems,
    required this.loadedItems,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_ReceiptCard> createState() => _ReceiptCardState();
}

class _ReceiptCardState extends State<_ReceiptCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.isExpanded ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void didUpdateWidget(_ReceiptCard old) {
    super.didUpdateWidget(old);
    if (widget.isExpanded != old.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(widget.receipt.purchasedAt)?.toLocal();
    final hasTime = dt != null && (dt.hour != 0 || dt.minute != 0);
    final dateStr = dt != null
        ? (hasTime ? DateFormat('M月d日 HH:mm').format(dt) : DateFormat('M月d日').format(dt))
        : widget.receipt.purchasedAt;

    final colors = widget.colors;
    final receipt = widget.receipt;
    final currencyFmt = widget.currencyFmt;
    final isExpanded = widget.isExpanded;
    final isLoadingItems = widget.isLoadingItems;
    final loadedItems = widget.loadedItems;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () => showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit_outlined, color: colors.primary),
                title: Text('編集', style: camillBodyStyle(15, colors.textPrimary)),
                onTap: () { Navigator.pop(ctx); widget.onEdit(); },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('削除', style: TextStyle(color: Colors.red)),
                onTap: () { Navigator.pop(ctx); widget.onDelete(); },
              ),
            ],
          ),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded ? colors.primary : colors.surfaceBorder,
            width: isExpanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // メイン行
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt_outlined,
                        color: colors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(receipt.storeName,
                            style: camillBodyStyle(
                                14, colors.textPrimary,
                                weight: FontWeight.w500)),
                        Text(dateStr,
                            style: camillBodyStyle(12, colors.textMuted)),
                      ],
                    ),
                  ),
                  Text(currencyFmt.format(receipt.totalAmount),
                      style: camillAmountStyle(14, colors.textPrimary)),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ),
            // 展開品目（SizeTransitionでスムーズアニメーション）
            ClipRect(
              child: SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: -1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(height: 1, color: colors.surfaceBorder),
                    if (isLoadingItems)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary))),
                      ),
                    if (!isLoadingItems)
                      ...?loadedItems?.map((item) => Padding(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                            child: Row(
                              children: [
                                const SizedBox(width: 46),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.itemName,
                                          style: camillBodyStyle(13, colors.textPrimary)),
                                      Builder(builder: (context) {
                                        final catColor =
                                            AppConstants.categoryColors[item.category] ??
                                                colors.textMuted;
                                        return Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: catColor.withAlpha(30),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: catColor, width: 0.5),
                                          ),
                                          child: Text(
                                            AppConstants.categoryLabels[item.category] ?? item.category,
                                            style: camillBodyStyle(10, catColor),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${item.quantity > 1 ? '×${item.quantity}  ' : ''}${currencyFmt.format(item.amount)}',
                                  style: camillBodyStyle(13, colors.textSecondary),
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
