import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camill/core/theme/camill_colors.dart';
import 'package:camill/shared/widgets/camill_card.dart';

void main() {
  final colors = CamillColors.naturalLight;

  Widget wrap(Widget child) => MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(body: child),
      );

  testWidgets('child が描画される', (tester) async {
    await tester.pumpWidget(wrap(
      CamillCard(child: const Text('テスト')),
    ));
    expect(find.text('テスト'), findsOneWidget);
  });

  testWidgets('onTap が呼ばれる', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(
      CamillCard(
        onTap: () => tapped = true,
        child: const Text('タップ'),
      ),
    ));
    await tester.tap(find.byType(CamillCard));
    expect(tapped, isTrue);
  });

  testWidgets('onTap なしでもクラッシュしない', (tester) async {
    await tester.pumpWidget(wrap(
      CamillCard(child: const Text('no tap')),
    ));
    await tester.tap(find.byType(CamillCard));
    await tester.pump();
  });

  testWidgets('カスタム padding が適用される', (tester) async {
    await tester.pumpWidget(wrap(
      CamillCard(
        padding: const EdgeInsets.all(32),
        child: const Text('padded'),
      ),
    ));
    expect(find.text('padded'), findsOneWidget);
  });
}
