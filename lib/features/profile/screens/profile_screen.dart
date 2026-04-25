import 'dart:io';
import 'dart:convert';
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
import '../../home/screens/fixed_expense_scan_screen.dart';
import '../../home/screens/home_screen.dart';
import '../services/drive_export_service.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/overseas_service.dart';
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

  // データ管理
  final _driveService = DriveExportService();
  int _receiptCount = 0;
  int _estimatedBytes = 0;
  bool _driveConnected = false;
  bool _storageLoaded = false;
  bool _isExporting = false;
  bool _exportDone = false;
  double _exportProgress = 0.0;
  DateTime? _lastBackupAt;

  static const _lastBackupKey = 'drive_last_backup_at';

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
    _loadStorageUsage();
    _loadLastBackupAt();
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
    final dir = await getApplicationDocumentsDirectory();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'default';
    final expectedName = 'profile_avatar_$uid.jpg';
    final expectedPath = '${dir.path}/$expectedName';

    if (stored != null) {
      final fileName = stored.contains('/') ? stored.split('/').last : stored;
      if (fileName != expectedName) {
        final oldPath = '${dir.path}/$fileName';
        if (File(oldPath).existsSync() && !File(expectedPath).existsSync()) {
          await File(oldPath).copy(expectedPath);
        }
      }
    }

    if (!mounted) return;
    if (File(expectedPath).existsSync()) {
      setState(() => _avatarPath = expectedPath);
      return;
    }

    // ローカルにない → サーバーから復元（最大2回リトライ）
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final profile = await _authService.fetchProfile();
        final avatarData = profile['avatar_data'] as String?;
        if (avatarData == null || avatarData.isEmpty) break;
        final b64 = avatarData.contains(',')
            ? avatarData.split(',').last
            : avatarData;
        final bytes = base64Decode(b64);
        await File(expectedPath).writeAsBytes(bytes);
        final p = await SharedPreferences.getInstance();
        await UserPrefs.setString(p, _avatarPathKey, expectedName);
        if (mounted) setState(() => _avatarPath = expectedPath);
        return;
      } catch (e) {
        debugPrint('avatar restore attempt ${attempt + 1} failed: $e');
        if (attempt < 1) await Future.delayed(const Duration(seconds: 2));
      }
    }
    if (mounted) setState(() => _avatarPath = null);
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

    // APIから最新値を同期
    try {
      final data = await _apiService.get('/users/preferences');
      final apiIncome = (data['monthly_income'] as num?)?.toInt() ?? 0;
      final apiPayday = (data['income_payday'] as num?)?.toInt() ?? 0;
      final apiSide = (data['side_income'] as num?)?.toInt() ?? 0;
      final p = await SharedPreferences.getInstance();
      await UserPrefs.setInt(p, _monthlyIncomeKey, apiIncome);
      await UserPrefs.setInt(p, _paydayKey, apiPayday);
      await UserPrefs.setInt(p, _sideIncomeKey, apiSide);
      if (mounted) {
        setState(() {
          _monthlyIncome = apiIncome;
          _payday = apiPayday;
          _sideIncome = apiSide;
        });
      }
    } catch (_) {}
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
    if (mounted) {
      setState(() {});
      _loadAvatar();
    }
  }

  // ── URL起動 ─────────────────────────────────────────────────────────────────
  Future<void> _loadStorageUsage() async {
    try {
      final connected = await _driveService.isSignedIn;
      final data = await _apiService.get('/users/storage-usage');
      if (!mounted) return;
      setState(() {
        _receiptCount = data['receipt_count'] as int? ?? 0;
        _estimatedBytes = data['estimated_bytes'] as int? ?? 0;
        _driveConnected = connected;
        _storageLoaded = true;
      });
    } catch (e) {
      debugPrint('storage usage load failed: $e');
      if (mounted) setState(() => _storageLoaded = true);
    }
  }

  Future<void> _loadLastBackupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await UserPrefs.getString(prefs, _lastBackupKey);
    if (saved != null && mounted) {
      setState(() => _lastBackupAt = DateTime.tryParse(saved));
    }
  }

  Future<void> _saveLastBackupAt(DateTime dt) async {
    final prefs = await SharedPreferences.getInstance();
    await UserPrefs.setString(prefs, _lastBackupKey, dt.toIso8601String());
  }

  Future<void> _exportToDrive() async {
    if (_isExporting) return;
    setState(() {
      _isExporting = true;
      _exportDone = false;
      _exportProgress = 0.0;
    });

    // step → progress マッピング (4ステップ)
    const progressMap = {0: 0.1, 1: 0.4, 2: 0.65, 3: 0.85, 4: 1.0};

    try {
      await _driveService.exportToDrive(
        onStep: (step, _) {
          if (mounted) {
            setState(
              () => _exportProgress =
                  progressMap[step]?.toDouble() ?? _exportProgress,
            );
          }
        },
      );
      if (!mounted) return;
      final now = DateTime.now();
      await _saveLastBackupAt(now);
      setState(() {
        _exportProgress = 1.0;
        _exportDone = true;
        _driveConnected = true;
        _lastBackupAt = now;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() {
        _isExporting = false;
        _exportDone = false;
        _exportProgress = 0.0;
      });
    } catch (e) {
      debugPrint('Drive export error: $e');
      if (!mounted) return;
      setState(() {
        _isExporting = false;
        _exportDone = false;
        _exportProgress = 0.0;
      });
      final msg = e.toString().contains('キャンセル')
          ? 'キャンセルされました'
          : 'エクスポートに失敗しました';
      showTopNotification(context, msg);
    }
  }

  String _formatBackupTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inHours < 1) return '${diff.inMinutes}分前';
    if (diff.inDays < 1) return '${diff.inHours}時間前';
    if (diff.inDays < 2) {
      return '昨日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

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
        title: Text('退会確認', style: camillHeadingStyle(16, colors.textPrimary)),
        content: Text(
          'アカウントを削除すると、すべてのデータが失われます。本当に退会しますか？',
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
              '退会する',
              style: camillBodyStyle(
                14,
                colors.danger,
                weight: FontWeight.w700,
              ),
            ),
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
              'マイページ',
              style: camillBodyStyle(
                30,
                colors.textPrimary,
                weight: FontWeight.w800,
              ),
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
                      Text(
                        _displayName,
                        style: camillHeadingStyle(18, colors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
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
          _SectionHeader(title: 'データ管理', colors: colors),
          if (_storageLoaded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.surfaceBorder),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.storage_outlined,
                          size: 16,
                          color: colors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '使用データ量',
                          style: camillBodyStyle(
                            12,
                            colors.textMuted,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _DataStatItem(
                          label: 'レシート',
                          value: '$_receiptCount件',
                          colors: colors,
                        ),
                        _DataStatItem(
                          label: '概算サイズ',
                          value: _formatBytes(_estimatedBytes),
                          colors: colors,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AnimatedSlide(
                      offset: _isExporting
                          ? const Offset(0, -0.15)
                          : Offset.zero,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isExporting ? null : _exportToDrive,
                          icon: _isExporting && !_exportDone
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _exportDone
                                      ? Icons.check_circle_outline
                                      : Icons.cloud_upload_outlined,
                                  size: 18,
                                ),
                          label: Text(
                            _exportDone
                                ? 'バックアップが完了しました'
                                : _isExporting
                                ? 'バックアップ中...'
                                : _driveConnected
                                ? 'Google Driveにバックアップ'
                                : 'Google Driveに接続してバックアップ',
                            style: camillBodyStyle(
                              13,
                              Colors.white,
                              weight: FontWeight.w600,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _exportDone
                                ? const Color(0xFF34A853)
                                : const Color(0xFF4285F4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: _isExporting
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _exportProgress,
                                  minHeight: 4,
                                  backgroundColor: colors.surfaceBorder,
                                  color: _exportDone
                                      ? const Color(0xFF34A853)
                                      : const Color(0xFF4285F4),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (_lastBackupAt != null) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '最終バックアップ: ${_formatBackupTime(_lastBackupAt!)}',
                          style: camillBodyStyle(11, colors.textMuted),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
            subtitle:
                '¥${_budget.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}',
            colors: colors,
            onTap: () async {
              await context.push('/category-budget');
              if (mounted) _loadBudget();
            },
          ),
          _SettingsItem(
            icon: Icons.subscriptions_outlined,
            title: 'サブスク管理',
            subtitle: 'スクショから一括追加・種別管理',
            colors: colors,
            onTap: () => context.push('/subscriptions'),
          ),
          _SettingsItem(
            icon: Icons.account_balance_outlined,
            title: '固定費の確認',
            subtitle: '銀行明細で引き落とし状況を確認',
            colors: colors,
            onTap: () {
              Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const FixedExpenseScanScreen(),
                ),
              );
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
          // ── デベロッパー専用：旅行モードテスト ──
          if (_isDeveloper) ...[
            Divider(color: colors.surfaceBorder),
            _SectionHeader(title: '🛠 旅行モード テスト', colors: colors),
            _OverseasDebugPanel(colors: colors),
          ],

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
      leading: Icon(icon, color: titleColor ?? colors.textSecondary, size: 22),
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

// ── 旅行モード デバッグパネル（開発者専用） ────────────────────────────────────

class _OverseasDebugPanel extends StatefulWidget {
  final CamillColors colors;
  const _OverseasDebugPanel({required this.colors});

  @override
  State<_OverseasDebugPanel> createState() => _OverseasDebugPanelState();
}

class _OverseasDebugPanelState extends State<_OverseasDebugPanel> {
  late final _service = OverseasService(ApiService());
  bool _isOverseas = false;
  String _currency = 'JPY';
  bool _loading = false;

  static const _testCountries = [
    ('🇯🇵 日本（JPY）', false, 'JPY', 'JP'),
    ('🇹🇭 タイ（THB）', true, 'THB', 'TH'),
    ('🇺🇸 アメリカ（USD）', true, 'USD', 'US'),
    ('🇰🇷 韓国（KRW）', true, 'KRW', 'KR'),
    ('🇨🇳 中国（CNY）', true, 'CNY', 'CN'),
    ('🇸🇬 シンガポール（SGD）', true, 'SGD', 'SG'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final overseas = await _service.getIsOverseas();
    final currency = await _service.getCurrentCurrency();
    if (mounted) {
      setState(() {
        _isOverseas = overseas;
        _currency = currency;
      });
    }
  }

  Future<void> _apply(
    bool isOverseas,
    String currency,
    String countryCode,
  ) async {
    setState(() => _loading = true);
    await _service.applyOverseasStatus(
      isOverseas: isOverseas,
      currency: currency,
      countryCode: countryCode,
    );
    if (mounted) {
      setState(() {
        _isOverseas = isOverseas;
        _currency = currency;
        _loading = false;
      });
      HomeScreen.overseasRefreshSignal.value++;
      showTopNotification(
        context,
        isOverseas ? '✈️ $currency モードに切り替えました' : '🏠 日本円（JPY）に戻しました',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '現在: ${_isOverseas ? "✈️ 海外モード ($_currency)" : "🏠 国内モード (JPY)"}',
            style: camillBodyStyle(
              13,
              _isOverseas ? colors.primary : colors.textMuted,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _testCountries.map((entry) {
              final (label, overseas, currency, code) = entry;
              final isSelected = _currency == currency;
              return GestureDetector(
                onTap: _loading ? null : () => _apply(overseas, currency, code),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary.withAlpha(30)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.surfaceBorder,
                    ),
                  ),
                  child: Text(
                    label,
                    style: camillBodyStyle(
                      12,
                      isSelected ? colors.primary : colors.textSecondary,
                      weight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_loading) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              color: colors.primary,
              backgroundColor: colors.primaryLight,
            ),
          ],
        ],
      ),
    );
  }
}

class _DataStatItem extends StatelessWidget {
  final String label;
  final String value;
  final CamillColors colors;

  const _DataStatItem({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: camillBodyStyle(
            16,
            colors.textPrimary,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: camillBodyStyle(11, colors.textMuted)),
      ],
    );
  }
}
