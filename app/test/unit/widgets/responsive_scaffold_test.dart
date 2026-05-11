import 'package:devconnect/core/navigation/feature_destination.dart';
import 'package:devconnect/core/widgets/responsive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResponsiveScaffold', () {
    Widget buildTestScaffold({
      String currentRoute = '/home',
      Size screenSize = const Size(400, 800),
      bool showBottomNav = true,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: ResponsiveScaffold(
            currentRoute: currentRoute,
            showBottomNav: showBottomNav,
            body: const Center(child: Text('Test Body')),
          ),
        ),
      );
    }

    testWidgets('renders body on mobile screen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScaffold(screenSize: const Size(390, 844)));

      expect(find.text('Test Body'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('renders sidebar on desktop screen', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScaffold(screenSize: const Size(1440, 900)));

      expect(find.text('Test Body'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('DevConnect'), findsOneWidget);
    });

    testWidgets('renders icon-only sidebar on tablet screen', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScaffold(screenSize: const Size(768, 1024)));

      expect(find.text('DevConnect'), findsNothing);
    });

    testWidgets('hides bottom nav when showBottomNav is false', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: const Size(390, 844)),
            child: ResponsiveScaffold(
              currentRoute: '/home',
              showBottomNav: false,
              body: const Center(child: Text('Body without nav')),
            ),
          ),
        ),
      );

      expect(find.byType(NavigationBar), findsNothing);
    });
  });

  group('ResponsiveLayout', () {
    Widget buildLayoutTest({required Size screenSize}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const ResponsiveLayout(
            mobile: Text('Mobile'),
            tablet: Text('Tablet'),
            desktop: Text('Desktop'),
          ),
        ),
      );
    }

    testWidgets('shows mobile widget on small screen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildLayoutTest(screenSize: const Size(390, 844)));

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('shows tablet widget on medium screen', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildLayoutTest(screenSize: const Size(768, 1024)));

      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Mobile'), findsNothing);
    });

    testWidgets('shows desktop widget on large screen', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildLayoutTest(screenSize: const Size(1440, 900)));

      expect(find.text('Desktop'), findsOneWidget);
    });
  });

  group('FeatureDestination - route matching', () {
    test('home destination matches /home route', () {
      expect(FeatureDestinations.home.matchesRoute('/home'), isTrue);
      expect(FeatureDestinations.home.matchesRoute('/home/'), isTrue);
    });

    test('explore destination matches /explore route', () {
      expect(FeatureDestinations.explore.matchesRoute('/explore'), isTrue);
    });

    test('chat destination matches /chat route', () {
      expect(FeatureDestinations.chat.matchesRoute('/chat'), isTrue);
    });

    test('notifications destination matches /notifications route', () {
      expect(FeatureDestinations.notifications.matchesRoute('/notifications'), isTrue);
    });

    test('profile destination matches /profile route', () {
      expect(FeatureDestinations.profile.matchesRoute('/profile'), isTrue);
      expect(FeatureDestinations.profile.matchesRoute('/profile/u123'), isTrue);
    });

    test('projects destination matches /projects route', () {
      expect(FeatureDestinations.projects.matchesRoute('/projects'), isTrue);
    });

    test('settings destination matches /settings route', () {
      expect(FeatureDestinations.settings.matchesRoute('/settings'), isTrue);
    });

    test('non-matching route returns false', () {
      expect(FeatureDestinations.home.matchesRoute('/explore'), isFalse);
      expect(FeatureDestinations.chat.matchesRoute('/home'), isFalse);
    });
  });

  group('FeatureDestinations registry', () {
    test('mobile list has exactly 4 items', () {
      expect(FeatureDestinations.mobile, hasLength(4));
    });

    test('mobile destinations are in correct order', () {
      expect(FeatureDestinations.mobile[0].id, equals('home'));
      expect(FeatureDestinations.mobile[1].id, equals('explore'));
      expect(FeatureDestinations.mobile[2].id, equals('chat'));
      expect(FeatureDestinations.mobile[3].id, equals('more'));
    });

    test('sidebar list is non-empty', () {
      expect(FeatureDestinations.sidebar, isNotEmpty);
      expect(FeatureDestinations.sidebar.length, greaterThan(FeatureDestinations.mobile.length));
    });

    test('moreItems list contains all non-primary destinations', () {
      expect(FeatureDestinations.moreItems, isNotEmpty);
      for (final item in FeatureDestinations.moreItems) {
        expect(item.group, isNot(equals(FeatureDestinationGroup.primary)));
      }
    });

    test('all sidebar items have valid group labels', () {
      for (final item in FeatureDestinations.sidebar) {
        expect(FeatureDestinations.groupLabel(item.group), isNotEmpty);
      }
    });

    test('fromRoute finds correct destination', () {
      expect(FeatureDestinations.fromRoute('/home')?.id, equals('home'));
      expect(FeatureDestinations.fromRoute('/explore')?.id, equals('explore'));
      expect(FeatureDestinations.fromRoute('/settings')?.id, equals('settings'));
      expect(FeatureDestinations.fromRoute('/nonexistent'), isNull);
    });
  });
}
