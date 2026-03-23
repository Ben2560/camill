import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../core/theme/camill_theme_mode.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/services/auth_service.dart';
import '../../../shared/widgets/top_notification.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _weekStartKey = 'week_start_sunday';

  final _authService = AuthService();
  bool _weekStartsSunday = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _weekStartsSunday = prefs.getBool(_weekStartKey) ?? true;
    });
  }

  Future<void> _showSecurity(CamillColors colors) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('パスワード変更',
            style: camillHeadingStyle(16, colors.textPrimary)),
        content: Text(
          '$email 宛にパスワード再設定メールを送信します。',
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
            child: Text('送信',
                style: camillBodyStyle(14, colors.primary,
                    weight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _authService.sendPasswordResetEmail();
      if (mounted) {
        showTopNotification(context, 'パスワード再設定メールを送信しました', backgroundColor: colors.primary);
      }
    } catch (_) {
      if (mounted) {
        showTopNotification(context, 'メール送信に失敗しました');
      }
    }
  }

  Future<void> _setWeekStart(bool sunday) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weekStartKey, sunday);
    if (!mounted) return;
    setState(() => _weekStartsSunday = sunday);
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
              child: Text('週の開始曜日',
                  style: camillBodyStyle(17, colors.textPrimary,
                      weight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text('日曜日始まり',
                  style: camillBodyStyle(15, colors.textPrimary)),
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
              title: Text('月曜日始まり',
                  style: camillBodyStyle(15, colors.textPrimary)),
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
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title:
            Text('アプリ設定', style: camillHeadingStyle(17, colors.textPrimary)),
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
          _SectionHeader(title: '表示', colors: colors),
          _SettingsItem(
            icon: Icons.palette_outlined,
            title: 'テーマ',
            subtitle: themeMode.displayName,
            colors: colors,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _ThemePickerSheet(colors: colors, ref: ref),
            ),
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

// ── テーマ選択モーダル ────────────────────────────────────────────────────────
class _ThemePickerSheet extends StatelessWidget {
  final CamillColors colors;
  final WidgetRef ref;

  const _ThemePickerSheet({required this.colors, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textMuted.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text('テーマ選択',
                style: camillHeadingStyle(16, colors.textPrimary)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _ThemeGrid(colors: colors, ref: ref),
          ),
        ],
      ),
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  final CamillColors colors;
  final WidgetRef ref;

  const _ThemeGrid({required this.colors, required this.ref});

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(themeProvider);
    final themes = CamillThemeMode.values.where((m) => !m.hasCat).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: themes.length,
      itemBuilder: (context, i) {
        final mode = themes[i];
        final modeColors = CamillColors.fromMode(mode);
        final isSelected = mode == currentMode;

        return GestureDetector(
          onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
          child: Container(
            decoration: BoxDecoration(
              color: modeColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? colors.primary : colors.surfaceBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: modeColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: modeColors.background,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: modeColors.surfaceBorder),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        mode.displayName,
                        style: TextStyle(
                          fontSize: 9,
                          color: modeColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, size: 10, color: colors.fabIcon),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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
