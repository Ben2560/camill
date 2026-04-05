import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/bill_model.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../services/bill_service.dart';

class BillScreen extends StatefulWidget {
  const BillScreen({super.key});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _service = BillService();
  final _currencyFmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
  List<Bill> _bills = [];
  bool _loading = true;

  // dismiss
  final _dismissOffset = ValueNotifier<double>(0);
  late final AnimationController _snapController;
  bool _isDismissing = false;
  double _pullDistance = 0;

  // per-tab scroll controllers
  final _scrollControllers = [ScrollController(), ScrollController()];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dismissOffset.addListener(_onOffsetChanged);
    _loadBills();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _snapController.dispose();
    _dismissOffset.removeListener(_onOffsetChanged);
    _dismissOffset.dispose();
    for (final c in _scrollControllers) {
      c.dispose();
    }
    super.dispose();
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

  Future<void> _loadBills({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final all = await _service.fetchBills();
      if (!mounted) return;
      setState(() {
        _bills = all;
        if (!silent) _loading = false;
      });
    } catch (e) {
      // silently swallow
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  List<Bill> get _unpaid =>
      _bills.where((b) => b.status == BillStatus.unpaid || b.status == BillStatus.pending).toList();
  List<Bill> get _paid =>
      _bills.where((b) => b.status == BillStatus.paid).toList();

  Future<void> _markPaid(Bill bill) async {
    try {
      await _service.payBill(bill.billId);
      await _loadBills(silent: true);
      _tabController.animateTo(1);
    } catch (e) {
      // silently swallow
    }
  }

  Future<void> _deleteBill(Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この請求書を削除しますか？'),
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
        await _service.deleteBill(bill.billId);
        await _loadBills(silent: true);
      } catch (e) {
        // silently swallow
      }
    }
  }

  ScrollController get _activeScrollController =>
      _scrollControllers[_tabController.index];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
      child: LoadingOverlay(
        isLoading: _loading,
        child: Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: colors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text('請求書管理', style: camillHeadingStyle(17, colors.textPrimary)),
            iconTheme: IconThemeData(color: colors.textSecondary),
            actions: [
              IconButton(
                icon: Icon(Icons.add, color: colors.primary),
                onPressed: _showAddDialog,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: colors.primary,
              unselectedLabelColor: colors.textMuted,
              indicatorColor: colors.primary,
              tabs: [
                Tab(text: '未払い (${_unpaid.length})'),
                Tab(text: '支払済み (${_paid.length})'),
              ],
            ),
          ),
          body: Listener(
            onPointerMove: (e) {
              if (_isDismissing) return;
              final sc = _activeScrollController;
              final atTop = !sc.hasClients || sc.position.pixels <= 0;
              if (atTop && e.delta.dy > 0) {
                _pullDistance += e.delta.dy;
                _dismissOffset.value = _pullDistance;
              } else if (e.delta.dy < 0 && _pullDistance > 0) {
                _pullDistance = 0;
                _dismissOffset.value = 0;
              }
            },
            onPointerUp: (_) {
              if (_isDismissing) return;
              endDismiss();
              _pullDistance = 0;
            },
            onPointerCancel: (_) {
              if (_isDismissing) return;
              _pullDistance = 0;
              _dismissOffset.value = 0;
            },
            child: TabBarView(
              controller: _tabController,
              children: [
                _BillList(
                  bills: _unpaid,
                  currencyFmt: _currencyFmt,
                  onPaid: _markPaid,
                  onDelete: _deleteBill,
                  emptyMessage: '未払いの請求書はありません',
                  scrollController: _scrollControllers[0],
                ),
                _BillList(
                  bills: _paid,
                  currencyFmt: _currencyFmt,
                  onPaid: null,
                  onDelete: _deleteBill,
                  emptyMessage: '支払済みの請求書はありません',
                  scrollController: _scrollControllers[1],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final colors = context.colors;
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime? dueDate;

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colors.surface,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('請求書を追加',
                  style: camillHeadingStyle(16, colors.textPrimary)),
              IconButton(
                icon: Icon(Icons.close, color: colors.textMuted, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: camillBodyStyle(14, colors.textPrimary),
                decoration: InputDecoration(
                  labelText: '名称（例：東京ガス）',
                  labelStyle: camillBodyStyle(13, colors.textMuted),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: camillBodyStyle(14, colors.textPrimary),
                decoration: InputDecoration(
                  labelText: '金額（円）',
                  labelStyle: camillBodyStyle(13, colors.textMuted),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 14)),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => dueDate = picked);
                  }
                },
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: colors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      dueDate != null
                          ? '支払期限: ${dueDate!.year}/${dueDate!.month}/${dueDate!.day}'
                          : '支払期限を選択（任意）',
                      style: camillBodyStyle(13, colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary),
                onPressed: () async {
                  if (titleCtrl.text.isNotEmpty &&
                      amountCtrl.text.isNotEmpty) {
                    Navigator.pop(ctx);
                    try {
                      await _service.createBill(
                        title: titleCtrl.text,
                        amount: int.tryParse(amountCtrl.text) ?? 0,
                        dueDate: dueDate?.toIso8601String(),
                      );
                      await _loadBills(silent: true);
                    } catch (e) {
                      // silently swallow
                    }
                  }
                },
                child:
                    Text('追加', style: camillBodyStyle(14, colors.fabIcon)),
              ),
            ),
          ],
        ),
      ),
    );
    } finally {
      titleCtrl.dispose();
      amountCtrl.dispose();
    }
  }
}

