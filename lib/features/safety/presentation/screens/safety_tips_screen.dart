import 'package:flutter/material.dart';

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({super.key});

  final List<String> tips = const [
    'Share your live location before travel.',
    'Keep emergency numbers on speed dial.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety Tips')),
      body: ListView.builder(
        itemCount: tips.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Tip ${index + 1}'),
            subtitle: Text(tips[index]),
          );
        },
      ),
    );
  }
}
