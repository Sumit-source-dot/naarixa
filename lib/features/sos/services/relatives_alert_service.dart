import 'package:supabase_flutter/supabase_flutter.dart';

class RelativesAlertService {
  RelativesAlertService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _functionName = 'relatives-alert';

  Future<bool> sendAlertEmail({
    required List<String> recipients,
    required String userId,
    required String userName,
    String? userEmail,
    String? userPhone,
    double? latitude,
    double? longitude,
    String? sosId,
    String? emergencyNote,
  }) async {
    if (recipients.isEmpty) return false;

    final payload = <String, dynamic>{
      'recipients': recipients,
      'emails': recipients,
      'user': {
        'id': userId,
        'name': userName,
        'email': userEmail,
        'phone': userPhone,
      },
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'sosId': sosId,
      'emergencyNote': emergencyNote,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      final response = await _client.functions.invoke(
        _functionName,
        body: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['success'] == true;
      }
      if (data is Map) {
        final decoded = Map<String, dynamic>.from(data);
        return decoded['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
