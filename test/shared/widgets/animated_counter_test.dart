import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camill/shared/widgets/animated_counter.dart';

void main() {
  testWidgets('初期値 0 でテキストが描画される', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedCounter(
            targetValue: 0,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
    expect(find.byType(AnimatedCounter), findsOneWidget);
  });

  testWidgets('targetValue を設定してウィジェットが構築される', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedCounter(
            targetValue: 1500,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
    expect(find.byType(AnimatedCounter), findsOneWidget);
  });

  testWidgets('pumpAndSettle でアニメーション完了後にテキストが表示される', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedCounter(
            targetValue: 100,
            duration: const Duration(milliseconds: 100),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('100'), findsOneWidget);
  });
}
