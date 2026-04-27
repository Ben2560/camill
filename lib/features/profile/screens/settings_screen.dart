import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services/biometric_service.dart';
import '../../../shared/services/user_prefs.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/services/auth_service.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/top_notification.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _weekStartKey = 'week_start_sunday';

  final _authService = AuthService();
  final _api = ApiService();
  final _biometricService = BiometricService();
  bool _weekStartsSunday = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = await UserPrefs.getBool(prefs, _weekStartKey);
    if (!mounted) return;
    setState(() => _weekStartsSunday = v ?? true);

    try {
      final data = await _api.get('/users/preferences');
      final apiVal = data['week_start_sunday'] as bool? ?? true;
      final p = await SharedPreferences.getInstance();
      await UserPrefs.setBool(p, _weekStartKey, apiVal);
      if (mounted) setState(() => _weekStartsSunday = apiVal);
    } catch (_) {}

    final available = await _biometricService.isAvailable();
    final enabled = await _biometricService.isEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final success = await _biometricService.authenticate();
      if (!success || !mounted) return;
    }
    await _biometricService.setEnabled(value);
    if (mounted) setState(() => _biometricEnabled = value);
  }

  Future<void> _showSecurity(CamillColors colors) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'パスワード変更',
          style: camillHeadingStyle(16, colors.textPrimary),
        ),
        content: Text(
          '$email 宛にパスワード再設定メールを送信します。',
          style: camillBodyStyle(14, colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'キャンセル',
              style: camillBodyStyle(14, colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '送信',
              style: camillBodyStyle(
                14,
                colors.primary,
                weight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _authService.sendPasswordResetEmail();
      if (mounted) {
        showTopNotification(
          context,
          'パスワード再設定メールを送信しました',
          backgroundColor: colors.primary,
        );
      }
    } catch (_) {
      if (mounted) {
        showTopNotification(context, 'メール送信に失敗しました');
      }
    }
  }

  Future<void> _setWeekStart(bool sunday) async {
    final prefs = await SharedPreferences.getInstance();
    await UserPrefs.setBool(prefs, _weekStartKey, sunday);
    if (!mounted) return;
    setState(() => _weekStartsSunday = sunday);
    try {
      await _api.patch(
        '/users/preferences',
        body: {'week_start_sunday': sunday},
      );
    } catch (_) {}
  }

  void _showWeekStartSheet(CamillColors colors) {
    showModalBottomSheet(
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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                '週の開始曜日',
                style: camillBodyStyle(
                  17,
                  colors.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text(
                '日曜日始まり',
                style: camillBodyStyle(15, colors.textPrimary),
              ),
              leading: Icon(
                _weekStartsSunday
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: _weekStartsSunday ? colors.primary : colors.textMuted,
              ),
              onTap: () {
                Navigator.pop(ctx);
                _setWeekStart(true);
              },
            ),
            ListTile(
              title: Text(
                '月曜日始まり',
                style: camillBodyStyle(15, colors.textPrimary),
              ),
              leading: Icon(
                !_weekStartsSunday
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: !_weekStartsSunday ? colors.primary : colors.textMuted,
              ),
              onTap: () {
                Navigator.pop(ctx);
                _setWeekStart(false);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text('アプリ設定', style: camillHeadingStyle(17, colors.textPrimary)),
        iconTheme: IconThemeData(color: colors.textSecondary),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: 'セキュリティ', colors: colors),
          _SettingsItem(
            icon: Icons.security,
            title: 'セキュリティ',
            subtitle: 'パスワード変更',
            colors: colors,
            onTap: () => _showSecurity(colors),
          ),
          if (_biometricAvailable)
            SwitchListTile(
              secondary: Icon(
                Icons.fingerprint,
                color: colors.textSecondary,
                size: 22,
              ),
              title: Text(
                'Face ID / Touch ID ロック',
                style: camillBodyStyle(15, colors.textPrimary),
              ),
              subtitle: Text(
                'バックグラウンド復帰時に認証',
                style: camillBodyStyle(12, colors.textMuted),
              ),
              value: _biometricEnabled,
              activeThumbColor: colors.primary,
              onChanged: _toggleBiometric,
            ),
          _SectionHeader(title: '表示', colors: colors),
          _SettingsItem(
            icon: Icons.palette_outlined,
            title: 'テーマ',
            subtitle: themeState.selectedBase.displayName,
            colors: colors,
            onTap: () => context.push('/theme-settings'),
          ),
          _SectionHeader(title: 'カレンダー・週', colors: colors),
          _SettingsItem(
            icon: Icons.calendar_today_outlined,
            title: '週の開始曜日',
            subtitle: _weekStartsSunday ? '日曜日始まり' : '月曜日始まり',
            colors: colors,
            onTap: () => _showWeekStartSheet(colors),
          ),
          _SectionHeader(title: '通知', colors: colors),
          _SettingsItem(
            icon: Icons.notifications_outlined,
            title: '通知設定',
            colors: colors,
            onTap: () => context.push('/notification-settings'),
          ),
        ],
      ),
    );
  }
}

// ── 共通パーツ ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final CamillColors colors;
  const _SectionHeader({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
  final CamillColors colors;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: colors.textSecondary, size: 22),
      title: Text(title, style: camillBodyStyle(15, colors.textPrimary)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: camillBodyStyle(12, colors.textMuted))
          : null,
      trailing: Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
      onTap: onTap,
    );
  }
}
