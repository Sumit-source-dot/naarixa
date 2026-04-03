import 'package:flutter/material.dart';

import '../widgets/hero_section.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            const HeroSection(),
            const SizedBox(height: 20),

            // City Selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("City Selector"),
            ),
            const SizedBox(height: 12),

            // Budget Filter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("Budget Filter"),
            ),
            const SizedBox(height: 12),

            // Safety Rating Filter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("Safety Rating Filter"),
            ),
            const SizedBox(height: 12),

            // Women Reviews
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("Women Reviews"),
            ),
            const SizedBox(height: 12),

            // Verified Only Filter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("Verified Only Filter"),
            ),
            const SizedBox(height: 12),

            // Map View
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text("Map View"),
              ),
            ),
            const SizedBox(height: 12),

            // Safety Score Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[200],
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Text(
                "Safety Score: 88",
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}