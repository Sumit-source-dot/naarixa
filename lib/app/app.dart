import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/routes.dart';
import '../core/theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../core/services/hidden_gesture_detector.dart';
import '../core/services/sos_trigger_coordinator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NaarixaApp extends ConsumerStatefulWidget {
  const NaarixaApp({super.key});

  @override
  ConsumerState<NaarixaApp> createState() => _NaarixaAppState();
}

class _NaarixaAppState extends ConsumerState<NaarixaApp> {
  @override
  void initState() {
    super.initState();
    _initializeSosTriggersIfNeeded();
  }

  void _initializeSosTriggersIfNeeded() {
    try {
      // Safely check if Supabase is initialized before accessing
      if (Supabase.instance != null) {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          _setupSosTriggers(ref, currentUser.id);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Supabase not yet initialized during app startup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return HiddenGestureDetector(
      onTwoFingerTap: () async {
        // Silent 2-finger SOS activation (no UI feedback)
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          debugPrint('🚨 SOS triggered via hidden gesture (2-finger tap)');
          // TODO: Trigger existing SOS function from SosController
          // For now, this is just the infrastructure setup
        }
      },
      child: MaterialApp(
        title: 'Naarixa',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        initialRoute: AppRoutes.root,
      ),
    );
  }

  /// Setup SOS trigger systems when user logs in
  Future<void> _setupSosTriggers(WidgetRef ref, String userId) async {
    try {
      final coordinator = ref.read(sosTriggerCoordinatorProvider(userId));

      // Initialize all SOS trigger methods
      // These settings can be made configurable in Settings UI later
      await coordinator.initialize(
        enableVolumePress: true,           // 3x volume button in 2 seconds
        enableShakeDetection: true,        // Accelerometer-based
        enableHiddenGesture: true,         // 2-finger tap anywhere
        enableBackground: false,            // Disable background for now (needs configuration)
      );

      debugPrint('✅ SOS trigger systems initialized for user: $userId');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize SOS triggers: $e');
      // Don't fail app startup if SOS system fails
    }
  }
}
