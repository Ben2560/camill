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

  testWidgets('レシートの時刻が 00:00 以外のとき HH:mm が表示される', (tester) async {
    final receipt = RecentReceipt(
      receiptId: 'r1',
      storeName: 'コンビニ',
      totalAmount: 300,
      purchasedAt: '2026-04-21T14:30:00',
    );
    await tester.pumpWidget(buildSubject(receipts: [receipt]));
    await tester.pump();
    expect(find.textContaining('14:30'), findsOneWidget);
  });

  testWidgets('クーポンがあるときクーポン説明とヘッダーが表示される', (tester) async {
    final coupon = Coupon(
      couponId: 'c1',
      storeName: 'イオン',
      description: '春のポイントアップ',
      discountAmount: 100,
      isUsed: false,
      isFromOcr: false,
      createdAt: DateTime(2026, 4, 1),
    );
    await tester.pumpWidget(buildSubject(coupons: [coupon]));
    expect(find.text('春のポイントアップ'), findsOneWidget);
    expect(find.textContaining('クーポン'), findsWidgets);
  });

  testWidgets('discountAmount=0 のクーポンは「無料」と表示される', (tester) async {
    final coupon = Coupon(
      couponId: 'c2',
      storeName: 'スタバ',
      description: '無料ドリンク',
      discountAmount: 0,
      isUsed: false,
      isFromOcr: false,
      createdAt: DateTime(2026, 4, 1),
    );
    await tester.pumpWidget(buildSubject(coupons: [coupon]));
    expect(find.text('無料'), findsOneWidget);
  });

  testWidgets('クーポンに validUntil があるとき期限が表示される', (tester) async {
    final coupon = Coupon(
      couponId: 'c3',
      storeName: 'マック',
      description: '半額',
      discountAmount: 200,
      isUsed: false,
      isFromOcr: false,
      createdAt: DateTime(2026, 4, 1),
      validUntil: DateTime(2026, 4, 30),
    );
    await tester.pumpWidget(buildSubject(coupons: [coupon]));
    expect(find.textContaining('4/30'), findsOneWidget);
  });

  testWidgets('請求書があるとき請求書タイトルが表示される', (tester) async {
    final bill = Bill(
      billId: 'b1',
      title: '電気代',
      amount: 5000,
      status: BillStatus.unpaid,
      createdAt: DateTime(2026, 4, 1),
    );
    await tester.pumpWidget(buildSubject(bills: [bill]));
    expect(find.text('電気代'), findsOneWidget);
    expect(find.text('支払期限の請求書'), findsOneWidget);
  });

  testWidgets('レシートタップで onTapReceipt が呼ばれる', (tester) async {
    RecentReceipt? tapped;
    final receipt = RecentReceipt(
      receiptId: 'r1',
      storeName: 'タップ店',
      totalAmount: 1000,
      purchasedAt: '2026-04-21T00:00:00',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: CalendarDayPanel(
            day: day,
            receipts: [receipt],
            activeCoupons: const [],
            dueBills: const [],
            loading: false,
            fmt: fmt,
            colors: colors,
            onTapReceipt: (r) => tapped = r,
            onTapCoupon: (_) {},
            onTapBill: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('タップ店'));
    expect(tapped?.receiptId, 'r1');
  });

  testWidgets('クーポンタップで onTapCoupon が呼ばれる', (tester) async {
    Coupon? tapped;
    final coupon = Coupon(
      couponId: 'c1',
      storeName: 'クーポン店',
      description: '夏の特別セール',
      discountAmount: 50,
      isUsed: false,
      isFromOcr: false,
      createdAt: DateTime(2026, 4, 1),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: CalendarDayPanel(
            day: day,
            receipts: const [],
            activeCoupons: [coupon],
            dueBills: const [],
            loading: false,
            fmt: fmt,
            colors: colors,
            onTapReceipt: (_) {},
            onTapCoupon: (c) => tapped = c,
            onTapBill: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('夏の特別セール'));
    expect(tapped?.couponId, 'c1');
  });

  testWidgets('請求書タップで onTapBill が呼ばれる', (tester) async {
    Bill? tapped;
    final bill = Bill(
      billId: 'b1',
      title: 'ガス代',
      amount: 3000,
      status: BillStatus.unpaid,
      createdAt: DateTime(2026, 4, 1),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: CalendarDayPanel(
            day: day,
            receipts: const [],
            activeCoupons: const [],
            dueBills: [bill],
            loading: false,
            fmt: fmt,
            colors: colors,
            onTapReceipt: (_) {},
            onTapCoupon: (_) {},
            onTapBill: (b) => tapped = b,
          ),
        ),
      ),
    );
    await tester.tap(find.text('ガス代'));
    expect(tapped?.billId, 'b1');
  });
}
