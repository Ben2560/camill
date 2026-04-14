import 'package:flutter/material.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/top_notification.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _api = ApiService();
  bool _loading = true;

  bool _budgetOver = true;
  bool _weeklyPace = true;
  bool _categoryBudgetAlert = false;
  bool _scoreReport = true;
  int _scoreReportTime = 21;
  bool _weeklyReport = true;
  bool _monthlyReport = true;
  bool _couponToday = true;
  bool _coupon3days = true;
  bool _billReminder = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final data = await _api.get('/users/notification-settings');
      setState(() {
        _budgetOver = data['budget_over'] as bool? ?? true;
        _weeklyPace = data['weekly_pace'] as bool? ?? true;
        _categoryBudgetAlert = data['category_budget_alert'] as bool? ?? false;
        _scoreReport = data['score_report'] as bool? ?? true;
        _scoreReportTime = (data['score_report_time'] as num?)?.toInt() ?? 21;
        _weeklyReport = data['weekly_report'] as bool? ?? true;
        _monthlyReport = data['monthly_report'] as bool? ?? true;
        _couponToday = data['coupon_today'] as bool? ?? true;
        _coupon3days = data['coupon_3days'] as bool? ?? true;
        _billReminder = data['bill_reminder'] as bool? ?? true;
      });
    } catch (e) {
      debugPrint('notification settings load failed: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _updateSetting(Map<String, dynamic> patch) async {
    try {
      await _api.patch('/users/notification-settings', body: patch);
    } catch (e) {
      if (mounted) {
        showTopNotification(context, '設定の保存に失敗しました: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          title: Text('通知設定', style: camillHeadingStyle(17, colors.textPrimary)),
          iconTheme: IconThemeData(color: colors.textSecondary),
        ),
        body: ListView(
          children: [
            const _SectionHeader(title: '予算通知'),
            _SettingTile(
              title: '月予算超過通知',
              value: _budgetOver,
              onChanged: (v) {
                setState(() => _budgetOver = v);
                _updateSetting({'budget_over': v});
              },
            ),
            _SettingTile(
              title: '週次ペース超過警告',
              value: _weeklyPace,
              onChanged: (v) {
                setState(() => _weeklyPace = v);
                _updateSetting({'weekly_pace': v});
              },
            ),
            _SettingTile(
              title: 'カテゴリ別予算アラート',
              subtitle: 'カテゴリが80%・100%を超えた時',
              value: _categoryBudgetAlert,
              onChanged: (v) {
                setState(() => _categoryBudgetAlert = v);
                _updateSetting({'category_budget_alert': v});
              },
            ),
            const _SectionHeader(title: 'スコア・レポート通知'),
            _SettingTile(
              title: '毎日のスコア報告',
              value: _scoreReport,
              onChanged: (v) {
                setState(() => _scoreReport = v);
                _updateSetting({'score_report': v});
              },
            ),
            if (_scoreReport)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Text('報告時刻',
                        style: camillBodyStyle(14, colors.textPrimary)),
                    const Spacer(),
                    DropdownButton<int>(
                      value: _scoreReportTime,
                      underline: const SizedBox(),
                      items: [18, 19, 20, 21, 22]
                          .map((h) => DropdownMenuItem(
                                value: h,
                                child: Text('$h時'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _scoreReportTime = v);
                        _updateSetting({'score_report_time': v});
                      },
                    ),
                  ],
                ),
              ),
            _SettingTile(
              title: '週次レポート',
              subtitle: '毎週月曜朝9時',
              value: _weeklyReport,
              onChanged: (v) {
                setState(() => _weeklyReport = v);
                _updateSetting({'weekly_report': v});
              },
            ),
            _SettingTile(
              title: '月次決算レポート',
              subtitle: '月末',
              value: _monthlyReport,
              onChanged: (v) {
                setState(() => _monthlyReport = v);
                _updateSetting({'monthly_report': v});
              },
            ),
            const _SectionHeader(title: 'クーポン通知'),
            _SettingTile(
              title: '期限当日通知',
              subtitle: '当日朝8時',
              value: _couponToday,
              onChanged: (v) {
                setState(() => _couponToday = v);
                _updateSetting({'coupon_today': v});
              },
            ),
            _SettingTile(
              title: '期限3日前通知',
              value: _coupon3days,
              onChanged: (v) {
                setState(() => _coupon3days = v);
                _updateSetting({'coupon_3days': v});
              },
            ),
            const _SectionHeader(title: '請求書通知'),
            _SettingTile(
              title: '支払期限リマインド',
              subtitle: '3日前・前日・当日',
              value: _billReminder,
              onChanged: (v) {
                setState(() => _billReminder = v);
                _updateSetting({'bill_reminder': v});
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(title,
          style: camillBodyStyle(13, c.textMuted, weight: FontWeight.w600)),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SwitchListTile(
      title: Text(title, style: camillBodyStyle(15, c.textPrimary)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: camillBodyStyle(12, c.textMuted))
          : null,
      value: value,
      activeThumbColor: c.primary,
      onChanged: onChanged,
    );
  }
}
