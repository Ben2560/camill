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
          // ── 日中 / 夜間 ───────────────────────────────────────────
          _SectionHeader(title: '日中 / 夜間', colors: colors),
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
                  // 自動切替トグル
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 18, color: colors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('日の出 / 日の入りで自動切替',
                              style: camillBodyStyle(
                                  14, colors.textPrimary,
                                  weight: FontWeight.w500)),
                        ),
                        Switch(
                          value: themeState.autoSwitch,
                          activeThumbColor: colors.primary,
                          onChanged: (v) =>
                              ref.read(themeProvider.notifier).setAutoSwitch(v),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colors.surfaceBorder),
                  // 手動トグル (自動OFF時のみ有効)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            themeState.isDarkNow
                                ? Icons.nightlight_round
                                : Icons.wb_sunny_rounded,
                            key: ValueKey(themeState.isDarkNow),
                            size: 18,
                            color: themeState.autoSwitch
                                ? colors.textMuted
                                : colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            themeState.isDarkNow ? '夜間モード' : '日中モード',
                            style: camillBodyStyle(
                              14,
                              themeState.autoSwitch
                                  ? colors.textMuted
                                  : colors.textPrimary,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch(
                          value: themeState.isDarkNow,
                          activeThumbColor: colors.primary,
                          onChanged: themeState.autoSwitch
                              ? null
                              : (v) => ref
                                  .read(themeProvider.notifier)
                                  .setDarkNow(v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── テーマ選択グリッド ────────────────────────────────────
          _SectionHeader(title: 'テーマ', colors: colors),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ThemeGrid(themeState: themeState, ref: ref, colors: colors),
          ),
        ],
      ),
    );
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
        childAspectRatio: 0.82,
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
        clipBehavior: Clip.antiAlias,
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
            // カラーヘッダー帯
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: mode.hasGradient
                      ? LinearGradient(
                          colors: [lightColors.primary, lightColors.accent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : LinearGradient(
                          colors: [
                            lightColors.primary,
                            lightColors.primary.withAlpha(180),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                ),
              ),
            ),
            // メインコンテンツ
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 48, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日中/夜間スウォッチ
                  Row(
                    children: [
                      _Swatch(color: lightColors.primary, size: 10),
                      const SizedBox(width: 3),
                      _Swatch(color: lightColors.background, size: 10,
                          bordered: true, borderColor: lightColors.surfaceBorder),
                      const SizedBox(width: 5),
                      _Swatch(color: darkColors.primary, size: 10),
                      const SizedBox(width: 3),
                      _Swatch(color: darkColors.background, size: 10,
                          bordered: true, borderColor: darkColors.surfaceBorder),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    mode.displayName,
                    style: TextStyle(
                      fontSize:   11,
                      color:      cardColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines:  2,
                    overflow:  TextOverflow.ellipsis,
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
