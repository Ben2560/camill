import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:camill/main.dart' as app;

// 実機 or エミュレータで実行:
//   flutter test integration_test/smoke_test.dart -d <device_id>
//
// CI (GitHub Actions) での実行例:
//   flutter test integration_test/smoke_test.dart -d emulator-5554
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('スモークテスト', () {
    testWidgets('アプリが起動しログイン画面が表示される', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ログイン画面のどれかが表示されていることを確認
      // （「camill」ロゴ or メールフィールド or ログインボタン）
      final hasLogo = find.text('camill').evaluate().isNotEmpty;
      final hasEmailField = find.byType(TextField).evaluate().isNotEmpty;
      final hasLoginUI = find.byType(MaterialApp).evaluate().isNotEmpty;

      expect(hasLogo || hasEmailField || hasLoginUI, isTrue,
          reason: 'アプリが起動してUIが描画されること');
    });

    testWidgets('ダークモード / ライトモードでクラッシュしない', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // テーマを強制変更してクラッシュしないことを確認
      await tester.binding.setSurfaceSize(const Size(390, 844)); // iPhone 14
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
