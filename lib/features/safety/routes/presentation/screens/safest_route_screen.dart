import 'package:flutter/material.dart';

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Safety Tips")),
      body: const Center(
        child: Text('''1. Share your live location before travel
2. Keep emergency numbers on speed dial
3. Use well-lit routes at night
4. Verify cab details before boarding
5. Trust your instincts
6. Keep your phone charged
7. Know nearby police/help points''', textAlign: TextAlign.center),
      ),
    );
  }
}
