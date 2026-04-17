import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services/user_prefs.dart';

import '../../../core/theme/camill_colors.dart';
import '../../../shared/models/family_model.dart';
import '../services/family_service.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen>
    with SingleTickerProviderStateMixin {
  final _service = FamilyService();
  Family? _family;
  bool _loading = true;
  bool _showInfoBanner = true;

  // dismiss scroll
  final _dismissOffset = ValueNotifier<double>(0);
  late final AnimationController _snapController;
  bool _isDismissing = false;
  double _pullDistance = 0;
  final _scrollController = ScrollController();

  static const _bannerPrefKey = 'family_info_banner_dismissed';

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dismissOffset.addListener(_onOffsetChanged);
    _load();
    _checkBanner();
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

  void _endDismiss() {
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = await UserPrefs.getBool(prefs, _bannerPrefKey) ?? false;
    if (mounted) setState(() => _showInfoBanner = !dismissed);
  }

  Future<void> _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await UserPrefs.setBool(prefs, _bannerPrefKey, true);
    if (mounted) setState(() => _showInfoBanner = false);
  }

  Future<void> _load() async {
    try {
      final family = await _service.fetchMyFamily();
      if (mounted) setState(() { _family = family; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createFamily() async {
    final name = await _showNameDialog('ファミリーを作成', hint: '例: 渡邉家');
    if (name == null || name.isEmpty) return;
    try {
      final family = await _service.createFamily(name);
      if (mounted) setState(() => _family = family);
    } catch (e) {
      if (mounted) _showError('作成に失敗しました');
    }
  }

  Future<void> _inviteMember(String role) async {
    if (_family == null) return;
    try {
      final invite = await _service.inviteMember(_family!.familyId, role);
      if (mounted) context.push('/family/invite', extra: invite);
    } catch (e) {
      if (mounted) _showError('招待の作成に失敗しました');
    }
  }

  Future<void> _leaveFamily() async {
    if (_family == null) return;

    final isLastMember = _family!.members.length <= 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isLastMember ? 'ファミリーを削除しますか？' : 'ファミリーから離脱しますか？'),
        content: Text(isLastMember
            ? 'あなたが最後のメンバーです。ファミリー自体が削除されます。この操作は取り消せません。'
            : 'この操作は取り消せません。'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: Text(
              isLastMember ? '削除する' : '離脱する',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    try {
      if (isLastMember) {
        await _service.deleteFamily(_family!.familyId);
      } else {
        final me = _family!.members.firstWhere(
          (m) => m.userId == myUid,
          orElse: () => throw Exception('自分のメンバー情報が見つかりません'),
        );
        await _service.leaveFamilyMember(_family!.familyId, me.userId);
      }
      if (mounted) setState(() => _family = null);
    } catch (e) {
      if (mounted) _showError(isLastMember ? 'ファミリーの削除に失敗しました' : '離脱に失敗しました');
    }
  }

  Future<void> _dissolveFamily() async {
    if (_family == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ファミリーを解散しますか？'),
        content: const Text('全メンバーがファミリーから外れます。この操作は取り消せません。'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('解散する', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.deleteFamily(_family!.familyId);
      if (mounted) setState(() => _family = null);
    } catch (e) {
      if (mounted) _showError('解散に失敗しました');
    }
  }

  Future<String?> _showNameDialog(String title, {String hint = ''}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => ctx.pop(controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    // Dispose after the dialog closing animation completes
    Future.delayed(const Duration(milliseconds: 300), controller.dispose);
    return result;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.surface,
          foregroundColor: colors.textPrimary,
          elevation: 0,
          title: Text('ファミリー管理',
              style: TextStyle(
                  color: colors.textPrimary, fontWeight: FontWeight.bold)),
        ),
        body: Listener(
          onPointerMove: (e) {
            if (_isDismissing) return;
            final atTop = !_scrollController.hasClients ||
                _scrollController.position.pixels <= 0;
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
            _endDismiss();
            _pullDistance = 0;
          },
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _family == null
                  ? _buildEmpty(colors)
                  : _buildFamily(colors),
        ),
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
            Icon(Icons.group_outlined, size: 64, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text('ファミリーに参加していません',
                style: TextStyle(color: colors.textPrimary, fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('家族でcamilを使って、支出を共有しましょう',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _createFamily,
              icon: const Icon(Icons.add),
              label: const Text('ファミリーを作成'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/family/join'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('QRで参加する'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamily(CamillColors colors) {
    final family = _family!;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = family.ownerUid == myUid;
    final isFull = family.members.length >= family.maxMembers;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        if (_showInfoBanner) _buildInfoBanner(colors),

        _SectionCard(
          colors: colors,
          child: Row(
            children: [
              Icon(Icons.home_outlined, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(family.name,
                        style: TextStyle(color: colors.textPrimary,
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${family.members.length}人 / ${family.maxMembers}人',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text('メンバー', style: TextStyle(color: colors.textSecondary,
            fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _SectionCard(
          colors: colors,
          child: Column(
            children: [
              ...family.members.map((m) => _buildMemberRow(m, colors)),
              const Divider(),
              ListTile(
                leading: Icon(Icons.person_add_outlined,
                    color: isFull ? colors.textSecondary : colors.primary),
                title: Text('メンバーを招待',
                    style: TextStyle(
                        color: isFull ? colors.textSecondary : colors.primary,
                        fontWeight: FontWeight.w600)),
                subtitle: isFull
                    ? Text('定員に達しています',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12))
                    : null,
                contentPadding: EdgeInsets.zero,
                onTap: isFull ? null : () => _showInviteSheet(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Text('財布・仕分けルール', style: TextStyle(color: colors.textSecondary,
            fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _SectionCard(
          colors: colors,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.account_balance_wallet_outlined,
                color: colors.primary),
            title: Text('財布管理',
                style: TextStyle(color: colors.textPrimary,
                    fontWeight: FontWeight.w600)),
            subtitle: Text('お小遣いや仕分けルールを管理',
                style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
            onTap: () => context.push('/family/wallets', extra: family),
          ),
        ),
        const SizedBox(height: 32),

        ListTile(
          leading: Icon(
            isOwner ? Icons.delete_outline : Icons.exit_to_app,
            color: Colors.red,
          ),
          title: Text(
            isOwner ? 'ファミリーを解散する' : 'ファミリーから離脱する',
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
          ),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.red, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: isOwner ? _dissolveFamily : _leaveFamily,
        ),
      ],
    );
  }

  Widget _buildMemberRow(FamilyMember member, CamillColors colors) {
    final roleLabel = {
      'owner': 'オーナー',
      'parent': '大人',
      'child': '子供',
    }[member.role] ?? member.role;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colors.primary.withAlpha(30),
        child: Text(member.displayName.isNotEmpty ? member.displayName[0] : '?',
            style: TextStyle(color: colors.primary)),
      ),
      title: Text(member.displayName,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(roleLabel,
            style: TextStyle(color: colors.primary, fontSize: 12)),
      ),
    );
  }

  Widget _buildInfoBanner(CamillColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Text('ファミリープランでできること',
                  style: TextStyle(color: colors.primary,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: _dismissBanner,
                child: Icon(Icons.close, color: colors.textSecondary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow('最大6人まで家族を追加できます'),
          _InfoRow('パートナーの支出をカテゴリ単位で共有'),
          _InfoRow('子供の貯金・お小遣いを管理'),
          _InfoRow('プライバシーはデフォルトで守られます'),
        ],
      ),
    );
  }

  void _showInviteSheet() {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('招待する人を選択',
                style: TextStyle(color: colors.textPrimary,
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('大人（パートナー）'),
              subtitle: const Text('支出をカテゴリ単位で共有できます'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: colors.surface,
              onTap: () {
                ctx.pop();
                _inviteMember('parent');
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.child_care_outlined),
              title: const Text('子供'),
              subtitle: const Text('お小遣いや貯金を代理管理できます'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: colors.surface,
              onTap: () {
                ctx.pop();
                _inviteMember('child');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String text;
  const _InfoRow(this.text);
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: colors.primary),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final CamillColors colors;
  final Widget child;
  const _SectionCard({required this.colors, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
