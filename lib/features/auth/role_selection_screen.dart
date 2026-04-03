import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/routes.dart';
import 'providers/user_role_provider.dart';
import 'auth_controller.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final AuthController _authController = AuthController();
  bool _isSaving = false;

  Future<void> _selectRole(String role) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    var shouldRedirect = false;

    try {
      await _authController.updateRole(role: role);
      ref.invalidate(userRoleProvider);
      shouldRedirect = true;
    } on AuthException catch (error) {
      _showMessage(error.message);
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted && shouldRedirect) {
        final targetRoute = role == 'owner'
            ? AppRoutes.ownerSetup
            : AppRoutes.renterSetup;
        Navigator.of(context).pushNamed(targetRoute);
      }
      if (mounted) {
        setState(() => _isSaving = false);
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: _isSaving
              ? null
              : () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  }
                },
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              Text(
                "Welcome to Naarixa",
                style: textTheme.headlineSmall?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Choose how you want to continue",
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 50),

              // RENTER CARD
              _buildRoleCard(
                icon: Icons.home_outlined,
                title: "I’m Looking for Safe Accommodation",
                description:
                    "Find verified PGs, check safety ratings, book securely & raise complaints safely.",
                buttonText: _isSaving ? "Saving..." : "Continue as User",
                onTap: _isSaving ? null : () => _selectRole('renter'),
              ),

              const SizedBox(height: 30),

              // OWNER CARD
              _buildRoleCard(
                icon: Icons.apartment_outlined,
                title: "I Want to List My Property",
                description:
                    "List your property, complete verification & manage bookings securely.",
                buttonText: _isSaving ? "Saving..." : "Continue as Owner",
                onTap: _isSaving ? null : () => _selectRole('owner'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final shadowColor = Theme.of(context).shadowColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.18),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 50,
            color: colorScheme.primary,
          ),

          const SizedBox(height: 20),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}