import 'package:go_router/go_router.dart';
import 'package:smart_travel_app/pages/home_page.dart';
import 'package:smart_travel_app/pages/route_plan_page.dart';
import 'package:smart_travel_app/pages/subway_service_page.dart';
import 'package:smart_travel_app/pages/high_speed_rail_page.dart';
import 'package:smart_travel_app/pages/transfer_time_page.dart';
import 'package:smart_travel_app/pages/profile_page.dart';
import 'package:smart_travel_app/pages/map_navigation_page.dart';

class AppRouter {
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/route-plan',
        builder: (context, state) => const RoutePlanPage(),
      ),
      GoRoute(
        path: '/subway-service',
        builder: (context, state) => const SubwayServicePage(),
      ),
      GoRoute(
        path: '/high-speed-rail',
        builder: (context, state) => const HighSpeedRailPage(),
      ),
      GoRoute(
        path: '/transfer-time',
        builder: (context, state) => const TransferTimePage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/map-navigation',
        builder: (context, state) => const MapNavigationPage(),
      ),
    ],
  );
}
