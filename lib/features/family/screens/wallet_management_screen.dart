import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/camill_colors.dart';
import '../../../shared/models/family_model.dart';
import '../../../shared/models/wallet_model.dart';
import '../services/wallet_service.dart';

class WalletManagementScreen extends StatefulWidget {
  final Family family;
  const WalletManagementScreen({super.key, required this.family});

  @override
  State<WalletManagementScreen> createState() => _WalletManagementScreenState();
}

class _WalletManagementScreenState extends State<WalletManagementScreen> {
  final _service = WalletService();
  List<Wallet> _wallets = [];
  List<WalletRule> _rules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.fetchWallets(),
        _service.fetchRules(),
      ]);
      if (mounted) {
        setState(() {
          _wallets = results[0] as List<Wallet>;
          _rules = results[1] as List<WalletRule>;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('WalletManagementScreen._load: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<WalletRule> _rulesForWallet(String walletId) =>
      _rules.where((r) => r.walletId == walletId).toList();

  Future<void> _createWallet() async {
    final result = await _showWalletDialog();
    if (result == null) return;
    try {
      final wallet = await _service.createWallet(
        name: result.$1,
        ownerUid: result.$2,
      );
      if (mounted) setState(() => _wallets.add(wallet));
    } catch (e) {
      debugPrint('createWallet: $e');
      if (mounted) _showError('財布の作成に失敗しました');
    }
  }

  Future<void> _addRule(String walletId) async {
    final result = await _showRuleDialog();
    if (result == null) return;
    try {
      final rule = await _service.createRule(
        matchType: result.$1,
        matchValue: result.$2,
        walletId: walletId,
      );
      if (mounted) setState(() => _rules.add(rule));
    } catch (e) {
      debugPrint('createRule: $e');
      if (mounted) _showError('ルールの追加に失敗しました');
    }
  }

  Future<void> _deleteRule(String ruleId) async {
    try {
      await _service.deleteRule(ruleId);
      if (mounted) setState(() => _rules.removeWhere((r) => r.ruleId == ruleId));
    } catch (e) {
      debugPrint('deleteRule: $e');
      if (mounted) _showError('ルールの削除に失敗しました');
    }
  }

  // ダイアログ: 財布作成 → (名前, ownerUid?)
  Future<(String, String?)?> _showWalletDialog() async {
    final nameCtrl = TextEditingController();
    String? selectedOwnerUid;

    // 子供メンバーのみ選択肢に出す
    final children = widget.family.members
        .where((m) => m.role == 'child')
        .toList();

    final result = await showDialog<(String, String?)?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('財布を追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '財布の名前',
                  hintText: '例: たろうのお小遣い',
                ),
                autofocus: true,
              ),
              if (children.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('所有者（任意）',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                DropdownButton<String?>(
                  value: selectedOwnerUid,
                  isExpanded: true,
                  hint: const Text('自分（デフォルト）'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('自分（デフォルト）')),
                    ...children.map((m) => DropdownMenuItem(
                          value: m.userId,
                          child: Text(m.displayName),
                        )),
                  ],
                  onChanged: (v) => setS(() => selectedOwnerUid = v),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(), child: const Text('キャンセル')),
            TextButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                ctx.pop((name, selectedOwnerUid));
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 300), nameCtrl.dispose);
    return result;
  }

  // ダイアログ: ルール追加 → (matchType, matchValue)
  Future<(String, String)?> _showRuleDialog() async {
    final valueCtrl = TextEditingController();
    String matchType = 'store';

    const typeOptions = [
      ('store', '店名', '例: マクドナルド'),
      ('keyword', 'キーワード', '例: お菓子'),
      ('item', '品目名', '例: ジュース'),
    ];

    final result = await showDialog<(String, String)?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('仕分けルールを追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('種類', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              DropdownButton<String>(
                value: matchType,
                isExpanded: true,
                items: typeOptions
                    .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                    .toList(),
                onChanged: (v) => setS(() {
                  matchType = v!;
                  valueCtrl.clear();
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueCtrl,
                decoration: InputDecoration(
                  labelText: '値',
                  hintText: typeOptions
                      .firstWhere((t) => t.$1 == matchType)
                      .$3,
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(), child: const Text('キャンセル')),
            TextButton(
              onPressed: () {
                final val = valueCtrl.text.trim();
                if (val.isEmpty) return;
                ctx.pop((matchType, val));
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 300), valueCtrl.dispose);
    return result;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        title: Text('財布管理',
            style: TextStyle(
                color: colors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _wallets.isEmpty
              ? _buildEmpty(colors)
              : _buildList(colors),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createWallet,
        icon: const Icon(Icons.add),
        label: const Text('財布を追加'),
      ),
    );
  }

  Widget _buildEmpty(CamillColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text('財布がありません',
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('子供のお小遣い管理や\n支出の仕分けに使えます',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildList(CamillColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _wallets.length,
      itemBuilder: (context, i) => _buildWalletCard(_wallets[i], colors),
    );
  }

  Widget _buildWalletCard(Wallet wallet, CamillColors colors) {
    final rules = _rulesForWallet(wallet.walletId);
    final ownerName = widget.family.members
        .where((m) => m.userId == wallet.ownerUid)
        .map((m) => m.displayName)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: const Border(),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.primary.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.account_balance_wallet_outlined,
              color: colors.primary, size: 20),
        ),
        title: Text(wallet.name,
            style: TextStyle(
                color: colors.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Text(
          ownerName != null ? '所有者: $ownerName' : '自分の財布',
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rules.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${rules.length}件',
                    style: TextStyle(color: colors.primary, fontSize: 12)),
              ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, color: colors.textSecondary),
          ],
        ),
        children: [
          if (rules.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('仕分けルールがありません',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            )
          else
            ...rules.map((rule) => _buildRuleRow(rule, colors)),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addRule(wallet.walletId),
              icon: Icon(Icons.add, size: 16, color: colors.primary),
              label: Text('ルールを追加',
                  style: TextStyle(color: colors.primary, fontSize: 13)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(WalletRule rule, CamillColors colors) {
    const typeLabel = {
      'store': '店名',
      'keyword': 'キーワード',
      'item': '品目名',
    };
    const typeIcon = {
      'store': Icons.storefront_outlined,
      'keyword': Icons.label_outline,
      'item': Icons.receipt_long_outlined,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(typeIcon[rule.matchType] ?? Icons.label_outline,
              size: 16, color: colors.textSecondary),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.surfaceBorder.withAlpha(80),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(typeLabel[rule.matchType] ?? rule.matchType,
                style:
                    TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(rule.matchValue,
                style: TextStyle(color: colors.textPrimary, fontSize: 13)),
          ),
          GestureDetector(
            onTap: () => _confirmDeleteRule(rule),
            child: Icon(Icons.close, size: 18, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteRule(WalletRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ルールを削除しますか？'),
        content: Text('「${rule.matchValue}」の仕分けルールを削除します。'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _deleteRule(rule.ruleId);
  }
}
