import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, List<AppNotification>>(
  NotificationsController.new,
);

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsControllerProvider);
  return notifications.maybeWhen(
    data: (items) => items.where((item) => !item.isRead).length,
    orElse: () => 0,
  );
});

class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  static const String _tableName = 'app_notifications';

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<List<AppNotification>> build() => _fetchNotifications();

  Future<List<AppNotification>> _fetchNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }

    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchNotifications);
  }

  Future<void> addNotification({
    required String title,
    required String body,
    String? bookingId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be signed in to create notifications.');
    }

    await _supabase.from(_tableName).insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'booking_id': bookingId,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });

    await refresh();
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}