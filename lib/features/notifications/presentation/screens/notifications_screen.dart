import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/notifications_provider.dart';
import '../widgets/notification_item_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications and Alerts')),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Failed to load notifications: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No notifications yet.'),
            );
          }

          return RefreshIndicator(
            onRefresh:
                () => ref.read(notificationsControllerProvider.notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return NotificationItemTile(
                  onDelete: () async {
                    try {
                      await ref
                          .read(notificationsControllerProvider.notifier)
                          .deleteNotification(item.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification deleted')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete notification: $e'),
                        ),
                      );
                    }
                  },
                  title: item.title,
                  body: item.body,
                  time: DateFormat('dd MMM, hh:mm a').format(item.createdAt),
                );
              },
            ),
          );
        },
      ),
    );
  }
}