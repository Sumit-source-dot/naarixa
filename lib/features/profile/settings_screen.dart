import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _sosAutoShare = true;
  bool _locationHighAccuracy = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Safety Preferences', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _pushNotifications,
            onChanged: (value) => setState(() => _pushNotifications = value),
            title: const Text('Push notifications'),
            subtitle: const Text('Receive safety alerts and SOS updates.'),
          ),
          SwitchListTile(
            value: _sosAutoShare,
            onChanged: (value) => setState(() => _sosAutoShare = value),
            title: const Text('Auto-share SOS status'),
            subtitle: const Text('Notify trusted contacts when SOS is active.'),
          ),
          SwitchListTile(
            value: _locationHighAccuracy,
            onChanged: (value) => setState(() => _locationHighAccuracy = value),
            title: const Text('High accuracy location'),
            subtitle: const Text('Improve live tracking precision.'),
          ),
          const SizedBox(height: 24),
          Text('Account', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Privacy controls'),
            subtitle: const Text('Manage visibility and data sharing.'),
          ),
        ],
      ),
    );
  }
}
