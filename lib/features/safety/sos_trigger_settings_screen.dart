import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/sos_trigger_coordinator.dart';
import '../../core/services/shake_detector.dart';

/// Settings screen for SOS trigger system configuration
/// 
/// Allows users to:
/// - Enable/disable volume button SOS
/// - Enable/disable shake detection
/// - Adjust shake sensitivity
/// - View SOS system status
class SosTriggerSettingsScreen extends ConsumerStatefulWidget {
  const SosTriggerSettingsScreen({super.key});

  @override
  ConsumerState<SosTriggerSettingsScreen> createState() =>
      _SosTriggerSettingsScreenState();
}

class _SosTriggerSettingsScreenState extends ConsumerState<SosTriggerSettingsScreen> {
  late SosTriggerCoordinator _coordinator;

  bool _volumeButtonEnabled = true;
  bool _shakeDetectionEnabled = true;
  bool _hiddenGestureEnabled = true;
  ShakeSensitivity _shakeSensitivity = ShakeSensitivity.medium;

  @override
  void initState() {
    super.initState();
    _initializeCoordinator();
  }

  void _initializeCoordinator() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      _coordinator = ref.read(sosTriggerCoordinatorProvider(currentUser.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Trigger Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Emergency SOS Triggers',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure emergency activation methods. These allow SOS to be triggered even when your hands are busy.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Volume Button SOS
          _buildSectionTitle('Volume Button SOS', context),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Volume Button Activation'),
                  subtitle: const Text('Press volume up 3 times in 2 seconds'),
                  value: _volumeButtonEnabled,
                  onChanged: (enabled) async {
                    setState(() => _volumeButtonEnabled = enabled);
                    await _coordinator.setVolumeButtonEnabled(enabled);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✓ Works when app is minimized',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                      ),
                      Text(
                        '✓ Non-invasive - doesn\'t affect volume control',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                      ),
                      Text(
                        '✓ 10 second cooldown between triggers',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Shake Detection SOS
          _buildSectionTitle('Shake Detection SOS', context),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Shake Activation'),
                  subtitle: const Text('Shake device 2 times rapidly'),
                  value: _shakeDetectionEnabled,
                  onChanged: (enabled) async {
                    setState(() => _shakeDetectionEnabled = enabled);
                    await _coordinator.setShakeDetectionEnabled(enabled);
                  },
                ),
                if (_shakeDetectionEnabled)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sensitivity',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              _shakeSensitivity.toString().split('.').last.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _shakeSensitivityToValue(_shakeSensitivity),
                          min: 0,
                          max: 2,
                          divisions: 2,
                          label: _shakeSensitivity
                              .toString()
                              .split('.')
                              .last
                              .toUpperCase(),
                          onChanged: (value) {
                            setState(() {
                              _shakeSensitivity =
                                  _valueToShakeSensitivity(value);
                            });
                            _coordinator.setShakeSensitivity(
                                _shakeSensitivity);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildSensitivityLegend(context),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✓ Uses device accelerometer',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                      ),
                      Text(
                        '✓ Detects strong movement patterns',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                      ),
                      Text(
                        '✓ Battery optimized',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Hidden Gesture
          _buildSectionTitle('Hidden Gesture', context),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('2-Finger Tap Activation'),
                  subtitle: const Text('Tap anywhere with 2 fingers quietly'),
                  value: _hiddenGestureEnabled,
                  onChanged: (enabled) {
                    setState(() => _hiddenGestureEnabled = enabled);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✓ Silent activation - no alerts/notifications',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                      ),
                      Text(
                        '✓ Unnoticeable gesture',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                      ),
                      Text(
                        '✓ Perfect for discreet activation',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Main SOS Button Section
          _buildSectionTitle('Primary SOS Method', context),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your main SOS button (on main screen) remains your primary emergency activation method.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Advanced triggers provide additional ways to activate SOS without using your hands.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Safety Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Safety Features',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• 10-second cooldown between SOS triggers\n'
                        '• Prevents accidental and repeated triggers\n'
                        '• Always background-safe for privacy',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSensitivityLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Less Sensitive',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Colors.grey),
        ),
        Text(
          'More Sensitive',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  double _shakeSensitivityToValue(ShakeSensitivity sensitivity) {
    return switch (sensitivity) {
      ShakeSensitivity.low => 0,
      ShakeSensitivity.medium => 1,
      ShakeSensitivity.high => 2,
    };
  }

  ShakeSensitivity _valueToShakeSensitivity(double value) {
    return switch (value.toInt()) {
      0 => ShakeSensitivity.low,
      1 => ShakeSensitivity.medium,
      2 => ShakeSensitivity.high,
      _ => ShakeSensitivity.medium,
    };
  }
}
