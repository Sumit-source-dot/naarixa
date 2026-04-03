import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';

class SafetyOverviewCard extends StatelessWidget {
  const SafetyOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        children: [
          Icon(Icons.verified_user, color: AppColors.safe),
          SizedBox(width: 10),
          Expanded(
            child: Text('Area status looks safe based on latest reports'),
          ),
        ],
      ),
    );
  }
}
