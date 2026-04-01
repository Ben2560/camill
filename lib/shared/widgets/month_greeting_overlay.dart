import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camill/core/theme/camill_theme.dart';

// 月ごとのカラー（グラデーション）
const _monthColors = {
  1:  [Color(0xFF90CAF9), Color(0xFFB3E5FC)], // 冬の空・氷
  2:  [Color(0xFFF48FB1), Color(0xFFFF80AB)], // バレンタイン・梅
  3:  [Color(0xFFF8BBD0), Color(0xFFCE93D8)], // 桜・春霞
  4:  [Color(0xFFA5D6A7), Color(0xFF80DEEA)], // 新緑・春
  5:  [Color(0xFF66BB6A), Color(0xFFAED581)], // 深緑・こどもの日
  6:  [Color(0xFF9575CD), Color(0xFF7986CB)], // 紫陽花・梅雨
  7:  [Color(0xFF29B6F6), Color(0xFF26C6DA)], // 夏空・海
  8:  [Color(0xFFFF7043), Color(0xFFFFCA28)], // 夏・ひまわり
  9:  [Color(0xFFEF9A9A), Color(0xFFFFCC80)], // 秋の始まり・コスモス
  10: [Color(0xFFFF8A65), Color(0xFFFFB74D)], // 紅葉・秋
  11: [Color(0xFF8D6E63), Color(0xFFBCAAA4)], // 晩秋・枯れ葉
  12: [Color(0xFF42A5F5), Color(0xFF7E57C2)], // 冬夜・クリスマス
};

// 月ごとのメッセージ（1-12月）
const _monthMessages = {
  1:  ('1月が始まりました', '新しい年のスタート。\n今年の家計を一緒に整えましょう。'),
  2:  ('2月が始まりました', '寒い季節こそ、\n家でじっくり家計を見直すチャンス。'),
  3:  ('3月が始まりました', '年度末。\n今月の支出、少し意識してみませんか？'),
  4:  ('4月が始まりました', '新しいスタートの季節。\n気持ちも家計もリフレッシュを。'),
  5:  ('5月が始まりました', 'ゴールデンウィーク、\n楽しみながらも出費に気をつけて。'),
  6:  ('6月が始まりました', '梅雨の季節。\n おうち時間を上手に使いましょう。'),
  7:  ('7月が始まりました', '夏本番。\n暑さに負けず、家計も涼しく保とう。'),
  8:  ('8月が始まりました', '夏の出費が増える季節。\nレシートをこまめに記録しよう。'),
  9:  ('9月が始まりました', '少しずつ涼しくなる頃。\n秋の支出を先読みしておこう。'),
  10: ('10月が始まりました', '実りの秋。\n食費が上がりやすい季節、要注意です。'),
  11: ('11月が始まりました', '年末が近づいてきました。\n今のうちに家計を整えておこう。'),
  12: ('12月が始まりました', '一年の締めくくり。\n来年のためにも、今月の出費を丁寧に。'),
};

class MonthGreetingOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  final int month;

  const MonthGreetingOverlay({
    super.key,
    required this.onDismiss,
    required this.month,
  });

  @override
  State<MonthGreetingOverlay> createState() => _MonthGreetingOverlayState();
}

class _MonthGreetingOverlayState extends State<MonthGreetingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final msg = _monthMessages[widget.month] ?? _monthMessages[1]!;

    return FadeTransition(
      opacity: _fadeIn,
      child: GestureDetector(
        onTap: _dismiss,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 暗いブラーオーバーレイ
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                color: Colors.black.withAlpha(160),
              ),
            ),
            // テキストコンテンツ（縦中央）
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 月のバッジ
                    Builder(builder: (context) {
                      final cols = _monthColors[widget.month] ?? _monthColors[1]!;
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: cols,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cols[0].withAlpha(120),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${widget.month}月',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 28),
                    // タイトル
                    Text(
                      msg.$1,
                      style: camillBodyStyle(
                        24,
                        Colors.white,
                        weight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // サブメッセージ
                    Text(
                      msg.$2,
                      style: camillBodyStyle(15, Colors.white.withAlpha(220), weight: FontWeight.w600)
                          .copyWith(height: 1.7),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            // タップ促進（画面下部に固定）
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Text(
                'タップして始める',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withAlpha(210),
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
