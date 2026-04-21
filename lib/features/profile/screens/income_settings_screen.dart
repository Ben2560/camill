import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services/user_prefs.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/widgets/camill_card.dart';
import '../../../shared/widgets/top_notification.dart';

class IncomeSettingsScreen extends StatefulWidget {
  const IncomeSettingsScreen({super.key});

  @override
  State<IncomeSettingsScreen> createState() => _IncomeSettingsScreenState();
}

class _IncomeSettingsScreenState extends State<IncomeSettingsScreen> {
  static const _monthlyIncomeKey = 'income_monthly';
  static const _paydayKey = 'income_payday';
  static const _paydayTypeKey = 'income_payday_type';
  static const _sideIncomeKey = 'income_side';

  late final TextEditingController _incomeCtrl;
  late final TextEditingController _paydayCtrl;
  late final TextEditingController _sideCtrl;
  String _paydayType = 'before';
  bool _saving = false;

  static const _typeOptions = [
    ('before', '土日は前倒し'),
    ('after', '土日は翌営業日'),
    ('exact', '土日も同日'),
  ];

  @override
  void initState() {
    super.initState();
    _incomeCtrl = TextEditingController();
    _paydayCtrl = TextEditingController();
    _sideCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _paydayCtrl.dispose();
    _sideCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final income = await UserPrefs.getInt(prefs, _monthlyIncomeKey) ?? 0;
    final side = await UserPrefs.getInt(prefs, _sideIncomeKey) ?? 0;
    final payday = await UserPrefs.getInt(prefs, _paydayKey) ?? 0;
    final paydayType =
        await UserPrefs.getString(prefs, _paydayTypeKey) ?? 'before';
    if (!mounted) return;
    setState(() {
      _incomeCtrl.text = income > 0 ? income.toString() : '';
      _paydayCtrl.text = payday > 0 ? payday.toString() : '';
      _sideCtrl.text = side > 0 ? side.toString() : '';
      _paydayType = paydayType;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await UserPrefs.setInt(
        prefs,
        _monthlyIncomeKey,
        int.tryParse(_incomeCtrl.text) ?? 0,
      );
      await UserPrefs.setInt(
        prefs,
        _paydayKey,
        int.tryParse(_paydayCtrl.text) ?? 0,
      );
      await UserPrefs.setString(prefs, _paydayTypeKey, _paydayType);
      await UserPrefs.setInt(
        prefs,
        _sideIncomeKey,
        int.tryParse(_sideCtrl.text) ?? 0,
      );
      if (mounted) {
        showTopNotification(context, '保存しました');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) showTopNotification(context, '保存に失敗しました');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: colors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('収入の設定', style: camillHeadingStyle(17, colors.textPrimary)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              '保存',
              style: camillBodyStyle(
                15,
                colors.primary,
                weight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            // 月収カード
            _CardLabel(
              icon: Icons.payments_outlined,
              title: '月収（手取り）',
              colors: colors,
            ),
            const SizedBox(height: 8),
            CamillCard(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '手取り金額（税引き後）',
                    style: camillBodyStyle(12, colors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  _AmountField(
                    controller: _incomeCtrl,
                    colors: colors,
                    autofocus: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 給料日カード
            _CardLabel(
              icon: Icons.calendar_today_outlined,
              title: '給料日',
              colors: colors,
            ),
            const SizedBox(height: 8),
            CamillCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 土日の扱い
                  Text('土日祝の場合', style: camillBodyStyle(12, colors.textMuted)),
                  const SizedBox(height: 10),
                  Row(
                    children: _typeOptions.map((opt) {
                      final (value, label) = opt;
                      final isSelected = value == _paydayType;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _paydayType = value),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.primary
                                  : colors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? colors.primary
                                    : colors.surfaceBorder,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: camillBodyStyle(
                                11,
                                isSelected
                                    ? colors.fabIcon
                                    : colors.textSecondary,
                                weight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('振込日', style: camillBodyStyle(12, colors.textMuted)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.surfaceBorder,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _paydayCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _DayRangeFormatter(),
                            ],
                            style: camillAmountStyle(22, colors.textPrimary),
                            decoration: InputDecoration(
                              hintText: '25',
                              hintStyle: camillAmountStyle(
                                22,
                                colors.textMuted.withAlpha(100),
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '日',
                          style: camillBodyStyle(
                            16,
                            colors.textMuted,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 副収入カード
            Row(
              children: [
                _CardLabel(
                  icon: Icons.add_card_outlined,
                  title: '副収入（月額）',
                  colors: colors,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '任意',
                    style: camillBodyStyle(
                      10,
                      colors.primary,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CamillCard(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '副業・フリーランス・配当など',
                    style: camillBodyStyle(12, colors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  _AmountField(controller: _sideCtrl, colors: colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 1〜31 の範囲に制限するフォーマッター
class _DayRangeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    if (next.text.isEmpty) return next;
    final val = int.tryParse(next.text);
    if (val == null) return old;
    if (val < 1) return next.copyWith(text: '1');
    if (val > 31) return old;
    return next;
  }
}

class _CardLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final CamillColors colors;

  const _CardLabel({
    required this.icon,
    required this.title,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: colors.textMuted),
        const SizedBox(width: 6),
        Text(
          title,
          style: camillBodyStyle(13, colors.textMuted, weight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final CamillColors colors;
  final bool autofocus;

  const _AmountField({
    required this.controller,
    required this.colors,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.surfaceBorder, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: camillAmountStyle(26, colors.textPrimary),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: camillAmountStyle(
                  26,
                  colors.textMuted.withAlpha(100),
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '円',
            style: camillBodyStyle(
              16,
              colors.textMuted,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
