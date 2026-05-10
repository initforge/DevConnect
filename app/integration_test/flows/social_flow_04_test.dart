import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:devconnect/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> login(WidgetTester tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));
    final fields = find.byType(TextFormField);
    if (fields.evaluate().isNotEmpty) {
      await tester.enterText(fields.at(0), 'minh@dev.com');
      await tester.enterText(fields.at(1), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      final skipBtn = find.text('Bỏ qua');
      if (skipBtn.evaluate().isNotEmpty) {
        await tester.tap(skipBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    }
  }

  group('Luồng 04: Xã hội & Kết nối (Social Flow)', () {
    testWidgets('TC-SOCIAL-FULL: Chat -> Notification -> Follow User', (
      tester,
    ) async {
      await login(tester);

      // 1. Vào Tab Chat (tab 3)
      final destinations = find.byType(NavigationDestination);
      await tester.tap(destinations.at(2));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Mở một hội thoại
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Gửi tin nhắn
      await tester.enterText(
        find.byType(TextField),
        'Test tin nhắn thời gian thực!',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.pageBack();
      await tester.pumpAndSettle();

      // 2. Vào Tab Thông báo (tab 4)
      await tester.tap(destinations.at(3));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Thông báo'), findsWidgets);

      // Bấm "Đọc hết"
      final readAll = find.text('Đọc hết');
      if (readAll.evaluate().isNotEmpty) {
        await tester.tap(readAll);
        await tester.pumpAndSettle();
      }

      // 3. Vào Profile người khác để Follow
      await tester.tap(destinations.at(0)); // Về feed
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Click avatar tác giả bài viết
      await tester.tap(find.byType(CircleAvatar).at(1));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Bấm Theo dõi
      final followBtn = find.text('Theo dõi');
      if (followBtn.evaluate().isNotEmpty) {
        await tester.tap(followBtn);
        await tester.pumpAndSettle();
      }

      debugPrint('✅ TC-SOCIAL-FULL: Hoàn thành luồng kết nối xã hội!');
    });
  });
}
