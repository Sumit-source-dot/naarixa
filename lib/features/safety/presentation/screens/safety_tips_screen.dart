import 'package:flutter/material.dart';

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({super.key});

  static const List<String> _tips = [
    'Share your live location with a trusted contact before travel.',
    'Keep emergency numbers on speed dial and save ICE contacts.',
    'Use well-lit routes and avoid isolated shortcuts at night.',
    'Confirm cab details and share trip status with family or friends.',
    'Trust your instincts and leave if a situation feels unsafe.',
    'Keep phone charged and carry a small power bank when possible.',
    'Know the nearest police station or help point in your area.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Safety Tips')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Card(
            elevation: 0,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(Icons.lightbulb_outline, color: theme.colorScheme.onSecondaryContainer),
              ),
              title: Text('Tip ${index + 1}', style: theme.textTheme.titleMedium),
              subtitle: Text(_tips[index]),
            ),
          );
        },
      ),
    );
  }
}
