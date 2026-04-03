import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/material.dart';

/// Detects device shakes using accelerometer data.
/// 
/// Features:
/// - Configurable sensitivity levels (LOW, MEDIUM, HIGH)
/// - Prevents false positives with shake confirmation logic
/// - Automatic reset after detection
/// - Works in background when service is active
class ShakeDetector {
  static final ShakeDetector _instance = ShakeDetector._internal();

  factory ShakeDetector() => _instance;

  ShakeDetector._internal();

  // Sensitivity levels (shake threshold in m/s²)
  static const double _sensitivityLow = 20.0;      // Gentle shakes only
  static const double _sensitivityMedium = 15.0;   // Normal detection
  static const double _sensitivityHigh = 10.0;     // Most sensitive

  // Configuration for shake confirmation
  static const int _requiredShakes = 2;            // Consecutive shakes needed
  static const Duration _shakeWindow = Duration(milliseconds: 800);
  static const Duration _cooldownAfterDetection = Duration(seconds: 2);

  // State
  bool _isListening = false;
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;
  double _currentSensitivity = _sensitivityMedium;
  
  int _shakeCount = 0;
  Timer? _shakeResetTimer;
  Timer? _cooldownTimer;
  
  DateTime? _lastShakeDetectedTime;

  Function(double magnitude)? onShakeDetected;
  Function()? onSosTriggerDetected;

  /// Start listening for shake events
  Future<void> startListening({
    ShakeSensitivity sensitivity = ShakeSensitivity.medium,
  }) async {
    if (_isListening) return;

    _isListening = true;
    _currentSensitivity = _sensitivityFromLevel(sensitivity);

    debugPrint('📱 Shake detector started (Sensitivity: $sensitivity)');

    _sensorSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        _processAccelerometerData(event);
      },
      onError: (error) {
        debugPrint('❌ Accelerometer error: $error');
        _isListening = false;
      },
    );
  }

  /// Stop listening for shake events
  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;
    await _sensorSubscription?.cancel();
    _sensorSubscription = null;
    _shakeResetTimer?.cancel();
    _cooldownTimer?.cancel();
    _shakeCount = 0;

    debugPrint('🛑 Shake detector stopped');
  }

  /// Process accelerometer data and detect shakes
  void _processAccelerometerData(AccelerometerEvent event) {
    // Calculate total acceleration (Pythagorean theorem)
    final magnitude = _calculateMagnitude(
      event.x,
      event.y,
      event.z,
    );

    // Detect shake if magnitude exceeds threshold
    if (magnitude > _currentSensitivity) {
      _handleShakeDetected(magnitude);
    }
  }

  /// Calculate acceleration magnitude
  double _calculateMagnitude(double x, double y, double z) {
    return (x * x + y * y + z * z);
  }

  /// Handle detected shake event
  void _handleShakeDetected(double magnitude) {
    // Skip if on cooldown
    if (_cooldownTimer?.isActive ?? false) {
      return;
    }

    _lastShakeDetectedTime = DateTime.now();
    _shakeCount++;

    debugPrint('💥 Shake detected: $_shakeCount/$_requiredShakes (magnitude: ${magnitude.toStringAsFixed(2)})');
    onShakeDetected?.call(magnitude);

    // Reset shake counter if window expired
    _shakeResetTimer?.cancel();
    _shakeResetTimer = Timer(_shakeWindow, () {
      debugPrint('⏱️ Shake detection window expired');
      _shakeCount = 0;
    });

    // Trigger SOS if threshold reached
    if (_shakeCount >= _requiredShakes) {
      _triggerSos();
    }
  }

  void _triggerSos() {
    _shakeCount = 0;
    _shakeResetTimer?.cancel();

    // Set cooldown to prevent multiple triggers
    _cooldownTimer = Timer(_cooldownAfterDetection, () {});

    debugPrint('🚨 SOS TRIGGER: Shake sequence detected!');
    onSosTriggerDetected?.call();
  }

  /// Update sensitivity level at runtime
  void setSensitivity(ShakeSensitivity sensitivity) {
    _currentSensitivity = _sensitivityFromLevel(sensitivity);
    debugPrint('📊 Shake sensitivity updated: $sensitivity');
  }

  /// Convert sensitivity enum to threshold value
  double _sensitivityFromLevel(ShakeSensitivity sensitivity) {
    return switch (sensitivity) {
      ShakeSensitivity.low => _sensitivityLow,
      ShakeSensitivity.medium => _sensitivityMedium,
      ShakeSensitivity.high => _sensitivityHigh,
    };
  }

  /// Get current sensitivity level
  ShakeSensitivity getCurrentSensitivity() {
    if (_currentSensitivity == _sensitivityHigh) return ShakeSensitivity.high;
    if (_currentSensitivity == _sensitivityLow) return ShakeSensitivity.low;
    return ShakeSensitivity.medium;
  }

  /// Reset shake counter
  void resetShakeCount() {
    _shakeCount = 0;
    _shakeResetTimer?.cancel();
  }

  /// Check if listening
  bool isListening() => _isListening;

  /// Check if on cooldown
  bool isOnCooldown() => _cooldownTimer?.isActive ?? false;

  /// Cleanup resources
  void dispose() {
    stopListening();
  }
}

/// Shake sensitivity levels
enum ShakeSensitivity {
  low,      // Gentle shakes only (threshold: 20.0)
  medium,   // Normal detection (threshold: 15.0)
  high,     // Most sensitive (threshold: 10.0)
}
