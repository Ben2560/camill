import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/receipt_model.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../widgets/receipt_form_page.dart';

// ── 外側ウィジェット ────────────────────────────────────────────
class AnalysisPreviewScreen extends StatefulWidget {
  final List<ReceiptAnalysis> analyses;
  final int maxReceipts;

  const AnalysisPreviewScreen({
    super.key,
    required this.analyses,
    required this.maxReceipts,
  });

  @override
  State<AnalysisPreviewScreen> createState() => _AnalysisPreviewScreenState();
}

class _AnalysisPreviewScreenState extends State<AnalysisPreviewScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _saving = false;
  late final List<GlobalKey<ReceiptFormPageState>> _pageKeys;

  List<ReceiptAnalysis> get _visibleAnalyses =>
      widget.analyses.take(widget.maxReceipts).toList();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageKeys = List.generate(
      _visibleAnalyses.length,
      (_) => GlobalKey<ReceiptFormPageState>(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    for (int i = 0; i < _pageKeys.length; i++) {
      // 未訪問ページは state が null のため、jumpToPage で強制ビルドしてから1フレーム待つ
      if (_pageKeys[i].currentState == null) {
        _pageController.jumpToPage(i);
        await WidgetsBinding.instance.endOfFrame;
      }
      final success = await _pageKeys[i].currentState!.performSave();
      if (!success) {
        setState(() => _saving = false);
        return;
      }
    }
    if (mounted) {
      if (_visibleAnalyses.any((a) => a.isBill)) {
        CalendarScreen.billRefreshSignal.value++;
      }
      CalendarScreen.receiptRefreshSignal.value++;
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = _visibleAnalyses.length;
    final showBanner = widget.analyses.length > widget.maxReceipts;

    return Stack(
      children: [
        // 背景ブラー
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: colors.background.withValues(alpha: 0.85),
          ),
        ),
        Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          count > 1
              ? '解析結果 ${_currentPage + 1} / $count'
              : '解析結果の確認',
          style: camillHeadingStyle(17, colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textSecondary),
      ),
      body: Column(
        children: [
          if (showBanner)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: colors.primaryLight,
              child: Text(
                '有料会員になると1枚の写真から最大5件まで登録できます',
                style: camillBodyStyle(13, colors.primary),
                textAlign: TextAlign.center,
              ),
            ),
          if (count > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(count, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? colors.primary : colors.surfaceBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                for (int i = 0; i < count; i++)
                  ReceiptFormPage(
                    key: _pageKeys[i],
                    analysis: _visibleAnalyses[i],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saving ? null : _saveAll,
                icon: _saving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.fabIcon,
                        ),
                      )
                    : Icon(Icons.save_outlined, color: colors.fabIcon),
                label: Text(
                  count > 1
                      ? '全$count件を登録'
                      : (_visibleAnalyses.first.isBill
                          ? 'この請求書を登録'
                          : 'このレシートを登録'),
                  style: camillBodyStyle(16, colors.fabIcon),
                ),
              ),
            ),
          ),
        ],
      ),
        ),
      ],
    );
  }
}

