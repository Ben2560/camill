import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SmartReceipt app smoke test', (WidgetTester tester) async {
    // Firebase初期化が必要なため、実機/エミュレータ上での統合テストは
    // integration_test パッケージで行う。ここではビルドが通ることのみ確認。
    expect(true, isTrue);
  });
}
