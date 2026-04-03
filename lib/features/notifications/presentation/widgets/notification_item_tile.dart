import 'package:flutter/material.dart';

class NotificationItemTile extends StatelessWidget {
  const NotificationItemTile({
    required this.title,
    required this.body,
    required this.time,
    super.key,
  });

  final String title;
  final String body;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.notifications_active_outlined),
        title: Text(title),
        subtitle: Text(body),
        trailing: Text(time),
      ),
    );
  }
}