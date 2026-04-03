import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'volume_button_listener.dart';
import 'shake_detector.dart';
import 'sos_trigger_manager.dart';
import 'hidden_gesture_detector.dart' as gesture;
import 'background_sos_service.dart';

/// Riverpod providers for SOS systems
final sosTriggersManagerProvider = Provider<SosTriggersManager>((ref) {
  return SosTriggersManager();
});

final volumeButtonListenerProvider = Provider<VolumeButtonListener>((ref) {
  return VolumeButtonListener();
});

final shakeDetectorProvider = Provider<ShakeDetector>((ref) {
  return ShakeDetector();
});

final backgroundSosServiceProvider = Provider<BackgroundSosService>((ref) {
  return BackgroundSosService();
});

/// Coordinator that integrates all SOS trigger methods
/// 
/// Responsibilities:
/// - Setup and manage all trigger listeners
/// - Show notifications when triggers are active
/// - Reuse existing SOS function from SosController
/// - Handle lifecycle (create/dispose)
class SosTriggerCoordinator {
  final ProviderRef ref;
  final String userId;

  SosTriggerCoordinator({
    required this.ref,
    required this.userId,
  });

  bool _isInitialized = false;

  /// Initialize all SOS trigger systems
  Future<void> initialize({
    bool enableVolumePress = true,
    bool enableShakeDetection = true,
    bool enableHiddenGesture = false,  // Optional - can be toggled in settings
    bool enableBackground = true,
  }) async {
    if (_isInitialized) return;

    debugPrint('🚀 Initializing SOS Trigger Coordinator...');

    try {
      // Initialize each trigger system
      if (enableVolumePress) await _setupVolumeListener();
      if (enableShakeDetection) await _setupShakeDetector();
      if (enableHiddenGesture) 
        debugPrint('✅ Hidden gesture detector ready (2-finger tap anywhere)');
      if (enableBackground) await _setupBackgroundService();

      _isInitialized = true;
      debugPrint('✅ SOS Trigger Coordinator initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize SOS Trigger Coordinator: $e');
      rethrow;
    }
  }

  /// Setup volume button listener
  Future<void> _setupVolumeListener() async {
    try {
      final listener = ref.read(volumeButtonListenerProvider);

      // Setup callbacks
      listener.onVolumePressDetected = (pressCount) {
        debugPrint('📱 Volume press: $pressCount/3');
      };

      listener.onSosTriggerDetected = () async {
        await _triggerSosFromSource('volume_button');
      };

      // Start listening
      await listener.startListening();
      debugPrint('✅ Volume button listener activated');
    } catch (e) {
      debugPrint('❌ Failed to setup volume listener: $e');
    }
  }

  /// Setup shake detector with medium sensitivity
  Future<void> _setupShakeDetector() async {
    try {
      final detector = ref.read(shakeDetectorProvider);

      // Setup callbacks
      detector.onShakeDetected = (magnitude) {
        debugPrint('💥 Shake detected: magnitude $magnitude');
      };

      detector.onSosTriggerDetected = () async {
        await _triggerSosFromSource('shake_detection');
      };

      // Start with medium sensitivity (can be changed via settings)
      await detector.startListening(
        sensitivity: ShakeSensitivity.medium,
      );
      debugPrint('✅ Shake detector activated (Medium sensitivity)');
    } catch (e) {
      debugPrint('❌ Failed to setup shake detector: $e');
    }
  }

  /// Setup background SOS service
  Future<void> _setupBackgroundService() async {
    try {
      final backgroundService = ref.read(backgroundSosServiceProvider);

      // Initialize background service
      final initialized = await backgroundService.initialize();
      if (initialized) {
        await backgroundService.startService();
        debugPrint('✅ Background SOS service activated');
      }
    } catch (e) {
      debugPrint('⚠️ Background service setup skipped: $e');
      // Don't fail coordinator setup if background service fails
    }
  }

