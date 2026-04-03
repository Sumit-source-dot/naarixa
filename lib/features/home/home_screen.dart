import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ ADD THIS

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_header.dart';
import '../sos/services/debug_service.dart';
import '../../navigation/app_router.dart';
import '../auth/auth_controller.dart';
import 'widgets/safety_overview_card.dart';
import '../sos/controllers/sos_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final controller = SosController();
  bool _sosActive = false;
  dynamic _activeSosId;

  Future<void> _handleSignOut(BuildContext context) async {
    final authController = AuthController();
    await authController.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
  }

  Future<void> _verifySosSetup() async {
    try {
      final isValid = await controller.verifySosSetup();
      if (!mounted) return;

      if (isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ SOS setup verified! Tables are ready.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ SOS tables not found. Run sos/SOS_TRACKING_SCHEMA.sql in Supabase.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Naarixa Home'),
        actions: [
          TextButton(
            onPressed: () => _handleSignOut(context),
            child: const Text('Logout'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(
                title: 'Naarixa',
                subtitle: 'Women Safety & Development Platform',
              ),
              const SizedBox(height: 16),
              const SafetyOverviewCard(),
              const SizedBox(height: 16),

              // ✅ FIXED SOS BUTTON
              AppButton(
                label: _sosActive ? 'Stop SOS' : 'SOS',
                isSos: true,
                onPressed: () async {
                  final user = Supabase.instance.client.auth.currentUser;

                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User not logged in")),
                    );
                    return;
                  }

                  try {
                    if (_sosActive) {
                      await controller.stopSOS(
                        sosId: _activeSosId,
                        userId: user.id,
                      );
                      if (!context.mounted) return;
                      setState(() {
                        _sosActive = false;
                        _activeSosId = null;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("🛑 SOS stopped"),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("🚨 Sending SOS...")),
                    );

                    final sosId = await controller.triggerSOS(userId: user.id);

                    if (!context.mounted) return;
                    setState(() {
                      _sosActive = true;
                      _activeSosId = sosId;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("✅ SOS Sent! Alert ID: $sosId"),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("❌ Error: $e"),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              // ✅ DEBUG BUTTON - Verify SOS Setup
              OutlinedButton(
                onPressed: _verifySosSetup,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline),
                      SizedBox(width: 8),
                      Text('Verify SOS Setup'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 🔧 DEBUG BUTTON - Test Supabase Connection
              OutlinedButton(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Testing Supabase connection... Check console (F12)")),
                  );
                  await DebugService.testSupabaseConnection();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bug_report),
                      SizedBox(width: 8),
                      Text('Test Supabase Connection'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 📊 DEBUG BUTTON - Show SOS Alerts
              OutlinedButton(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Fetching SOS alerts... Check console (F12)")),
                  );
                  await DebugService.listAllSOSAlerts();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list),
                      SizedBox(width: 8),
                      Text('Show My SOS Alerts'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
