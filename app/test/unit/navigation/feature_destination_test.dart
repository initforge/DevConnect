import 'package:devconnect/core/constants/routes.dart';
import 'package:devconnect/core/navigation/feature_destination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeatureDestinations', () {
    test('mobile nav exposes the expected 4 destinations plus create action', () {
      expect(
        FeatureDestinations.mobile.map((item) => item.route),
        [AppRoutes.home, AppRoutes.explore, AppRoutes.chat, AppRoutes.more],
      );
    });

    test('more hub exposes non-primary features', () {
      final routes = FeatureDestinations.moreItems.map((item) => item.route);

      expect(routes, contains(AppRoutes.notifications));
      expect(routes, contains(AppRoutes.profile));
      expect(routes, contains(AppRoutes.projects));
      expect(routes, contains(AppRoutes.jobs));
      expect(routes, contains(AppRoutes.leaderboard));
      expect(routes, contains(AppRoutes.analytics));
      expect(routes, contains(AppRoutes.playground));
      expect(routes, contains(AppRoutes.mentorship));
      expect(routes, contains(AppRoutes.settings));
    });

    test('route lookup resolves nested feature routes', () {
      expect(FeatureDestinations.fromRoute('/chat/conv1')?.id, 'chat');
      expect(FeatureDestinations.fromRoute('/projects')?.id, 'projects');
      expect(FeatureDestinations.fromRoute('/more')?.id, 'more');
    });

    test('live code is marked as preview', () {
      expect(
        FeatureDestinations.liveCode.status,
        FeatureDestinationStatus.preview,
      );
    });
  });
}
