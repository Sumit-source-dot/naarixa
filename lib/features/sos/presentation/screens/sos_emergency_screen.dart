import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/sos_controller.dart';

class SosEmergencyScreen extends StatefulWidget {
  const SosEmergencyScreen({super.key});

  @override
  State<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

class _SosEmergencyScreenState extends State<SosEmergencyScreen> {
  final SosController _controller = SosController();
  bool _sosActive = false;
  dynamic _activeSosId;
  bool _isBusy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSos() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
    });

    try {
      if (_sosActive && _activeSosId != null) {
        await _controller.stopSOS(sosId: _activeSosId);
        if (!mounted) return;
        setState(() {
          _sosActive = false;
          _activeSosId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🛑 SOS stopped')),
        );
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first to send SOS.')),
        );
        return;
      }

      final sosId = await _controller.triggerSOS(userId: user.id);
      if (!mounted) return;
      setState(() {
        _sosActive = true;
        _activeSosId = sosId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ SOS Sent! Alert ID: $sosId')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SOS failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('SOS / Emergency')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency help is one tap away.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Trigger SOS to share your live location with trusted responders. Stop SOS once you are safe.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colorScheme.error.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.sos_rounded, color: colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _sosActive
                          ? 'SOS is active. Live tracking is running.'
                          : 'SOS is currently inactive.',
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sosActive ? colorScheme.primary : colorScheme.error,
                  foregroundColor: _sosActive ? colorScheme.onPrimary : colorScheme.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isBusy ? null : _handleSos,
                icon: Icon(_sosActive ? Icons.stop_circle_outlined : Icons.sos),
                label: Text(_sosActive ? 'Stop SOS' : 'Trigger SOS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


