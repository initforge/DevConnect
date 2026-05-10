import 'package:devconnect/main.dart' as app;
import 'package:devconnect/core/constants/routes.dart';
import 'package:devconnect/core/widgets/shared_widgets.dart';
import 'package:devconnect/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  Future<void> loginIfNeeded(WidgetTester tester) async {
    final emailFields = find.byType(TextFormField);
    if (emailFields.evaluate().length >= 2) {
      await tester.enterText(emailFields.at(0), 'minh@dev.com');
      await tester.enterText(emailFields.at(1), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 8));
    }

    final skipForNow = find.text('Skip for now');
    if (skipForNow.evaluate().isNotEmpty) {
      await tester.tap(skipForNow);
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 4));
    }

    expect(find.byType(AppBottomNavBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  Future<void> goToRoute(WidgetTester tester, String route) async {
    appRouter.go(route);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 6));
    expect(tester.takeException(), isNull);
  }

  Future<void> expectScreen(
    WidgetTester tester, {
    required String route,
    required List<Finder> requiredFinders,
  }) async {
    await goToRoute(tester, route);
    for (final finder in requiredFinders) {
      expect(finder, findsWidgets);
    }
  }

  testWidgets('smoke verify updated screens render without runtime errors', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginIfNeeded(tester);

    await expectScreen(
      tester,
      route: AppRoutes.profile,
      requiredFinders: [
        find.text('GitHub Connected'),
        find.text('Posts'),
        find.text('About'),
      ],
    );

    await expectScreen(
      tester,
      route: AppRoutes.chat,
      requiredFinders: [find.text('Messages'), find.text('ONLINE NOW')],
    );

    await expectScreen(
      tester,
      route: AppRoutes.notifications,
      requiredFinders: [find.text('Notifications'), find.text('Today')],
    );

    await expectScreen(
      tester,
      route: AppRoutes.settings,
      requiredFinders: [
        find.text('Settings'),
        find.text('ACCOUNT'),
        find.text('PRIVACY'),
      ],
    );

    await expectScreen(
      tester,
      route: AppRoutes.projects,
      requiredFinders: [find.text('Projects'), find.text('Looking for Devs')],
    );

    await expectScreen(
      tester,
      route: AppRoutes.jobs,
      requiredFinders: [find.text('Jobs'), find.text('Hiring pulse')],
    );

    await expectScreen(
      tester,
      route: AppRoutes.leaderboard,
      requiredFinders: [
        find.text('Leaderboard'),
        find.textContaining('most valuable builders'),
      ],
    );

    await expectScreen(
      tester,
      route: AppRoutes.analytics,
      requiredFinders: [
        find.text('Your Analytics'),
        find.text('Viewer Over Time'),
      ],
    );

    await expectScreen(
      tester,
      route: AppRoutes.playground,
      requiredFinders: [
        find.text('Code Playground'),
        find.text('Console Output'),
      ],
    );

    await expectScreen(
      tester,
      route: AppRoutes.liveCode,
      requiredFinders: [
        find.text('Live Session'),
        find.textContaining('new API hook'),
      ],
    );

    await expectScreen(
      tester,
      route: AppRoutes.mentorship,
      requiredFinders: [
        find.text('Mentorship'),
        find.text('Best matches for you'),
      ],
    );
  });
}
