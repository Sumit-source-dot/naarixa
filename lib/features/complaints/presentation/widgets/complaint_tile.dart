import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ComplaintTile extends StatelessWidget {
  const ComplaintTile({
    required this.title,
    required this.priority,
    required this.status,
    required this.createdAt,
    super.key,
  });

  final String title;
  final String priority;
  final String status;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = DateFormat('dd MMM, hh:mm a').format(createdAt);
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text('Priority: $priority · Status: $status · $timeLabel'),
        trailing: Icon(Icons.report_outlined, color: theme.colorScheme.primary),
      ),
    );
  }
}