import 'package:exhibition_booth_management/features/admin/pages/manage_applications_page.dart';
import 'package:exhibition_booth_management/features/exhibitor/pages/my_applications_page.dart';
import 'dashboard_redirect_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/guest/pages/guest_home_page.dart';
import '../../features/guest/pages/exhibition_detail_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/exhibitor/pages/exhibitor_home_page.dart';
import '../../features/exhibitor/pages/event_selection_page.dart';
import '../../features/exhibitor/pages/floor_plan_page.dart';
import '../../features/exhibitor/pages/booking_application_page.dart';
import '../../features/organizer/pages/organizer_home_page.dart';
import '../../features/organizer/pages/manage_exhibitions_page.dart';
import '../../features/organizer/pages/manage_booths_page.dart';
import '../../features/organizer/pages/applications_review_page.dart';
import '../../features/admin/pages/admin_home_page.dart';
import '../../features/admin/pages/manage_all_exhibitions_page.dart';
import '../../features/admin/pages/manage_floor_plans_page.dart';
import '../../features/admin/pages/manage_users_page.dart';
import '../../models/models.dart';

/// Router provider that manages navigation throughout the app
/// Uses GoRouter with authentication-based redirection
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final location = state.matchedLocation;

      // 1️⃣ Not logged in
      if (!isLoggedIn) {
        // Allow guest pages
        if (location == '/' ||
            location == '/login' ||
            location == '/register' ||
            location.startsWith('/exhibition/')) {
          return null;
        }
        return '/login';
      }

      // 2️⃣ Logged in user
      final user = authState.asData!.value!;

      // 🔥 NEW: logged in but still on guest home
      if (location == '/') {
        switch (user.role) {
          case UserRole.exhibitor:
            return '/exhibitor';
          case UserRole.organizer:
            return '/organizer';
          case UserRole.admin:
            return '/admin';
          default:
            return null;
        }
      }

      // 3️⃣ Prevent going back to login/register
      if (location == '/login' || location == '/register') {
        switch (user.role) {
          case UserRole.exhibitor:
            return '/exhibitor';
          case UserRole.organizer:
            return '/organizer';
          case UserRole.admin:
            return '/admin';
          default:
            return null;
        }
      }

      return null;
    },

    routes: [
      // Guest Routes
      GoRoute(
        path: '/',
        builder: (context, state) => const GuestHomePage(),
      ),
      GoRoute(
        path: '/exhibition/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ExhibitionDetailPage(exhibitionId: id);
        },
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Exhibitor Routes
      GoRoute(
        path: '/exhibitor',
        builder: (context, state) => const ExhibitorHomePage(),
      ),
      GoRoute(
        path: '/exhibitor/events',
        builder: (context, state) => const EventSelectionPage(),
      ),
      GoRoute(
        path: '/exhibitor/floor-plan/:exhibitionId',
        builder: (context, state) {
          final exhibitionId = state.pathParameters['exhibitionId']!;
          return FloorPlanPage(exhibitionId: exhibitionId);
        },
      ),
      GoRoute(
        path: '/exhibitor/booking-application',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BookingApplicationPage(
            exhibitionId: extra['exhibitionId'],
            selectedBooths: extra['selectedBooths'],
          );
        },
      ),
      GoRoute(
        path: '/exhibitor/my-applications',
        builder: (context, state) => const MyApplicationsPage(),
      ),

      // Organizer Routes
      GoRoute(
        path: '/organizer',
        builder: (context, state) => const OrganizerHomePage(),
      ),
      GoRoute(
        path: '/organizer/exhibitions',
        builder: (context, state) => const ManageExhibitionsPage(),
      ),
      GoRoute(
        path: '/organizer/booths/:exhibitionId',
        builder: (context, state) {
          final exhibitionId = state.pathParameters['exhibitionId']!;
          return ManageBoothsPage(exhibitionId: exhibitionId);
        },
      ),
      GoRoute(
        path: '/organizer/applications',
        builder: (context, state) => const ApplicationsReviewPage(),
      ),

      // Admin Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHomePage(),
      ),
      GoRoute(
        path: '/admin/exhibitions',
        builder: (context, state) => const ManageAllExhibitionsPage(),
      ),
      GoRoute(
        path: '/admin/floor-plans',
        builder: (context, state) => const ManageFloorPlansPage(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const ManageUsersPage(),
      ),
      GoRoute(
        path: '/admin/applications',
        builder: (context, state) => const ManageApplicationsPage(),
      ),

    ],
  );
});