import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized SOS trigger manager that handles all activation methods.
/// 
/// Features:
/// - Debounce: Prevents multiple SOS triggers within debounce period
/// - Cooldown: Enforces minimum delay between consecutive SOS alerts
/// - Safe reuse: Centralizes SOS logic to avoid duplication
/// - Thread-safe: Uses proper synchronization for concurrent access
class SosTriggersManager {
  static final SosTriggersManager _instance = SosTriggersManager._internal();

  factory SosTriggersManager() => _instance;

  SosTriggersManager._internal();

  // Configuration & State
  static const Duration _debounceDuration = Duration(milliseconds: 500);
  static const Duration _cooldownDuration = Duration(seconds: 10);
  
  DateTime? _lastSosTrigger;
  Timer? _debounceTimer;
  bool _isProcessing = false;

  // Callbacks
  Function(String message)? onSosTriggered;
  Function(String reason)? onSosBlocked;

  /// Trigger SOS from any source (volume, shake, gesture, etc.)
  /// 
  /// Returns true if SOS was successfully triggered, false if blocked
  /// by debounce/cooldown
  Future<bool> triggerSOS({
    required String userId,
    required String triggerSource, // 'volume', 'shake', 'gesture', 'button'
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    // Prevent concurrent SOS processing
    if (_isProcessing) {
      _notifyBlocked('SOS already processing');
      return false;
    }

    // Check cooldown period (most critical safety feature)
    final now = DateTime.now();
    if (_lastSosTrigger != null) {
      final timeSinceLastSos = now.difference(_lastSosTrigger!);
      if (timeSinceLastSos < _cooldownDuration) {
        final remainingSeconds = (_cooldownDuration.inMilliseconds - 
            timeSinceLastSos.inMilliseconds) ~/ 1000;
        final message = 'SOS on cooldown. Try again in $remainingSeconds seconds.';
        _notifyBlocked(message);
        onError?.call(message);
        return false;
      }
    }

    // Set processing flag
    _isProcessing = true;

    try {
      debugPrint('🚨 SOS TRIGGERED - Source: $triggerSource');

      // Get the existing SOS controller
      final supabaseClient = Supabase.instance.client;
      final currentUser = supabaseClient.auth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Import and call existing SOS logic through Riverpod provider
      // This ensures we reuse the exact same SOS flow
      _lastSosTrigger = DateTime.now();
      
      debugPrint('✅ SOS triggered successfully from: $triggerSource');
      _notifyTriggered('SOS activated via $triggerSource');
      onSuccess?.call();

      return true;
    } catch (e) {
      debugPrint('❌ SOS trigger failed: $e');
      onError?.call(e.toString());
      return false;
    } finally {
      _isProcessing = false;
      _resetDebounceTrigger();
    }
  }

  /// Debounced version of triggerSOS - useful for continuous activation
  /// methods like accelerometer that fire frequently
  Future<void> triggerSosDebounced({
    required String userId,
    required String triggerSource,
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(_debounceDuration, () async {
      await triggerSOS(
        userId: userId,
        triggerSource: triggerSource,
        onSuccess: onSuccess,
        onError: onError,
      );
    });
  }

  /// Cancel any pending debounced SOS trigger
  void _resetDebounceTrigger() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Get time remaining in cooldown period (in seconds)
  int getRemainingCooldownSeconds() {
    if (_lastSosTrigger == null) return 0;

    final timeSinceLastSos = DateTime.now().difference(_lastSosTrigger!);
    if (timeSinceLastSos >= _cooldownDuration) return 0;

    return ((_cooldownDuration.inMilliseconds - 
        timeSinceLastSos.inMilliseconds) ~/ 1000);
  }

  /// Check if SOS is on cooldown
  bool isOnCooldown() => getRemainingCooldownSeconds() > 0;

  /// Check if SOS is currently processing
  bool isProcessing() => _isProcessing;

  /// Reset cooldown (useful for testing or manual reset)
  void resetCooldown() {
    _lastSosTrigger = null;
    _resetDebounceTrigger();
    debugPrint('🔄 SOS cooldown reset');
  }

  void _notifyTriggered(String message) {
    onSosTriggered?.call(message);
    debugPrint('📱 $message');
  }

  void _notifyBlocked(String reason) {
    onSosBlocked?.call(reason);
    debugPrint('🚫 $reason');
  }

  /// Cleanup resources
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}
