import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:camill/core/theme/camill_colors.dart';
import 'package:camill/features/home/widgets/tax_breakdown_row.dart';

void main() {
  final colors = CamillColors.naturalLight;
  final fmt = NumberFormat('#,###');

  Widget buildSubject({required String label, required int amount}) {
    return MaterialApp(
      theme: ThemeData(extensions: [colors]),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TaxBreakdownRow(
            label: label,
            amount: amount,
            colors: colors,
            fmt: fmt,
          ),
        ),
      ),
    );
  }

  testWidgets('ラベルと金額が表示される', (tester) async {
    await tester.pumpWidget(buildSubject(label: '8%対象', amount: 1080));
    expect(find.text('8%対象'), findsOneWidget);
    expect(find.text('1,080'), findsOneWidget);
  });

  testWidgets('金額 0 も表示される', (tester) async {
    await tester.pumpWidget(buildSubject(label: '軽減税率', amount: 0));
    expect(find.text('軽減税率'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('ドットインジケーターが描画される', (tester) async {
    await tester.pumpWidget(buildSubject(label: '10%対象', amount: 500));
    // Container × ドット + Padding + Row が 1 つあること
    expect(find.byType(Row), findsWidgets);
  });
}
