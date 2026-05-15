import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect/features/feed/widgets/feed_list.dart';
import 'package:devconnect/data/repositories/post_repository.dart';

void main() {
  group('FeedList', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: FeedList(
                  feedType: FeedType.forYou,
                  onRefresh: () async {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      });
      expect(find.byType(FeedList), findsOneWidget);
    });
  });
}
