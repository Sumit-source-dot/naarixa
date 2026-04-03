import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Detects volume button presses and triggers SOS when:
/// - Volume UP button pressed 3 times within 2 seconds
/// 
/// Features:
/// - Non-invasive background listening
/// - Automatic reset after timeout
/// - Configurable detection parameters
/// - Works in background when service is active
class VolumeButtonListener {
  static final VolumeButtonListener _instance = VolumeButtonListener._internal();

  factory VolumeButtonListener() => _instance;

  VolumeButtonListener._internal() {
    _initializeChannels();
  }

  static const platform = MethodChannel('com.naarixa.app/volume_listener');

  // Configuration
  static const int _requiredPresses = 3;
  static const Duration _detectionWindow = Duration(seconds: 2);

  // State
  int _volumeUpPressCount = 0;
  Timer? _resetTimer;
  bool _isListening = false;

  Function(int pressCount)? onVolumePressDetected;
  Function()? onSosTriggerDetected;

  void _initializeChannels() {
    platform.setMethodCallHandler(_handleMethodCall);
  }

  /// Start listening for volume button presses
  Future<void> startListening() async {
    if (_isListening) return;

    try {
      _isListening = true;
      debugPrint('🔊 Volume button listener started');

      await platform.invokeMethod('startVolumeListener');
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to start volume listener: ${e.message}');
      _isListening = false;
      rethrow;
    }
  }

  /// Stop listening for volume button presses
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      _isListening = false;
      _resetTimer?.cancel();
      _volumeUpPressCount = 0;

      await platform.invokeMethod('stopVolumeListener');
      debugPrint('🔇 Volume button listener stopped');
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to stop volume listener: ${e.message}');
      rethrow;
    }
  }

  /// Handle incoming method calls from native code
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onVolumeUpPressed':
          await _onVolumeUpPressed();
          break;
        case 'onVolumeDownPressed':
          await _onVolumeDownPressed();
          break;
        default:
          debugPrint('⚠️ Unknown volume listener method: ${call.method}');
      }
    } catch (e) {
      debugPrint('❌ Error in volume listener handler: $e');
    }
  }

  Future<void> _onVolumeUpPressed() async {
    // Reset counter if window has expired
    if (_resetTimer != null && !_resetTimer!.isActive) {
      _volumeUpPressCount = 0;
    }

    // Increment press count
    _volumeUpPressCount++;
    debugPrint('📱 Volume UP pressed: $_volumeUpPressCount/$_requiredPresses');

    onVolumePressDetected?.call(_volumeUpPressCount);

    // Set/reset the detection window timer
    _resetTimer?.cancel();
    _resetTimer = Timer(_detectionWindow, () {
      debugPrint('⏱️ Volume press detection window expired');
      _volumeUpPressCount = 0;
    });

    // Check if SOS threshold reached
    if (_volumeUpPressCount >= _requiredPresses) {
      _triggerSos();
    }
  }

  Future<void> _onVolumeDownPressed() async {
    // Volume down cancels the sequence
    if (_volumeUpPressCount > 0) {
      debugPrint('❌ Volume DOWN pressed - resetting sequence');
      _volumeUpPressCount = 0;
      _resetTimer?.cancel();
    }
  }

  void _triggerSos() {
    _volumeUpPressCount = 0;
    _resetTimer?.cancel();

    debugPrint('🚨 SOS TRIGGER: Volume button sequence detected!');
    onSosTriggerDetected?.call();
  }

  /// Get current press count (for testing/UI)
  int getPressCount() => _volumeUpPressCount;

  /// Reset press count
  void resetPressCount() {
    _volumeUpPressCount = 0;
    _resetTimer?.cancel();
  }

  /// Check if listening
  bool isListening() => _isListening;

  /// Cleanup resources
  void dispose() {
    _resetTimer?.cancel();
    _isListening = false;
  }
}
