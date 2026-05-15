import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect/features/auth/screens/login_screen.dart';

void main() {
  Widget buildApp() =>
      const ProviderScope(child: MaterialApp(home: LoginScreen()));

  group('LoginScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('shows email and password fields', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    });

    testWidgets('Sign In button is disabled when form is empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      // Find the Sign In button
      final button = find.widgetWithText(ElevatedButton, 'Sign In');
      expect(button, findsOneWidget);
      // Button should be disabled (onPressed == null) when form is empty
      final elevatedButton = tester.widget<ElevatedButton>(button);
      expect(elevatedButton.onPressed, isNull);
    });
  });
}