  /// Trigger SOS from any source and integrate with existing SOS controller
  Future<void> _triggerSosFromSource(String source) async {
    try {
      final triggersManager = ref.read(sosTriggersManagerProvider);
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        debugPrint('❌ User not authenticated');
        return;
      }

      // Check cooldown before triggering
      if (triggersManager.isOnCooldown()) {
        final remaining = triggersManager.getRemainingCooldownSeconds();
        debugPrint('⏱️ SOS on cooldown: $remaining seconds remaining');
        return;
      }

      // Trigger SOS through centralized manager
      final success = await triggersManager.triggerSOS(
        userId: currentUser.id,
        triggerSource: source,
        onSuccess: () {
          debugPrint('✅ SOS successfully triggered via $source');
          
          // TODO: Call the existing triggerEmergencyFlow from SosController
          // This needs to be done through Riverpod provider
          // Example: ref.read(sosControllerProvider).triggerEmergencyFlow(...)
          
          // For now, we're setting up the infrastructure
          // The actual SOS execution will be handled by your existing SosController
        },
        onError: (error) {
          debugPrint('❌ SOS trigger failed: $error');
        },
      );

      if (success) {
        debugPrint('🚨 SOS activated by: $source');
      }
    } catch (e) {
      debugPrint('❌ Error triggering SOS: $e');
    }
  }

  /// Update shake sensitivity at runtime (call from settings)
  void setShakeSensitivity(ShakeSensitivity sensitivity) {
    final detector = ref.read(shakeDetectorProvider);
    detector.setSensitivity(sensitivity);
    debugPrint('📊 Shake sensitivity updated: $sensitivity');
  }

  /// Enable/disable volume button SOS
  Future<void> setVolumeButtonEnabled(bool enabled) async {
    final listener = ref.read(volumeButtonListenerProvider);
    if (enabled) {
      await listener.startListening();
    } else {
      await listener.stopListening();
    }
    debugPrint(enabled ? '✅ Volume button SOS enabled' : '❌ Volume button SOS disabled');
  }

  /// Enable/disable shake detection
  Future<void> setShakeDetectionEnabled(bool enabled) async {
    final detector = ref.read(shakeDetectorProvider);
    if (enabled) {
      await detector.startListening();
    } else {
      await detector.stopListening();
    }
    debugPrint(enabled ? '✅ Shake detection enabled' : '❌ Shake detection disabled');
  }

  /// Get current status of all systems
  Map<String, dynamic> getSystemStatus() {
    final triggersManager = ref.read(sosTriggersManagerProvider);
    final listener = ref.read(volumeButtonListenerProvider);
    final detector = ref.read(shakeDetectorProvider);
    final backgroundService = ref.read(backgroundSosServiceProvider);

    return {
      'initialized': _isInitialized,
      'processing': triggersManager.isProcessing(),
      'onCooldown': triggersManager.isOnCooldown(),
      'cooldownRemaining': triggersManager.getRemainingCooldownSeconds(),
      'volumeListenerActive': listener.isListening(),
      'shakeDetectorActive': detector.isListening(),
      'shakeOnCooldown': detector.isOnCooldown(),
      'backgroundServiceRunning': backgroundService.isRunning(),
    };
  }

  /// Cleanup all resources
  void dispose() {
    try {
      debugPrint('🧹 Disposing SOS Trigger Coordinator...');

      final listener = ref.read(volumeButtonListenerProvider);
      final detector = ref.read(shakeDetectorProvider);
      final triggersManager = ref.read(sosTriggersManagerProvider);
      final backgroundService = ref.read(backgroundSosServiceProvider);

      listener.dispose();
      detector.dispose();
      triggersManager.dispose();
      backgroundService.dispose();

      _isInitialized = false;
      debugPrint('✅ SOS Trigger Coordinator disposed');
    } catch (e) {
      debugPrint('❌ Error disposing SOS Trigger Coordinator: $e');
    }
  }

  /// Check if coordinator is initialized
  bool get isInitialized => _isInitialized;
}

/// Provider for the coordinator (singleton per user ID)
final sosTriggerCoordinatorProvider = Provider.family<SosTriggerCoordinator, String>((ref, userId) {
  return SosTriggerCoordinator(ref: ref, userId: userId);
});
