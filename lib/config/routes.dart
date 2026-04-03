import 'package:flutter/material.dart';

import '../features/accommodation/presentation/screens/property_detail_screen.dart';
import '../features/accommodation/presentation/screens/add_property_screen.dart';
import '../features/auth/auth_gate_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/owner_setup_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/renter_setup_screen.dart';
import '../features/auth/role_selection_screen.dart';
import '../features/cabs/models/ride_model.dart';
import '../features/cabs/screens/cabs_home_screen.dart';
import '../features/cabs/screens/ride_tracking_screen.dart';
import '../features/complaints/presentation/screens/complaints_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/safety/routes/presentation/screens/safest_route_screen.dart';
import '../features/safety/presentation/screens/helpline_screen.dart';
import '../features/safety/presentation/screens/safety_tips_screen.dart';
import '../features/sos/presentation/screens/sos_emergency_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/travel/route_monitoring/presentation/screens/deviation_monitoring_screen.dart';
import '../features/travel/tracking/presentation/screens/live_tracking_screen.dart';
import '../navigation/main_navigation_screen.dart';
import '../shared/models/accommodation_property.dart';

class AppRoutes {
  AppRoutes._();

  static const String root = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String roleSelection = '/roleSelection';
  static const String renterSetup = '/renter-setup';
  static const String ownerSetup = '/owner-setup';
  static const String complaints = '/complaints';
  static const String notifications = '/notifications';
  static const String propertyDetail = '/property-detail';
  static const String addProperty = '/add-property';
  static const String cabs = '/cabs';
  static const String rideTracking = '/ride-tracking';
  static const String sosEmergency = '/sos-emergency';
  static const String helplines = '/helplines';
  static const String safetyTips = '/safety-tips';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case root:
        return MaterialPageRoute(builder: (_) => const AuthGateScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      case renterSetup:
        return MaterialPageRoute(builder: (_) => const RenterSetupScreen());
      case ownerSetup:
        return MaterialPageRoute(builder: (_) => const OwnerSetupScreen());
      case complaints:
        return MaterialPageRoute(
          builder: (_) => const ComplaintsScreen(showAppBar: true),
        );
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case propertyDetail:
        final property = routeSettings.arguments as AccommodationProperty;
        return MaterialPageRoute(
          builder: (_) => PropertyDetailScreen(property: property),
        );
      case addProperty:
        return MaterialPageRoute(builder: (_) => const AddPropertyScreen());
      case cabs:
        return MaterialPageRoute(builder: (_) => const CabsHomeScreen());
      case rideTracking:
        final ride = routeSettings.arguments as Ride;
        return MaterialPageRoute(
          builder: (_) => RideTrackingScreen(ride: ride),
        );
      case sosEmergency:
        return MaterialPageRoute(builder: (_) => const SosEmergencyScreen());
      case helplines:
        return MaterialPageRoute(builder: (_) => const HelplineScreen());
      case safetyTips:
        return MaterialPageRoute(builder: (_) => const SafetyTipsScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(builder: (_) => const AuthGateScreen());
    }
  }
}