import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelplineScreen extends StatelessWidget {
  const HelplineScreen({super.key});

  final List<Map<String, String>> helplines = const [
    {'name': 'Women Helpline', 'number': '1091'},
    {'name': 'Emergency', 'number': '112'},
    {'name': 'Police', 'number': '100'},
    {'name': 'Ambulance', 'number': '108'},
    {'name': 'Domestic Abuse', 'number': '181'},
    {'name': 'Cyber Crime', 'number': '1930'},
    {'name': 'Child Helpline', 'number': '1098'},
    {'name': 'Railway Helpline', 'number': '139'},
  ];

  Future<void> callNumber(String number) async {
    final Uri uri = Uri.parse('tel:$number');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Helplines')),
      body: ListView.builder(
        itemCount: helplines.length,
        itemBuilder: (context, index) {
          final item = helplines[index];
          return ListTile(
            title: Text(item['name']!),
            subtitle: Text(item['number']!),
            onTap: () => callNumber(item['number']!),
          );
        },
      ),
    );
  }
}
