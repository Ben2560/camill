import 'package:flutter/material.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/top_notification.dart' as notif;
import '../services/community_service.dart';

class CommunitySettingsScreen extends StatefulWidget {
  const CommunitySettingsScreen({super.key});

  @override
  State<CommunitySettingsScreen> createState() =>
      _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends State<CommunitySettingsScreen> {
  final _service = CommunityService();
  bool _loading = true;
  bool _saving = false;

  bool _shareEnabled = true;
  bool _notifyAll = true;
  List<String> _selectedStoreIds = [];
  int _remainingChanges = 3;
  DateTime? _nextResetDate;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _service.fetchSettings();
      if (!mounted) return;
      setState(() {
        _shareEnabled = settings.shareEnabled;
        _notifyAll = settings.notifyAll;
        _selectedStoreIds = settings.selectedStoreIds;
        _remainingChanges = settings.remainingChanges;
        _nextResetDate = settings.nextResetDate;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _updateSetting({bool? shareEnabled, bool? notifyAll}) async {
    setState(() => _saving = true);
    try {
      final settings = await _service.updateSettings(
        shareEnabled: shareEnabled,
        notifyAll: notifyAll,
      );
      if (!mounted) return;
      setState(() {
        _shareEnabled = settings.shareEnabled;
        _notifyAll = settings.notifyAll;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      notif.showTopNotification(context, '設定の更新に失敗しました');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LoadingOverlay(
      isLoading: _saving,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('コミュニティ設定'),
          backgroundColor: colors.background,
        ),
        body: _loading
            ? Center(
                child: CircularProgressIndicator(color: colors.primary),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSection(
                    colors,
                    'クーポンシェア',
                    [
                      _buildSwitchTile(
                        colors,
                        icon: Icons.share_outlined,
                        title: 'クーポン情報をシェア',
                        subtitle:
                            'OCRで検出したクーポンを地域のユーザーと匿名で共有します',
                        value: _shareEnabled,
                        onChanged: (v) => _updateSetting(shareEnabled: v),
                      ),
                    ],
                  ),
                  _buildSection(
                    colors,
                    '通知',
                    [
                      _buildSwitchTile(
                        colors,
                        icon: Icons.notifications_outlined,
                        title: '全クーポン通知',
                        subtitle: '近くの店舗に新しいクーポンが共有されたら通知',
                        value: _notifyAll,
                        onChanged: (v) => _updateSetting(notifyAll: v),
                      ),
                    ],
                  ),
                  _buildSection(
                    colors,
                    '店舗選択（無料プラン）',
                    [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '選択中の店舗: ${_selectedStoreIds.length}/2',
                              style: camillBodyStyle(
                                14,
                                colors.textPrimary,
                                weight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '残り変更回数: $_remainingChanges回',
                              style:
                                  camillBodyStyle(13, colors.textSecondary),
                            ),
                            if (_nextResetDate != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '次のリセット: ${_nextResetDate!.month}/${_nextResetDate!.day}',
                                style:
                                    camillBodyStyle(13, colors.textSecondary),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'クーポン詳細を閲覧したい店舗を地図画面から選択できます。3ヶ月に1回リセットされます。',
                              style: camillBodyStyle(12, colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSection(
    CamillColors colors,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            title,
            style: camillBodyStyle(
              12,
              colors.textMuted,
              weight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
        Divider(color: colors.surfaceBorder, height: 1),
      ],
    );
  }

  Widget _buildSwitchTile(
    CamillColors colors, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: camillBodyStyle(
                    14,
                    colors.textPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: camillBodyStyle(12, colors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.primary,
          ),
        ],
      ),
    );
  }
}
