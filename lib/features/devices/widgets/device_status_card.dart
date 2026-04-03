import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';

class DeviceStatusCard extends StatelessWidget {
  const DeviceStatusCard({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Text(name, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
