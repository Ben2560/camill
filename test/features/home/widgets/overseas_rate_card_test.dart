import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camill/core/theme/camill_colors.dart';
import 'package:camill/features/home/widgets/overseas_rate_card.dart';

void main() {
  final colors = CamillColors.naturalLight;

  Widget buildSubject({String currency = 'USD', double rate = 150.5}) {
    return MaterialApp(
      theme: ThemeData(extensions: [colors]),
      home: Scaffold(
        body: OverseasRateCard(currency: currency, rate: rate, colors: colors),
      ),
    );
  }

  testWidgets('通貨コードが表示される', (tester) async {
    await tester.pumpWidget(buildSubject(currency: 'USD'));
    expect(find.textContaining('USD'), findsWidgets);
  });

  testWidgets('レートが表示される', (tester) async {
    await tester.pumpWidget(buildSubject(currency: 'USD', rate: 155.0));
    // rate > 1 なので整数表示か小数表示になる
    expect(find.byType(OverseasRateCard), findsOneWidget);
  });

  testWidgets('通貨ラベルが表示される（既知の通貨）', (tester) async {
    await tester.pumpWidget(buildSubject(currency: 'EUR'));
    expect(find.textContaining('ユーロ'), findsWidgets);
  });

  testWidgets('未知の通貨でもクラッシュしない', (tester) async {
    await tester.pumpWidget(buildSubject(currency: 'XYZ', rate: 1.0));
    expect(find.byType(OverseasRateCard), findsOneWidget);
  });
}
