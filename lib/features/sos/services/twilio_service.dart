/// Twilio Service for emergency SMS and calls
/// Uses Supabase Edge Function to avoid CORS issues on web/Chrome

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/env.dart';

class TwilioService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _functionName = 'smooth-function';
  static const String _defaultCountryCode = '+91';
  String? _lastErrorMessage;
  int? _lastStatusCode;
  int? _lastTwilioCode;

  String? get lastErrorMessage => _lastErrorMessage;
  int? get lastStatusCode => _lastStatusCode;
  int? get lastTwilioCode => _lastTwilioCode;

  bool get isSmsDailyLimitError {
    if (_lastTwilioCode == 63038) return true;
    final message = (_lastErrorMessage ?? '').toLowerCase();
    return _lastStatusCode == 429 && message.contains('daily messages limit');
  }

  void _clearLastError() {
    _lastErrorMessage = null;
    _lastStatusCode = null;
    _lastTwilioCode = null;
  }

  int? _parseIntValue(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _captureErrorFromResponse(Map<String, dynamic>? data, {String? fallbackMessage}) {
    final details = data?['details'];
    final twilioFromRoot = data?['twilio'];
    final twilioFromDetails = details is Map ? details['twilio'] : null;

    _lastErrorMessage = (data?['error'] ?? fallbackMessage)?.toString();
    _lastStatusCode = _parseIntValue(data?['statusCode']) ?? _parseIntValue(details is Map ? details['statusCode'] : null);
    _lastTwilioCode =
        _parseIntValue(twilioFromRoot is Map ? twilioFromRoot['code'] : null) ??
        _parseIntValue(twilioFromDetails is Map ? twilioFromDetails['code'] : null);
  }

  String _toE164(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '').trim();
    if (cleaned.isEmpty) return '';
    if (cleaned.startsWith('00')) return '+${cleaned.substring(2)}';
    if (cleaned.startsWith('+')) return cleaned;

    final digits = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '$_defaultCountryCode$digits';
    if (digits.length >= 11 && digits.length <= 15) return '+$digits';
    return cleaned;
  }

  bool _isLikelyE164(String value) => RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(value);

  Future<Map<String, dynamic>?> _invokeTwilioFunction(
    Map<String, dynamic> payload,
  ) async {
    final accessToken = _client.auth.currentSession?.accessToken;
    final headers = <String, String>{
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    try {
      final response = await _client.functions.invoke(
        _functionName,
        headers: headers,
        body: payload,
      );

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }

      return {'success': false, 'error': 'Unexpected function response format'};
    } catch (e) {
      print('⚠️ functions.invoke failed, trying direct HTTP fallback: $e');
      try {
        final url = Uri.parse('${Env.supabaseUrl}/functions/v1/$_functionName');
        final httpHeaders = <String, String>{
          'Content-Type': 'application/json',
          'apikey': Env.supabaseAnonKey,
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        };

        final httpResponse = await http.post(
          url,
          headers: httpHeaders,
          body: jsonEncode(payload),
        );

        final body = httpResponse.body.isEmpty
            ? <String, dynamic>{}
            : (jsonDecode(httpResponse.body) as Map<String, dynamic>);

        if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
          return body;
        }

        return {
          'success': false,
          'error': body['error'] ?? 'HTTP fallback failed',
          'statusCode': httpResponse.statusCode,
          'details': body,
        };
      } catch (fallbackError) {
        return {
          'success': false,
          'error': 'Failed to reach edge function',
          'details': '$fallbackError',
        };
      }
    }
  }

  /// Send SMS asking user if they are safe
  /// Returns true if SMS sent successfully
  Future<bool> sendSafetyCheckSMS({
    required String toPhoneNumber,
    required dynamic sosId,
    required String userId,
  }) async {
    try {
      _clearLastError();
      final toPhoneE164 = _toE164(toPhoneNumber);
      print('📱 Sending safety check SMS to: $toPhoneE164 (raw: $toPhoneNumber)');

      if (toPhoneE164.isEmpty || !_isLikelyE164(toPhoneE164)) {
        _captureErrorFromResponse(
          {'error': 'Invalid recipient phone number format'},
          fallbackMessage: 'Invalid recipient phone number format',
        );
        print('❌ Invalid phone format for SMS. Raw: $toPhoneNumber, Parsed: $toPhoneE164');
        return false;
      }

      const message = 'Are you safe?';

      final data = await _invokeTwilioFunction({
        'action': 'sms',
        'toPhoneNumber': toPhoneE164,
        'message': message,
      });

      final isSuccess = data != null && data['success'] == true;
      if (!isSuccess) {
        _captureErrorFromResponse(data, fallbackMessage: 'Twilio SMS failed');
        print('❌ SMS failed via edge function. Response: $data');
        return false;
      }

      final smsSid = data['sid']?.toString() ?? '';
      print('✅ SMS sent successfully. SID: $smsSid');

      // Log SMS in database
      await _logSMSSent(sosId, userId, toPhoneE164, smsSid);
      return true;
    } catch (e) {
      _captureErrorFromResponse(null, fallbackMessage: e.toString());
      print('❌ Error sending SMS: $e');
      return false;
    }
  }

  /// Make an emergency call to user
  /// Call will prompt user to press 1 for safe or 2 for unsafe
  Future<bool> makeEmergencyCall({
    required String toPhoneNumber,
    required dynamic sosId,
    required String userId,
  }) async {
    try {
      final toPhoneE164 = _toE164(toPhoneNumber);
      print('📞 Making emergency call to: $toPhoneE164 (raw: $toPhoneNumber)');

      if (toPhoneE164.isEmpty || !_isLikelyE164(toPhoneE164)) {
        print('❌ Invalid phone format for call. Raw: $toPhoneNumber, Parsed: $toPhoneE164');
        return false;
      }

      final data = await _invokeTwilioFunction({
        'action': 'call',
        'toPhoneNumber': toPhoneE164,
      });

      final isSuccess = data != null && data['success'] == true;
      if (!isSuccess) {
        print('❌ Call failed via edge function. Response: $data');
        return false;
      }

      final callSid = data['sid']?.toString() ?? '';
      print('✅ Call initiated successfully. SID: $callSid');

      // Log call in database
      await _logCallMade(sosId, userId, toPhoneE164, callSid);
      return true;
    } catch (e) {
      print('❌ Error making call: $e');
      return false;
    }
  }

  /// Log SMS sent to database
  Future<void> _logSMSSent(
    dynamic sosId,
    String userId,
    String phoneNumber,
    String smsSid,
  ) async {
    try {
      await _client.from('sos_notifications').insert({
        'sos_id': sosId,
        'user_id': userId,
        'notification_type': 'sms',
        'phone_number': phoneNumber,
        'message': 'Safety check SMS sent',
        'external_id': smsSid,
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ SMS log saved');
    } catch (e) {
      print('⚠️ Error logging SMS: $e');
    }
  }

  /// Log call made to database
  Future<void> _logCallMade(
    dynamic sosId,
    String userId,
    String phoneNumber,
    String callSid,
  ) async {
    try {
      await _client.from('sos_notifications').insert({
        'sos_id': sosId,
        'user_id': userId,
        'notification_type': 'call',
        'phone_number': phoneNumber,
        'message': 'Emergency call initiated',
        'external_id': callSid,
        'status': 'initiated',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Call log saved');
    } catch (e) {
      print('⚠️ Error logging call: $e');
    }
  }

  /// Check if user responded yes to safety check
  Future<bool> hasUserRespondedSafe(dynamic sosId) async {
    try {
      final response = await _client
          .from('sos_notifications')
          .select('response_status')
          .eq('sos_id', sosId)
          .eq('notification_type', 'sms')
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      return response['response_status'] == 'yes';
    } catch (e) {
      print('⚠️ No response found yet: $e');
      return false;
    }
  }

  /// Update SMS response status (when callback from Twilio comes)
  Future<void> updateSMSResponse(String smsSid, String responseStatus) async {
    try {
      await _client
          .from('sos_notifications')
          .update({'response_status': responseStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('external_id', smsSid);

      print('✅ SMS response updated: $responseStatus');
    } catch (e) {
      print('❌ Error updating SMS response: $e');
    }
  }
}
