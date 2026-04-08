import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/camill_colors.dart';
import '../../../shared/models/family_model.dart';
import '../services/family_service.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  final _service = FamilyService();
  Family? _family;
  bool _loading = true;
  bool _showInfoBanner = true;

  static const _bannerPrefKey = 'family_info_banner_dismissed';

  @override
  void initState() {
    super.initState();
    _load();
    _checkBanner();
  }

  Future<void> _checkBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_bannerPrefKey) ?? false;
    if (mounted) setState(() => _showInfoBanner = !dismissed);
  }

  Future<void> _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bannerPrefKey, true);
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ファミリーから離脱しますか？'),
        content: const Text('この操作は取り消せません。'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('離脱する', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final me = _family!.members.firstWhere(
      (m) => m.userId == myUid,
      orElse: () => throw Exception('自分のメンバー情報が見つかりません'),
    );
    try {
      await _service.leaveFamilyMember(_family!.familyId, me.userId);
      if (mounted) setState(() => _family = null);
    } catch (e) {
      if (mounted) _showError('離脱に失敗しました');
    }
  }

  Future<String?> _showNameDialog(String title, {String hint = ''}) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
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
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    }
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
        title: Text('ファミリー管理',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _family == null
              ? _buildEmpty(colors)
              : _buildFamily(colors),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // インフォバナー
        if (_showInfoBanner) _buildInfoBanner(colors),

        // ファミリー名
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

        // メンバーセクション
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
                leading: Icon(Icons.person_add_outlined, color: colors.primary),
                title: Text('メンバーを招待',
                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
                contentPadding: EdgeInsets.zero,
                onTap: () => _showInviteSheet(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 危険ゾーン
        ListTile(
          leading: const Icon(Icons.exit_to_app, color: Colors.red),
          title: const Text('ファミリーから離脱する',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.red, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: _leaveFamily,
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
