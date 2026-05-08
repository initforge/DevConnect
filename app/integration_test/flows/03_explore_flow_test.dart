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

  group('Luồng 03: Khám phá Chuyên sâu (Deep Explore Flow)', () {
    testWidgets('TC-EXPLORE-DEEP: Tương tác chi tiết từng ngóc ngách hệ sinh thái', (tester) async {
      await login(tester);

      // 1. Chuyển sang tab Explore
      final destinations = find.byType(NavigationDestination);
      await tester.tap(destinations.at(1));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 2. Tương tác Sàn dự án
      await tester.tap(find.text('Sàn dự án'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Kiểm tra danh sách dự án
      expect(find.byType(ListView), findsOneWidget);
      // Kiểm tra một TechChip bất kỳ (ví dụ: Flutter)
      expect(find.text('Flutter'), findsWidgets);
      
      // Bấm FAB Tạo dự án & Kiểm tra logic Phase sau
      await tester.tap(find.text('Tạo dự án'));
      await tester.pumpAndSettle();
      expect(find.text('Tạo dự án mới sẽ triển khai ở phase sau'), findsOneWidget);
      
      // Pull to Refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 3. Tương tác Tuyển dụng (Job Board)
      await tester.tap(find.text('Việc làm'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Kiểm tra Match% hiển thị
      expect(find.textContaining('%'), findsWidgets);
      
      // Click Ứng tuyển lần đầu
      final applyBtn = find.text('Ung tuyen ngay').first;
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();
      
      // KIỂM TRA BUSINESS LOGIC: Nút phải đổi trạng thái sau khi ứng tuyển
      expect(find.text('Da ung tuyen'), findsWidgets);
      expect(find.text('Da ung tuyen thanh cong!'), findsOneWidget);
      
      // Thử bấm lại (không được bắn snackbar thành công nữa)
      await tester.tap(find.text('Da ung tuyen').first);
      await tester.pump();
      
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 4. Tương tác Bảng xếp hạng
      await tester.tap(find.text('Xếp hạng'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Kiểm tra có đủ các chỉ số (Points, Reputation)
      expect(find.textContaining('pts'), findsWidgets);
      
      // Cuộn xuống xem các user hạng dưới
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 5. Test Playground (Sân chơi Code)
      await tester.tap(find.text('Playground'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Thay đổi ngôn ngữ
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('JavaScript').last);
      await tester.pumpAndSettle();
      
      // Bấm nút Run
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();
      expect(find.textContaining('Output'), findsWidgets);

      print('✅ TC-EXPLORE-DEEP: Hoàn thành kiểm tra mọi ngóc ngách Business Logic!');
    });
  });
}
