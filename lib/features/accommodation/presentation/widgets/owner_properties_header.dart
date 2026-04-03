import 'package:flutter/material.dart';

class OwnerPropertiesHeader extends StatelessWidget {
  final int totalProperties;
  final int verifiedProperties;
  final int availableProperties;
  final VoidCallback onAddPressed;

  const OwnerPropertiesHeader({
    super.key,
    required this.totalProperties,
    required this.verifiedProperties,
    required this.availableProperties,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade600,
                Colors.deepPurple.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Properties',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your listings',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  FloatingActionButton.extended(
                    onPressed: onAddPressed,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple.shade600,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Quick stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statCard('Total', totalProperties, Icons.home, Colors.white),
                  _statCard('Verified', verifiedProperties, Icons.verified, Colors.white),
                  _statCard('Available', availableProperties, Icons.check_circle, Colors.white),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: textColor.withOpacity(0.9),
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
        margin: const EdgeInsets.only(right: 8),
      ),
    );
  }
}