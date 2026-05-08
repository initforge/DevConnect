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

  group('Luồng 02: Bảng tin & Tương tác (Feed & Interaction Flow)', () {
    testWidgets('TC-FEED-FULL: Switch tabs -> Like -> Bookmark -> Detail -> Comment', (tester) async {
      await login(tester);

      // 1. Chuyển đổi giữa các tab Feed
      await tester.tap(find.text('Xu hướng'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Đang theo dõi'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Dành cho bạn'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 2. Tương tác Like trên Post Card đầu tiên
      final likeBtn = find.byIcon(Icons.favorite_border).first;
      await tester.tap(likeBtn);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.favorite), findsWidgets);

      // 3. Tương tác Bookmark
      final bookmarkBtn = find.byIcon(Icons.bookmark_border).first;
      await tester.tap(bookmarkBtn);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.bookmark), findsWidgets);

      // 4. Vào chi tiết bài viết (Tap vào InkWell đầu tiên của post)
      // Tìm InkWell nằm trong PostCard
      await tester.tap(find.byType(InkWell).at(1)); 
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 5. Viết bình luận trong chi tiết
      final commentInput = find.byType(TextField).last;
      await tester.enterText(commentInput, 'Bài viết rất hay! (E2E Test)');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 6. Quay lại feed
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // 7. Test Pull to Refresh
      await tester.fling(find.byType(Scrollable).first, const Offset(0, 400), 1000);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      print('✅ TC-FEED-FULL: Hoàn thành tương tác bảng tin!');
    });
  });
}