class _BillList extends StatelessWidget {
  final List<Bill> bills;
  final NumberFormat currencyFmt;
  final void Function(Bill)? onPaid;
  final void Function(Bill) onDelete;
  final String emptyMessage;
  final ScrollController scrollController;

  const _BillList({
    required this.bills,
    required this.currencyFmt,
    required this.onPaid,
    required this.onDelete,
    required this.emptyMessage,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (bills.isEmpty) {
      return Center(
          child: Text(emptyMessage, style: camillBodyStyle(14, colors.textMuted)));
    }
    return ListView.separated(
      controller: scrollController,
      physics: const DismissScrollPhysicsWithTopBounce(),
      padding: const EdgeInsets.all(16),
      itemCount: bills.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _BillCard(
        bill: bills[i],
        currencyFmt: currencyFmt,
        onPaid: onPaid,
        onDelete: onDelete,
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Bill bill;
  final NumberFormat currencyFmt;
  final void Function(Bill)? onPaid;
  final void Function(Bill) onDelete;

  const _BillCard({
    required this.bill,
    required this.currencyFmt,
    required this.onPaid,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final days = bill.daysUntilDue;
    final urgent = bill.isUrgent;
    final paid = bill.status == BillStatus.paid;

    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: urgent && !paid ? colors.danger : colors.surfaceBorder,
            width: urgent && !paid ? 1.5 : 1,
          ),
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
          child: Row(
            children: [
              Container(
                width: 48,
                height: 56,
                decoration: BoxDecoration(
                  color: paid ? colors.surfaceBorder : colors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  paid
                      ? Icons.check_circle_outline
                      : Icons.description_outlined,
                  color: paid ? colors.textMuted : colors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bill.title,
                        style: camillBodyStyle(15, colors.textPrimary,
                            weight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      currencyFmt.format(bill.amount),
                      style: camillAmountStyle(18, colors.primary),
                    ),
                    if (bill.dueDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            urgent && !paid
                                ? Icons.warning_amber_outlined
                                : Icons.schedule,
                            size: 13,
                            color: urgent && !paid
                                ? colors.danger
                                : colors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            paid
                                ? '支払済み'
                                : (days != null && days >= 0)
                                    ? '期限まで残り$days日'
                                    : '期限切れ',
                            style: camillBodyStyle(
                              12,
                              urgent && !paid ? colors.danger : colors.textMuted,
                              weight: urgent && !paid
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
              if (onPaid != null)
                ElevatedButton(
                  onPressed: () => onPaid!(bill),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.success,
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text('支払い\nました',
                      textAlign: TextAlign.center,
                      style: camillBodyStyle(11, Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('削除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete(bill);
              },
            ),
          ],
        ),
      ),
    );
  }
}
