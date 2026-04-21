import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:camill/core/theme/camill_colors.dart';
import 'package:camill/features/calendar/widgets/calendar_day_panel.dart';
import 'package:camill/shared/models/bill_model.dart';
import 'package:camill/shared/models/coupon_model.dart';
import 'package:camill/shared/models/summary_model.dart';

void main() {
  final colors = CamillColors.naturalLight;
  final fmt = NumberFormat('#,###');
  final day = DateTime(2026, 4, 21);

  Widget buildSubject({
    List<RecentReceipt> receipts = const [],
    List<Coupon> coupons = const [],
    List<Bill> bills = const [],
    bool loading = false,
  }) {
    return MaterialApp(
      theme: ThemeData(extensions: [colors]),
      home: Scaffold(
        body: CalendarDayPanel(
          day: day,
          receipts: receipts,
          activeCoupons: coupons,
          dueBills: bills,
          loading: loading,
          fmt: fmt,
          colors: colors,
          onTapReceipt: (_) {},
          onTapCoupon: (_) {},
          onTapBill: (_) {},
        ),
      ),
    );
  }

  testWidgets('空のとき「この日の記録はありません」と表示される', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('この日の記録はありません'), findsOneWidget);
  });

  testWidgets('日付バッジに日付が表示される', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('21'), findsOneWidget);
  });

  testWidgets('ローディング中はインジケーターが表示される', (tester) async {
    await tester.pumpWidget(buildSubject(loading: true));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('レシートがあるとき店舗名が表示される', (tester) async {
    final receipt = RecentReceipt(
      receiptId: 'r1',
      storeName: 'テストスーパー',
      totalAmount: 1200,
      purchasedAt: '2026-04-21T00:00:00',
    );
    await tester.pumpWidget(buildSubject(receipts: [receipt]));
    expect(find.text('テストスーパー'), findsOneWidget);
  });

  testWidgets('合計金額が表示される（複数レシート）', (tester) async {
    final receipts = [
      RecentReceipt(
        receiptId: 'r1',
        storeName: '店A',
        totalAmount: 500,
        purchasedAt: '2026-04-21T00:00:00',
      ),
      RecentReceipt(
        receiptId: 'r2',
        storeName: '店B',
        totalAmount: 300,
        purchasedAt: '2026-04-21T00:00:00',
      ),
    ];
    await tester.pumpWidget(buildSubject(receipts: receipts));
    expect(find.text('800'), findsOneWidget);
  });
}
