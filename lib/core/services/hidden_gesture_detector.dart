import 'dart:async';
import 'package:flutter/material.dart';

/// Detects hidden gesture patterns for SOS activation.
/// 
/// Supported gestures:
/// - 2-finger tap: Quick tap with 2 fingers (silence + activate)
/// 
/// Features:
/// - Detects gesture anywhere on screen without interfering with normal UI
/// - Configurable detection parameters
/// - Debounced to prevent accidental triggers
class HiddenGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onTwoFingerTap;
  
  const HiddenGestureDetector({
    super.key,
    required this.child,
    required this.onTwoFingerTap,
  });

  @override
  State<HiddenGestureDetector> createState() => _HiddenGestureDetectorState();
}

class _HiddenGestureDetectorState extends State<HiddenGestureDetector> {
  // Configuration
  static const int _requiredPointers = 2;
  static const Duration _tapTimeout = Duration(milliseconds: 300);

  // State
  late List<int> _activePointers;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _activePointers = [];
    _tapTimer = null;
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);

    // Check for 2-finger simultaneous touch
    if (_activePointers.length == _requiredPointers) {
      debugPrint('👆 Two-finger gesture detected');
      _initiateGestureDetection();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);

    // Reset if not all fingers are pressed simultaneously
    if (_activePointers.isEmpty) {
      _resetGestureDetection();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
  }

  void _initiateGestureDetection() {
    _tapTimer?.cancel();
    
    _tapTimer = Timer(_tapTimeout, () {
      if (_activePointers.length == _requiredPointers) {
        debugPrint('🚨 SOS TRIGGER: Two-finger tap detected!');
        widget.onTwoFingerTap();
      }
      _resetGestureDetection();
    });
  }

  void _resetGestureDetection() {
    _tapTimer?.cancel();
    _tapTimer = null;
  }
}
