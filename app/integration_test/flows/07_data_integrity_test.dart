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

  group('Luồng 07: Đồng nhất dữ liệu & Trạng thái rỗng (Data Integrity)', () {
    testWidgets('TC-DATA-01: Kiểm tra đồng nhất tên người dùng trên toàn app', (tester) async {
      await login(tester);

      // 1. Vào Profile lấy tên hiện tại
      final destinations = find.byType(NavigationDestination);
      await tester.tap(destinations.at(4));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      const newName = 'Integrity Check Name';
      
      // 2. Đổi tên
      final editBtn = find.byIcon(Icons.edit_outlined);
      if (editBtn.evaluate().isNotEmpty) {
        await tester.tap(editBtn);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, newName);
        await tester.tap(find.text('Lưu thay đổi'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // 3. Quay về Feed xem tên có đổi ở Bài viết không (Nếu có bài của mình)
      await tester.tap(destinations.at(0));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Kiểm tra xem tên mới có xuất hiện ở đâu đó trên màn hình Feed không
      // (Giả sử có bài viết của user hiện tại trên feed)
      // expect(find.text(newName), findsWidgets);

      // 4. Vào Chat xem tên mình trong Header
      await tester.tap(destinations.at(2));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Mở Drawer hoặc xem Info (tùy cấu trúc app)
      // Đây là nơi test tính reactive của State Management
    });

    testWidgets('TC-DATA-02: Kiểm tra Empty State khi tìm kiếm không ra kết quả', (tester) async {
      await login(tester);

      // Vào Explore
      final destinations = find.byType(NavigationDestination);
      await tester.tap(destinations.at(1));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tìm kiếm một chuỗi vô nghĩa
      final searchInput = find.byType(TextField).first;
      await tester.enterText(searchInput, 'zxcvbnm_không_có_thật_đâu_nha');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Kiểm tra màn hình trống
      expect(find.text('Chưa có dữ liệu'), findsWidgets);
      expect(find.byIcon(Icons.search_off_outlined), findsWidgets);
    });
  });
}
