import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ComplaintTile extends StatelessWidget {
  const ComplaintTile({
    required this.onDelete,
    required this.title,
    required this.priority,
    required this.status,
    required this.createdAt,
    super.key,
  });

  final VoidCallback onDelete;
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.report_outlined, color: theme.colorScheme.primary),
            IconButton(
              tooltip: 'Delete complaint',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}