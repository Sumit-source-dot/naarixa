import 'package:flutter/material.dart';

class AiRoutesScreen extends StatelessWidget {
  const AiRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Safe Routes')),
      body: const Center(child: Text('AI safety scoring and route ranking boilerplate.')),
    );
  }
}