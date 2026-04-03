import 'package:flutter/material.dart';

import '../../config/routes.dart';
import 'auth_controller.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final AuthController _authController = AuthController();
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _routeUser();
  }

  void _goTo(String routeName) {
    if (!mounted || _didNavigate) return;
    _didNavigate = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(routeName);
    });
  }

  Future<void> _routeUser() async {
    if (!_authController.isLoggedIn) {
      _goTo(AppRoutes.login);
      return;
    }

    final profile = await _authController.getUserProfile();
    if (!mounted) return;

    final role = _authController.getRoleFromProfile(profile);
    final isComplete = _authController.isProfileComplete(profile);

    if (role == null) {
      _goTo(AppRoutes.roleSelection);
      return;
    }

    if (isComplete) {
      _goTo(AppRoutes.home);
      return;
    }

    if (role == 'renter') {
      _goTo(AppRoutes.renterSetup);
      return;
    }

    if (role == 'owner') {
      _goTo(AppRoutes.ownerSetup);
      return;
    }

    _goTo(AppRoutes.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
