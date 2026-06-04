import 'package:go_router/go_router.dart';
import 'package:smart_travel_app/pages/home_page.dart';
import 'package:smart_travel_app/pages/route_plan_page.dart';
import 'package:smart_travel_app/pages/subway_service_page.dart';
import 'package:smart_travel_app/pages/transfer_time_page.dart';
import 'package:smart_travel_app/pages/profile_page.dart';
import 'package:smart_travel_app/pages/map_navigation_page.dart';
import 'package:smart_travel_app/pages/settings/theme_settings_page.dart';
import 'package:smart_travel_app/pages/settings/feedback_page.dart';
import 'package:smart_travel_app/pages/settings/about_app_page.dart';
import 'package:smart_travel_app/pages/settings/preferences_page.dart';
import 'package:smart_travel_app/pages/settings/ability_settings_page.dart';
import 'package:smart_travel_app/pages/settings/luggage_settings_page.dart';
import 'package:smart_travel_app/pages/settings/notifications_page.dart';
import 'package:smart_travel_app/pages/settings/help_center_page.dart';
import 'package:smart_travel_app/pages/settings/user_agreement_page.dart';
import 'package:smart_travel_app/pages/settings/api_settings_page.dart';
import 'package:smart_travel_app/pages/ai_planning_page.dart';

class AppRouter {
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/route-plan',
        builder: (context, state) {
          final start = state.uri.queryParameters['start'];
          final end = state.uri.queryParameters['end'];
          return RoutePlanPage(
            initialStartStation: start,
            initialEndStation: end,
            initialStartEntranceId:
                state.uri.queryParameters['startEntranceId'],
            initialStartEntranceName:
                state.uri.queryParameters['startEntranceName'],
            initialEndExitId: state.uri.queryParameters['endExitId'],
            initialEndExitName: state.uri.queryParameters['endExitName'],
          );
        },
      ),
      GoRoute(
        path: '/subway-service',
        builder: (context, state) => const SubwayServicePage(),
      ),
      GoRoute(
        path: '/transfer-time',
        builder: (context, state) => const TransferTimePage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
        routes: [
          GoRoute(
            path: 'theme',
            builder: (context, state) => const ThemeSettingsPage(),
          ),
          GoRoute(
            path: 'feedback',
            builder: (context, state) => const FeedbackPage(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutAppPage(),
          ),
          GoRoute(
            path: 'preferences',
            builder: (context, state) => const PreferencesPage(),
          ),
          GoRoute(
            path: 'ability',
            builder: (context, state) => const AbilitySettingsPage(),
          ),
          GoRoute(
            path: 'luggage',
            builder: (context, state) => const LuggageSettingsPage(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: 'help-center',
            builder: (context, state) => const HelpCenterPage(),
          ),
          GoRoute(
            path: 'user-agreement',
            builder: (context, state) => const UserAgreementPage(),
          ),
          GoRoute(
            path: 'api-settings',
            builder: (context, state) => const ApiSettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/map-navigation',
        builder: (context, state) => const MapNavigationPage(),
      ),
      GoRoute(
        path: '/ai-planning',
        builder: (context, state) {
          final start = state.uri.queryParameters['start'];
          final end = state.uri.queryParameters['end'];
          return AIPlanningPage(
            initialStartStation: start,
            initialEndStation: end,
            initialStartEntranceId:
                state.uri.queryParameters['startEntranceId'],
            initialStartEntranceName:
                state.uri.queryParameters['startEntranceName'],
            initialEndExitId: state.uri.queryParameters['endExitId'],
            initialEndExitName: state.uri.queryParameters['endExitName'],
          );
        },
      ),
    ],
  );
}
