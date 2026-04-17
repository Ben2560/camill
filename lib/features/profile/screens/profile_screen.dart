import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services/user_prefs.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../auth/services/auth_service.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/top_notification.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final ValueNotifier<int>? refreshNotifier;
  const ProfileScreen({super.key, this.refreshNotifier});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();

  static const _budgetKey = 'budget_monthly';
  static const _monthlyIncomeKey = 'income_monthly';
  static const _paydayKey = 'income_payday';
  static const _sideIncomeKey = 'income_side';
  static const _avatarPathKey = 'profile_avatar_path';

  int _budget = 80000;
  int _monthlyIncome = 0;
  int _payday = 0;
  int _sideIncome = 0;
  String _plan = 'free';
  bool _isDeveloper = false;
  String? _avatarPath;

  static const _planLabels = {
    'free': '無料プラン',
    'pro': 'Proプラン',
    'family': 'ファミリープラン',
  };

  String get _planLabel =>
      _isDeveloper ? 'デベロッパーモード' : (_planLabels[_plan] ?? _plan);

  @override
  void initState() {
    super.initState();
    _loadBudget();
    _loadIncome();
    _loadAvatar();
    _loadBillingStatus();
    widget.refreshNotifier?.addListener(_loadBudget);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_loadBudget);
    super.dispose();
  }

  Future<void> _loadBillingStatus() async {
    try {
      final data = await _apiService.get('/billing/status');
      if (!mounted) return;
      setState(() {
        _plan = data['plan'] as String? ?? 'free';
        _isDeveloper = data['is_developer'] as bool? ?? false;
      });
    } catch (e) {
      debugPrint('billing status load failed: $e');
    }
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = await UserPrefs.getString(prefs, _avatarPathKey);
    if (!mounted) return;
    if (stored == null) {
      setState(() => _avatarPath = null);
      return;
    }
    final fileName = stored.contains('/') ? stored.split('/').last : stored;
    final dir = await getApplicationDocumentsDirectory();
    // UID 別ファイル名への移行（旧: profile_avatar.jpg → 新: profile_avatar_{uid}.jpg）
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'default';
    final expectedName = 'profile_avatar_$uid.jpg';
    if (fileName != expectedName) {
      final oldPath = '${dir.path}/$fileName';
      final newPath = '${dir.path}/$expectedName';
      if (File(oldPath).existsSync() && !File(newPath).existsSync()) {
        await File(oldPath).copy(newPath);
      }
      if (File(newPath).existsSync()) {
        await UserPrefs.setString(prefs, _avatarPathKey, expectedName);
        if (mounted) setState(() => _avatarPath = newPath);
      } else {
        if (mounted) setState(() => _avatarPath = null);
      }
      return;
    }
    final path = '${dir.path}/$fileName';
    if (!mounted) return;
    if (File(path).existsSync()) {
      setState(() => _avatarPath = path);
    } else {
      setState(() => _avatarPath = null);
    }
  }

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final v = await UserPrefs.getInt(prefs, _budgetKey);
    if (!mounted) return;
    setState(() => _budget = v ?? 80000);
  }

  Future<void> _loadIncome() async {
    final prefs = await SharedPreferences.getInstance();
    final income = await UserPrefs.getInt(prefs, _monthlyIncomeKey);
    final payday = await UserPrefs.getInt(prefs, _paydayKey);
    final side = await UserPrefs.getInt(prefs, _sideIncomeKey);
    if (!mounted) return;
    setState(() {
      _monthlyIncome = income ?? 0;
      _payday = payday ?? 0;
      _sideIncome = side ?? 0;
    });
  }

  String _formatAmount(int amount) {
    if (amount == 0) return '未設定';
    return '¥${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
  }

  String get _incomeSummary {
    if (_monthlyIncome == 0 && _payday == 0 && _sideIncome == 0) return '未設定';
    final parts = <String>[];
    if (_monthlyIncome > 0) parts.add(_formatAmount(_monthlyIncome));
    if (_payday > 0) parts.add('毎月$_payday日');
    return parts.join(' · ');
  }

  Future<void> _openIncomeSettings() async {
    await context.push('/income');
    if (mounted) _loadIncome();
  }

