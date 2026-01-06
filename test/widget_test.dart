// Updated test to match this project's app structure.
// The original default counter test expected a MyApp with a counter, but
// this project exposes ExhibitionApp (router + providers) and does not
// include the default counter UI. The test below overrides the routerProvider
// to a safe /login route and asserts the route renders.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:exhibition_booth_management/main.dart';
import 'package:exhibition_booth_management/core/router/app_router.dart';

void main() {
  testWidgets('ExhibitionApp renders overridden /login route',
          (WidgetTester tester) async {
        // Create a test router that only exposes a safe /login route
        final testRouter = GoRouter(
          initialLocation: '/login',
          routes: [
            GoRoute(
              path: '/login',
              builder: (context, state) => const Text('Login route'),
            ),
          ],
        );

        // Pump the app wrapped in a ProviderScope that overrides the routerProvider
        await tester.pumpWidget(
          ProviderScope(
            overrides: [routerProvider.overrideWithValue(testRouter)],
            child: const ExhibitionApp(),
          ),
        );

        // Allow router to settle
        await tester.pumpAndSettle();

        // Verify the overridden login route is shown
        expect(find.text('Login route'), findsOneWidget);
      });
}