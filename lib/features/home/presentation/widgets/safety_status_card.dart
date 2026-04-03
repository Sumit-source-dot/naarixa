import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SafetyStatusCard extends StatelessWidget {
  const SafetyStatusCard({required this.isSafeZone, super.key});

  final bool isSafeZone;

  @override
  Widget build(BuildContext context) {
    final statusText = isSafeZone ? 'Safe Zone' : 'Risk Zone';
    final statusColor = isSafeZone ? AppColors.success : AppColors.danger;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.shield_rounded, color: statusColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                statusText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}