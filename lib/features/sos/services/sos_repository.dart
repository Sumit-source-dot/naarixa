import 'package:supabase_flutter/supabase_flutter.dart';

class SOSRepository {
  final SupabaseClient _client = Supabase.instance.client;
  bool? _liveTrackingHasStatus;
  bool? _liveTrackingHasUserId;

  /// Checks if SOS tables exist in Supabase
  Future<Map<String, bool>> verifyTablesExist() async {
    try {
      final sosExists = await _tableExists('sos_alerts');
      final trackingExists = await _tableExists('live_tracking');
      return {
        'sos_alerts': sosExists,
        'live_tracking': trackingExists,
      };
    } catch (e) {
      print('❌ Error verifying tables: $e');
      return {'sos_alerts': false, 'live_tracking': false};
    }
  }

  /// Check if a table exists
  Future<bool> _tableExists(String tableName) async {
    try {
      await _client.from(tableName).count();
      print('✅ Table "$tableName" exists');
      return true;
    } catch (e) {
      print('❌ Table "$tableName" does not exist: $e');
      return false;
    }
  }

  /// Insert SOS alert with detailed error logging
  Future<dynamic> insertSOSAlert({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    print('📍 Inserting SOS alert - User: $userId, Lat: $latitude, Lng: $longitude');

    if (userId.isEmpty) {
      throw Exception('User ID is empty');
    }

    final attempts = <Map<String, dynamic>>[
      {
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'status': 'active',
        'risk_level': 'low',
      },
      {
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'status': 'active',
      },
      {
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'risk_level': 'low',
      },
      {
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
      },
    ];

    PostgrestException? lastError;

    for (final payload in attempts) {
      try {
        print('📤 Sending SOS payload: $payload');
        final response = await _client
            .from('sos_alerts')
            .insert(payload)
            .select('id')
            .single();

        final sosId = response['id'];
        if (sosId == null) {
          throw Exception('Response did not contain ID');
        }

        print('✅ SOS alert created with ID: $sosId');
        return sosId;
      } on PostgrestException catch (e) {
        lastError = e;
        print('⚠️ SOS insert attempt failed');
        print('   Code: ${e.code}');
        print('   Message: ${e.message}');
        print('   Details: ${e.details}');
        print('   Hint: ${e.hint}');

        final message = e.message.toLowerCase();
        final retryable = message.contains('status') ||
            message.contains('risk_level') ||
            e.code == '42703' ||
            e.code == 'PGRST204';
        if (!retryable) {
          rethrow;
        }
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    throw Exception('Failed to insert SOS alert');
  }

  /// Insert live tracking point
  Future<void> insertLiveTrackingPoint({
    required dynamic sosId,
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    print('📍 Inserting live tracking - SOS: $sosId, Lat: $latitude, Lng: $longitude');

    final includeUserId = _liveTrackingHasUserId != false;
    final includeStatus = _liveTrackingHasStatus != false;

    final attempts = <Map<String, dynamic>>[];

    if (includeUserId && includeStatus) {
      attempts.add({
        'sos_id': sosId,
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'status': 'active',
      });
    }
    if (includeUserId) {
      attempts.add({
        'sos_id': sosId,
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
      });
    }
    if (includeStatus) {
      attempts.add({
        'sos_id': sosId,
        'latitude': latitude,
        'longitude': longitude,
        'status': 'active',
      });
    }
    attempts.add({
      'sos_id': sosId,
      'latitude': latitude,
      'longitude': longitude,
    });

    PostgrestException? lastError;

    for (final payload in attempts) {
      try {
        print('📤 Sending tracking payload: $payload');
        await _client.from('live_tracking').insert(payload);
        _liveTrackingHasStatus = payload.containsKey('status');
        _liveTrackingHasUserId = payload.containsKey('user_id');
        print('✅ Live tracking point inserted');
        return;
      } on PostgrestException catch (e) {
        lastError = e;
        print('⚠️ Tracking insert attempt failed');
        print('   Code: ${e.code}');
        print('   Message: ${e.message}');
        print('   Details: ${e.details}');
        print('   Hint: ${e.hint}');

        final message = e.message.toLowerCase();
        if (message.contains('status')) {
          _liveTrackingHasStatus = false;
        }
        if (message.contains('user_id')) {
          _liveTrackingHasUserId = false;
        }

        final retryable = message.contains('status') ||
            message.contains('user_id') ||
            e.code == '42703' ||
            e.code == 'PGRST204';
        if (!retryable) {
          rethrow;
        }
      }
    }

    if (lastError != null) {
      throw lastError;
    }
  }

  /// Update SOS alert status
  Future<void> updateSOSStatus({
    required dynamic sosId,
    required String status,
  }) async {
    try {
      print('🔄 Updating SOS $sosId status to: $status');

      await _client.from('sos_alerts').update({'status': status}).eq('id', sosId);

      print('✅ SOS status updated');
    } catch (e) {
      print('❌ Error updating SOS status: $e');
      rethrow;
    }
  }

  /// Update SOS alert risk level
  Future<void> updateSOSRiskLevel({
    required dynamic sosId,
    required String riskLevel,
  }) async {
    try {
      print('⚠️ Updating SOS $sosId risk level to: $riskLevel');

      await _client
          .from('sos_alerts')
          .update({'risk_level': riskLevel})
          .eq('id', sosId);

      print('✅ Risk level updated');
    } catch (e) {
      print('❌ Error updating risk level: $e');
      rethrow;
    }
  }

  /// Get user's SOS alerts
  Future<List<Map<String, dynamic>>> getUserSOSAlerts(String userId) async {
    try {
      final response =
          await _client.from('sos_alerts').select().eq('user_id', userId).order('created_at', ascending: false);

      print('✅ Retrieved ${response.length} SOS alerts for user $userId');
      return response;
    } catch (e) {
      print('❌ Error retrieving SOS alerts: $e');
      rethrow;
    }
  }

  /// Get live tracking for SOS
  Future<List<Map<String, dynamic>>> getLiveTracking(dynamic sosId) async {
    try {
      final response = await _client
          .from('live_tracking')
          .select()
          .eq('sos_id', sosId)
          .order('created_at', ascending: false);

      print('✅ Retrieved ${response.length} tracking points for SOS $sosId');
      return response;
    } catch (e) {
      print('❌ Error retrieving live tracking: $e');
      rethrow;
    }
  }

  /// Get renter's primary phone number from profiles table
  Future<String?> getUserPhoneNumber(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('phone')
          .eq('id', userId)
          .single();

      final phone = response['phone'] as String?;

      if (phone != null && phone.isNotEmpty) {
        print('✅ Renter profile phone found: $phone');
        return phone;
      }

      print('❌ No renter phone found in profiles.phone');
      return null;
    } catch (e) {
      print('❌ Error fetching renter profile phone: $e');
      return null;
    }
  }

  /// Resolve SOS owner and their phone using sos_alerts -> profiles
  Future<Map<String, String>?> getSOSOwnerAndPhone(dynamic sosId) async {
    try {
      final sos = await _client
          .from('sos_alerts')
          .select('user_id')
          .eq('id', sosId)
          .single();

      final userId = sos['user_id']?.toString();
      if (userId == null || userId.isEmpty) {
        print('❌ Could not resolve user_id from sos_alerts for SOS: $sosId');
        return null;
      }

      final phone = await getUserPhoneNumber(userId);
      if (phone == null || phone.isEmpty) {
        print('❌ Could not resolve profile phone for user: $userId');
        return null;
      }

      return {
        'userId': userId,
        'phone': phone,
      };
    } catch (e) {
      print('❌ Error resolving SOS owner phone: $e');
      return null;
    }
  }

  Future<List<String>> getRelativesEmails(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('relatives_emails')
          .eq('id', userId)
          .maybeSingle();

      final raw = response?['relatives_emails'];
      if (raw is List) {
        return raw
            .whereType<String>()
            .map((email) => email.trim())
            .where((email) => email.isNotEmpty)
            .toList();
      }
      return const <String>[];
    } catch (e) {
      print('❌ Error fetching relatives emails: $e');
      return const <String>[];
    }
  }
}
