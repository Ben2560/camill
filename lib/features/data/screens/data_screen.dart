import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import 'package:intl/intl.dart';
import '../../community/screens/community_screen.dart';
import '../widgets/data_chart_widgets.dart';

class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommunityScreen();
  }
}

// ── 収支グラフ専用スクリーン ─────────────────────────────────────────────────

class BalanceChartScreen extends StatefulWidget {
  const BalanceChartScreen({super.key});

  @override
  State<BalanceChartScreen> createState() => _BalanceChartScreenState();
}

class _BalanceChartScreenState extends State<BalanceChartScreen>
    with SingleTickerProviderStateMixin {
  final _dismissOffset = ValueNotifier<double>(0);
  late final AnimationController _snapController;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dismissOffset.addListener(_onOffsetChanged);
  }

  void _onOffsetChanged() {
    if (!mounted || _isDismissing) return;
    final limit = MediaQuery.of(context).size.height * 0.19;
    if (_dismissOffset.value >= limit) {
      _isDismissing = true;
      _dismissOffset.removeListener(_onOffsetChanged);
      _beginDismiss();
    }
  }

  @override
  void dispose() {
    _dismissOffset.removeListener(_onOffsetChanged);
    _dismissOffset.dispose();
    _snapController.dispose();
    super.dispose();
  }

  void endDismiss() {
    if (_isDismissing) return;
    final sh = MediaQuery.of(context).size.height;
    if (_dismissOffset.value > sh * 0.20) {
      _isDismissing = true;
      _beginDismiss();
    } else {
      _snapBack();
    }
  }

  void _beginDismiss() {
    _snapController.duration = const Duration(milliseconds: 200);
    _snapController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) Navigator.of(context, rootNavigator: false).pop();
    });
  }

  void _snapBack() {
    final start = _dismissOffset.value;
    _snapController.reset();
    final anim = Tween<double>(begin: start, end: 0).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    anim.addListener(() => _dismissOffset.value = anim.value);
    _snapController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currencyFmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    final sh = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: Listenable.merge([_dismissOffset, _snapController]),
      builder: (ctx, child) {
        final progress = (_dismissOffset.value / (sh * 0.20)).clamp(0.0, 1.0);
        final blur = _isDismissing ? _snapController.value * 12.0 : 0.0;
        Widget content = child!;
        if (blur > 0.1) {
          content = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: content,
          );
        }
        return Stack(
          children: [
            Container(color: colors.background),
            Container(color: Colors.black.withValues(alpha: 0.28 * progress)),
            Transform.translate(
              offset: Offset(0, _dismissOffset.value),
              child: Transform.scale(
                scale: 1.0 - progress * 0.07,
                alignment: Alignment.topCenter,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(progress * 22.0),
                  ),
                  child: content,
                ),
              ),
            ),
          ],
        );
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          scrolledUnderElevation: 0,
          title: Text(
            '収支グラフ',
            style: camillHeadingStyle(17, colors.textPrimary),
          ),
          iconTheme: IconThemeData(color: colors.textSecondary),
          elevation: 0,
        ),
        body: ChartTab(
          currencyFmt: currencyFmt,
          dismissOffset: _dismissOffset,
          onDismissEnd: endDismiss,
          isDismissing: () => _isDismissing,
        ),
      ),
    );
  }
}

