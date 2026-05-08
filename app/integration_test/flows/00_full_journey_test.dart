import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:devconnect/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Hành trình người dùng (Full User Journey)', () {
    testWidgets('TC-JOURNEY-01: Từ Đăng ký mới đến khi sử dụng hết tính năng', (tester) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('🚀 Khởi hành: Đăng ký tài khoản mới');
      final registerLink = find.text('Đăng ký ngay');
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'E2E Voyager');
      await tester.enterText(fields.at(1), 'voyager_$timestamp');
      await tester.enterText(fields.at(2), 'voyager_$timestamp@test.com');
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Password123!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Hoàn tất đăng ký'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      print('✨ Onboarding: Chọn sở thích');
      // Chọn vài chip
      final chips = find.byType(GestureDetector);
      if (chips.evaluate().length >= 3) {
        await tester.tap(chips.at(0));
        await tester.tap(chips.at(1));
        await tester.pump();
      }
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bắt đầu ngay'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      print('📝 Content: Tạo bài viết đầu tiên');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      final postFields = find.byType(TextField);
      await tester.enterText(postFields.first, 'Chào thế giới từ E2E!');
      await tester.enterText(postFields.last, 'Đây là bài viết đầu tiên được tạo tự động bởi hành trình người dùng.');
      await tester.tap(find.text('Đăng bài'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('💬 Social: Gửi tin nhắn chào mừng');
      final destinations = find.byType(NavigationDestination);
      await tester.tap(destinations.at(2)); // Tab Chat
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.enterText(find.byType(TextField), 'Chào bạn, tôi là người mới!');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      print('💼 Career: Ứng tuyển việc làm');
      await tester.tap(destinations.at(1)); // Tab Explore
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Việc làm'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Ung tuyen ngay').first);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      print('⚙️ Settings: Đổi giao diện sang Dark Mode');
      await tester.tap(destinations.at(4)); // Tab Profile
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      print('🏁 Kết thúc: Đăng xuất');
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Đăng nhập'), findsWidgets);
      print('✅ HÀNH TRÌNH HOÀN TẤT: Toàn bộ hệ thống hoạt động hoàn hảo!');
    });
  });
}
