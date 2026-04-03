import 'package:flutter/material.dart';

import 'widgets/device_status_card.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [DeviceStatusCard(name: 'Primary Safety Device')],
          ),
        ),
      ),
    );
  }
}
