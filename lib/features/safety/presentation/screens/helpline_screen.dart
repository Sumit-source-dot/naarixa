import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelplineScreen extends StatelessWidget {
  const HelplineScreen({super.key});

  static const List<_HelplineEntry> _helplines = [
    _HelplineEntry(label: 'Women Helpline', number: '1091', note: '24x7'),
    _HelplineEntry(label: 'Emergency', number: '112', note: 'National emergency'),
    _HelplineEntry(label: 'Police', number: '100', note: 'Immediate police help'),
    _HelplineEntry(label: 'Ambulance', number: '108', note: 'Medical emergency'),
    _HelplineEntry(label: 'Domestic Abuse', number: '181', note: 'Women in distress'),
    _HelplineEntry(label: 'Cyber Crime', number: '1930', note: 'Financial fraud'),
    _HelplineEntry(label: 'Child Helpline', number: '1098', note: 'Children in need'),
    _HelplineEntry(label: 'Railway Helpline', number: '139', note: 'Railway safety'),
  ];

  Future<void> _callNumber(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    final canLaunch = await canLaunchUrl(uri);
    if (!canLaunch) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calling is not supported on this device.')),
      );
      return;
    }
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('All Helplines (India)')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _helplines.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final entry = _helplines[index];
          return Card(
            elevation: 0,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.call, color: theme.colorScheme.primary),
              ),
              title: Text(entry.label, style: theme.textTheme.titleMedium),
              subtitle: Text('${entry.number} · ${entry.note}'),
              trailing: IconButton(
                icon: const Icon(Icons.phone_in_talk_outlined),
                onPressed: () => _callNumber(context, entry.number),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HelplineEntry {
  const _HelplineEntry({required this.label, required this.number, required this.note});

  final String label;
  final String number;
  final String note;
}