String get _displayName =>
      FirebaseAuth.instance.currentUser?.displayName ?? 'ユーザー';

  Future<void> _openAccountSettings() async {
    await context.push('/account');
    if (mounted) { setState(() {}); _loadAvatar(); }
  }

  // ── URL起動 ─────────────────────────────────────────────────────────────────
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        showTopNotification(context, 'URLを開けませんでした');
      }
    }
  }

  // ── 退会 ────────────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(CamillColors colors) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('退会確認',
            style: camillHeadingStyle(16, colors.textPrimary)),
        content: Text(
          'アカウントを削除すると、すべてのデータが失われます。本当に退会しますか？',
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
            child: Text('退会する',
                style: camillBodyStyle(14, colors.danger,
                    weight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _authService.deleteAccount();
      if (mounted) context.go('/login');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'requires-recent-login'
          ? '再度ログインしてから退会操作を行ってください'
          : '退会処理に失敗しました';
      showTopNotification(context, msg);
    } catch (_) {
      if (mounted) {
        showTopNotification(context, '退会処理に失敗しました');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 8, 4),
            child: Text(
              'プロフィール',
              style: camillBodyStyle(30, colors.textPrimary, weight: FontWeight.w800),
            ),
          ),
          // ユーザー情報ヘッダー
          Container(
            color: colors.primary.withAlpha(20),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colors.primaryLight,
                  backgroundImage: _avatarPath != null
                      ? FileImage(File(_avatarPath!))
                      : null,
                  child: _avatarPath == null
                      ? Text(
                          _displayName.isNotEmpty ? _displayName[0] : 'U',
                          style: camillHeadingStyle(24, colors.primary),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_displayName,
                          style: camillHeadingStyle(18, colors.textPrimary)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isDeveloper
                              ? Colors.purple.withAlpha(20)
                              : colors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _planLabel,
                          style: camillBodyStyle(
                            12,
                            _isDeveloper ? Colors.purple : colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: 'アカウント', colors: colors),
          _SettingsItem(
            icon: Icons.person_outline,
            title: '表示名',
            colors: colors,
            onTap: _openAccountSettings,
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: '収入・支出', colors: colors),
          _SettingsItem(
            icon: Icons.payments_outlined,
            title: '収入の設定',
            subtitle: _incomeSummary,
            colors: colors,
            onTap: _openIncomeSettings,
          ),
          _SettingsItem(
            icon: Icons.account_balance_wallet_outlined,
            title: '月の予算',
            subtitle: '¥${_budget.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}',
            colors: colors,
            onTap: () async {
              await context.push('/category-budget');
              if (mounted) _loadBudget();
            },
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: 'アプリ設定', colors: colors),
          _SettingsItem(
            icon: Icons.settings_outlined,
            title: 'アプリ設定',
            subtitle: 'テーマ・セキュリティ・通知など',
            colors: colors,
            onTap: () => context.push('/settings'),
          ),
          _SettingsItem(
            icon: Icons.people_alt_outlined,
            title: 'コミュニティ設定',
            subtitle: 'クーポンシェア・通知設定',
            colors: colors,
            onTap: () => context.push('/community-settings'),
          ),
          if (_plan == 'family')
            _SettingsItem(
              icon: Icons.group_outlined,
              title: 'ファミリー管理',
              colors: colors,
              onTap: () => context.push('/family'),
            ),
          const SizedBox(height: 8),
          _SectionHeader(title: 'プラン', colors: colors),
          _SettingsItem(
            icon: Icons.workspace_premium_outlined,
            title: 'プラン・課金管理',
            subtitle: _planLabel,
            colors: colors,
            onTap: () async {
              await context.push('/plan');
              if (mounted) _loadBillingStatus();
            },
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: 'その他', colors: colors),
          _SettingsItem(
            icon: Icons.support_agent_outlined,
            title: 'お問い合わせ',
            colors: colors,
            onTap: () => context.push('/support'),
          ),
          _SettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'プライバシーポリシー',
            colors: colors,
            onTap: () => _openUrl(AppConstants.privacyPolicyUrl),
          ),
          _SettingsItem(
            icon: Icons.description_outlined,
            title: '利用規約',
            colors: colors,
            onTap: () => _openUrl(AppConstants.termsOfServiceUrl),
          ),
          _SettingsItem(
            icon: Icons.logout,
            title: 'ログアウト',
            colors: colors,
            onTap: () async {
              final router = GoRouter.of(context);
              await _authService.signOut();
              router.go('/login');
            },
          ),
          Divider(color: colors.surfaceBorder),
          _SettingsItem(
            icon: Icons.delete_forever_outlined,
            title: '退会する',
            titleColor: colors.danger,
            colors: colors,
            onTap: () => _confirmDelete(colors),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── 共通ウィジェット ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final CamillColors colors;

  const _SectionHeader({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: camillBodyStyle(12, colors.textMuted, weight: FontWeight.w600),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final CamillColors colors;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: titleColor ?? colors.textSecondary, size: 22),
      title: Text(
        title,
        style: camillBodyStyle(15, titleColor ?? colors.textPrimary),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: camillBodyStyle(12, colors.textMuted))
          : null,
      trailing: Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
      onTap: onTap,
    );
  }
}
