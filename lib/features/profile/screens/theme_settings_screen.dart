import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../core/theme/camill_theme_mode.dart';
import '../../../core/theme/theme_provider.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors    = context.colors;
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text('テーマ設定', style: camillHeadingStyle(17, colors.textPrimary)),
        iconTheme: IconThemeData(color: colors.textSecondary),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── テーマ選択グリッド ────────────────────────────────────
          _SectionHeader(title: 'テーマ', colors: colors),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ThemeGrid(themeState: themeState, ref: ref, colors: colors),
          ),
          // ── 切り替え時間 ──────────────────────────────────────────
          _SectionHeader(title: '日中 / 夜間の切り替え時刻', colors: colors),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.surfaceBorder),
              ),
              child: Column(
                children: [
                  _TimeRow(
                    icon: Icons.wb_sunny_outlined,
                    label: '朝の開始',
                    hour: themeState.morningStartHour,
                    colors: colors,
                    onTap: () => _pickHour(
                      context,
                      colors,
                      initial: themeState.morningStartHour,
                      onPicked: (h) =>
                          ref.read(themeProvider.notifier).setMorningStartHour(h),
                    ),
                  ),
                  Divider(height: 1, color: colors.surfaceBorder),
                  _TimeRow(
                    icon: Icons.nightlight_outlined,
                    label: '夜間の開始',
                    hour: themeState.nightStartHour,
                    colors: colors,
                    onTap: () => _pickHour(
                      context,
                      colors,
                      initial: themeState.nightStartHour,
                      onPicked: (h) =>
                          ref.read(themeProvider.notifier).setNightStartHour(h),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ── 現在の状態表示 ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    themeState.isDarkNow
                        ? Icons.nightlight_round
                        : Icons.wb_sunny_rounded,
                    color: colors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    themeState.isDarkNow
                        ? '現在: 夜間モード (ダークバリアント)'
                        : '現在: 日中モード (ライトバリアント)',
                    style: camillBodyStyle(13, colors.primary,
                        weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickHour(
    BuildContext context,
    CamillColors colors, {
    required int initial,
    required void Function(int) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial, minute: 0),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary:   colors.primary,
                onPrimary: colors.fabIcon,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked.hour);
  }
}

// ── テーマグリッド ────────────────────────────────────────────────────────────

class _ThemeGrid extends StatelessWidget {
  final ThemeState themeState;
  final WidgetRef ref;
  final CamillColors colors;

  const _ThemeGrid({
    required this.themeState,
    required this.ref,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final themes = CamillThemeMode.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   3,
        childAspectRatio: 0.88,
        crossAxisSpacing: 10,
        mainAxisSpacing:  10,
      ),
      itemCount: themes.length,
      itemBuilder: (_, i) => _ThemeCard(
        mode:       themes[i],
        themeState: themeState,
        ref:        ref,
        currentColors: colors,
      ),
    );
  }
}

// ── テーマカード ──────────────────────────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  final CamillThemeMode mode;
  final ThemeState themeState;
  final WidgetRef ref;
  final CamillColors currentColors;

  const _ThemeCard({
    required this.mode,
    required this.themeState,
    required this.ref,
    required this.currentColors,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected  = mode == themeState.selectedBase;
    // カードは現在の日中/夜間に合わせたバリアントで表示
    final cardColors  = CamillColors.fromBase(mode, isDark: themeState.isDarkNow);
    final lightColors = CamillColors.fromBase(mode, isDark: false);
    final darkColors  = CamillColors.fromBase(mode, isDark: true);

    return GestureDetector(
      onTap: () => ref.read(themeProvider.notifier).setBase(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? currentColors.primary
                : currentColors.surfaceBorder,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: currentColors.primary.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            // メインコンテンツ
            Padding(
              padding: EdgeInsets.fromLTRB(
                  8, mode.hasGradient ? 42 : 10, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日中/夜間スウォッチ
                  Row(
                    children: [
                      _Swatch(color: lightColors.primary, size: 9),
                      const SizedBox(width: 3),
                      _Swatch(color: lightColors.background, size: 9,
                          bordered: true, borderColor: lightColors.surfaceBorder),
                      const SizedBox(width: 6),
                      _Swatch(color: darkColors.primary, size: 9),
                      const SizedBox(width: 3),
                      _Swatch(color: darkColors.background, size: 9,
                          bordered: true, borderColor: darkColors.surfaceBorder),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    mode.displayName,
                    style: TextStyle(
                      fontSize:   10,
                      color:      cardColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines:  2,
                    overflow:  TextOverflow.ellipsis,
                  ),
                  if (mode.hasGradient)
                    Text(
                      'グラデ',
                      style: TextStyle(
                        fontSize: 8,
                        color:    cardColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            // 選択チェック
            if (isSelected)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: currentColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check,
                      size: 11, color: currentColors.fabIcon),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 小パーツ ──────────────────────────────────────────────────────────────────

class _Swatch extends StatelessWidget {
  final Color color;
  final double size;
  final bool bordered;
  final Color? borderColor;

  const _Swatch({
    required this.color,
    required this.size,
    this.bordered = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        color:  color,
        shape:  BoxShape.circle,
        border: bordered
            ? Border.all(color: borderColor ?? Colors.grey, width: 0.5)
            : null,
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int hour;
  final CamillColors colors;
  final VoidCallback onTap;

  const _TimeRow({
    required this.icon,
    required this.label,
    required this.hour,
    required this.colors,
    required this.onTap,
  });

  String _fmt(int h) => '${h.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: colors.textSecondary, size: 20),
      title: Text(label,
          style: camillBodyStyle(15, colors.textPrimary)),
      trailing: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color:        colors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _fmt(hour),
            style: camillBodyStyle(14, colors.primary,
                weight: FontWeight.w700),
          ),
        ),
      ),
      onTap: onTap,
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: camillBodyStyle(12, colors.textMuted, weight: FontWeight.w600),
      ),
    );
  }
}
