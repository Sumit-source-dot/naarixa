import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_input.dart';
import '../../config/routes.dart';
import 'auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _authController = AuthController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email and password are required.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authController.login(email: email, password: password);

      // 🔥 Get profile after login
      final profile = await _authController.getUserProfile();

      if (!mounted) return;

      final role = _authController.getRoleFromProfile(profile);
      final isComplete = _authController.isProfileComplete(profile);

      if (role == null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.roleSelection,
          (route) => false,
        );
      } else if (isComplete) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      } else if (role == 'renter') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.renterSetup,
          (route) => false,
        );
      } else if (role == 'owner') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.ownerSetup,
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.roleSelection,
          (route) => false,
        );
      }
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (e) {
      _showMessage('Login failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const AppHeader(
                title: 'Login',
                subtitle: 'Sign in to continue',
              ),
              const SizedBox(height: 16),

              AppInput(
                hint: 'Email',
                controller: _emailController,
              ),

              const SizedBox(height: 12),

              AppInput(
                hint: 'Password',
                controller: _passwordController,
                obscureText: true,
              ),

              const SizedBox(height: 16),

              AppButton(
                label: _isLoading ? 'Please wait...' : 'Login',
                onPressed: _isLoading ? null : _handleLogin,
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          AppRoutes.register,
                        ),
                child: const Text('Create new account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}