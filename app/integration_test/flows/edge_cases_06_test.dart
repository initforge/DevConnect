import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:devconnect/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Luồng 06: Các trường hợp ngoại lệ (Edge Cases)', () {
    testWidgets('TC-EDGE-01: Kiểm tra độ mạnh yếu của mật khẩu trong UI', (
      tester,
    ) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Đi tới trang đăng ký
      await tester.tap(find.text('Đăng ký ngay'));
      await tester.pumpAndSettle();

      // Điền thông tin step 1
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Edge Tester');
      await tester.enterText(fields.at(1), 'edgetester');
      await tester.enterText(fields.at(2), 'edge@test.com');
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      // Kiểm tra mật khẩu YẾU (chỉ chữ thường)
      final pwField = find.byType(TextFormField);
      await tester.enterText(pwField, 'weak');
      await tester.pumpAndSettle();
      expect(find.text('Yếu'), findsOneWidget);

      // Kiểm tra mật khẩu TRUNG BÌNH (đủ 8 ký tự)
      await tester.enterText(pwField, 'weakpassword');
      await tester.pumpAndSettle();
      expect(find.text('Trung bình'), findsOneWidget);

      // Kiểm tra mật khẩu RẤT MẠNH (Hoa, Số, Đặc biệt, >8 ký tự)
      await tester.enterText(pwField, 'Str0ng!Pass');
      await tester.pumpAndSettle();
      expect(find.text('Rất mạnh'), findsOneWidget);
    });

    testWidgets('TC-EDGE-02: Lỗi định dạng Email và bỏ trống trường', (
      tester,
    ) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Thử đăng nhập với email sai định dạng
      final loginFields = find.byType(TextFormField);
      await tester.enterText(loginFields.at(0), 'not-an-email');
      await tester.enterText(loginFields.at(1), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.text('Email không hợp lệ'), findsOneWidget);

      // Thử để trống mật khẩu
      await tester.enterText(loginFields.at(0), 'test@test.com');
      await tester.enterText(loginFields.at(1), '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });
  });
}
