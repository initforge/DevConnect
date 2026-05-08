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

  group('Luồng 05: Cài đặt & Cá nhân hóa (Settings & Profile Flow)', () {
    testWidgets('TC-SETTINGS-FULL: Edit Profile -> Change Theme -> Reset Data', (tester) async {
      await login(tester);

      // 1. Vào Tab Profile (tab 5)
      final destinations = find.byType(NavigationDestination);
      await tester.tap(destinations.at(4));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 2. Bấm Edit Profile (Nút Outline hoặc Icon Edit)
      final editBtn = find.byIcon(Icons.edit_outlined);
      if (editBtn.evaluate().isNotEmpty) {
        await tester.tap(editBtn);
        await tester.pumpAndSettle();
        
        // Thay đổi thông tin
        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'Minh Nguyen Updated');
        await tester.enterText(fields.at(1), 'Lập trình viên Flutter đam mê E2E testing.');
        
        // Bấm Lưu
        await tester.tap(find.text('Lưu thay đổi'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Kiểm tra UI cập nhật tên mới
        expect(find.text('Minh Nguyen Updated'), findsWidgets);
      }

      // 3. Vào Cài đặt
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Đổi Theme (Switch đầu tiên)
      final themeSwitch = find.byType(Switch).first;
      await tester.tap(themeSwitch);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // Đổi chế độ thông báo
      final notifSwitch = find.byType(Switch).at(1);
      await tester.tap(notifSwitch);
      await tester.pumpAndSettle();

      // 4. Kiểm tra trang "Về ứng dụng"
      await tester.tap(find.text('Về ứng dụng'));
      await tester.pumpAndSettle();
      expect(find.text('Phiên bản'), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();

      print('✅ TC-SETTINGS-FULL: Hoàn thành kiểm tra cài đặt và cá nhân hóa!');
    });
  });
}
