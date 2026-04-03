import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/// Background service for monitoring SOS triggers even when app is minimized.
/// 
/// Responsibilities:
/// - Request necessary permissions for background operation
/// - Keep volume button listener active in background
/// - Monitor accelerometer for shake detection
class BackgroundSosService {
  static final BackgroundSosService _instance = BackgroundSosService._internal();

  factory BackgroundSosService() => _instance;

  BackgroundSosService._internal();

  bool _isRunning = false;

  /// Initialize and start the background SOS service
  Future<bool> initialize() async {
    try {
      // Request necessary permissions
      await _requestPermissions();
      debugPrint('✅ Background SOS service initialized');
      return true;
    } catch (e) {
      debugPrint('⚠️ Failed to initialize background SOS service: $e');
      return false;
    }
  }

  /// Start background SOS monitoring
  Future<bool> startService() async {
    try {
      if (_isRunning) {
        debugPrint('⚠️ Background SOS service already running');
        return true;
      }

      // For now, just set the flag. The actual background listening
      // is handled by VolumeButtonListener and ShakeDetector at the OS level
      _isRunning = true;

      debugPrint('✅ Background SOS service started');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start background SOS service: $e');
      return false;
    }
  }

  /// Stop background SOS monitoring
  Future<bool> stopService() async {
    try {
      if (!_isRunning) {
        debugPrint('⚠️ Background SOS service not running');
        return true;
      }

      _isRunning = false;

      debugPrint('✅ Background SOS service stopped');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to stop background SOS service: $e');
      return false;
    }
  }

  /// Request necessary permissions for background operation
  Future<bool> _requestPermissions() async {
    try {
      final permissions = [
        Permission.location,
        Permission.phone,
        Permission.sms,
        Permission.sensors,
      ];

      final statuses = await permissions.request();
      
      for (final entry in statuses.entries) {
        if (entry.value.isDenied) {
          debugPrint('⚠️ Permission denied: ${entry.key}');
        } else if (entry.value.isPermanentlyDenied) {
          debugPrint('❌ Permission permanently denied: ${entry.key}');
        } else {
          debugPrint('✅ Permission granted: ${entry.key}');
        }
      }

      return true;
    } catch (e) {
      debugPrint('⚠️ Failed to request permissions: $e');
      return false;
    }
  }

  /// Check if service is running
  bool isRunning() => _isRunning;

  /// Cleanup resources
  void dispose() {
    stopService();
  }
}
