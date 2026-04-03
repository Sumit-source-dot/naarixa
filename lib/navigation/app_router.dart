import 'package:flutter/material.dart';

import '../features/auth/auth_gate_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import 'main_navigation_screen.dart';

class AppRouter {
  AppRouter._();

  static const String authGate = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case authGate:
        return MaterialPageRoute(builder: (_) => const AuthGateScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
      default:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
    }
  }
}
