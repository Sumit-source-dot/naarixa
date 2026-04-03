import 'package:flutter/material.dart';

class DeviationMonitoringScreen extends StatelessWidget {
  const DeviationMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deviation Monitoring')),
      body: const Center(child: Text('Deviation detection workflow boilerplate.')),
    );
  }
}