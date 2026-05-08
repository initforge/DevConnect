import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:devconnect/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const testEmail = 'minh@dev.com';
  const testPassword = 'password123';

  group('Luồng 01: Xác thực & Tài khoản (Auth Flow)', () {
    testWidgets('TC-AUTH-FULL: Luồng từ Login -> Register -> Login -> Logout', (tester) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 1. Kiểm tra validation khi để trống
      final loginBtn = find.widgetWithText(ElevatedButton, 'Đăng nhập');
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập email'), findsOneWidget);

      // 2. Chuyển sang trang Đăng ký
      final registerLink = find.text('Đăng ký ngay');
      await tester.tap(registerLink);
      await tester.pumpAndSettle();
      expect(find.text('Tạo tài khoản'), findsOneWidget);

      // 3. Đăng ký Step 1 (Validation email)
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'E2E User');
      await tester.enterText(fields.at(1), 'e2e_user_${DateTime.now().millisecondsSinceEpoch}');
      await tester.enterText(fields.at(2), 'invalid-email');
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Email không hợp lệ'), findsOneWidget);

      // 4. Quay lại Đăng nhập
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // 5. Đăng nhập thành công
      final loginFields = find.byType(TextFormField);
      await tester.enterText(loginFields.at(0), testEmail);
      await tester.enterText(loginFields.at(1), testPassword);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 6. Xử lý Onboarding (Bỏ qua)
      final skipBtn = find.text('Bỏ qua');
      if (skipBtn.evaluate().isNotEmpty) {
        await tester.tap(skipBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // 7. Xác nhận đã vào Home (có NavigationBar)
      expect(find.byType(NavigationBar), findsOneWidget);

      // 8. Luồng Đăng xuất (Vào Profile -> Settings -> Logout)
      // Chuyển sang tab Profile (tab thứ 5)
      final destinations = find.byType(NavigationDestination);
      await tester.tap(destinations.at(4));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Bấm icon Settings
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      await tester.tap(settingsIcon);
      await tester.pumpAndSettle();

      // Bấm Đăng xuất
      final logoutBtn = find.text('Đăng xuất');
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Quay về màn hình Login
      expect(find.text('Đăng nhập'), findsWidgets);
      print('✅ TC-AUTH-FULL: Hoàn thành luồng xác thực thành công!');
    });
  });
}
