import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/sos_repository.dart';
import '../services/relatives_alert_service.dart';
import '../services/twilio_service.dart';

class SosController {
  final SOSRepository _sosRepository = SOSRepository();
  final TwilioService _twilioService = TwilioService();
  final RelativesAlertService _relativesAlertService = RelativesAlertService();
  StreamSubscription<Position>? _trackingSubscription;

  /// Check if SOS tables exist and are properly configured.
  Future<bool> verifySosSetup() async {
    final tableStatus = await _sosRepository.verifyTablesExist();

    if (!tableStatus['sos_alerts']! || !tableStatus['live_tracking']!) {
      print('❌ SOS tables not found in Supabase!');
      print(
        '📋 Missing tables: ${tableStatus.entries.where((e) => !e.value).map((e) => e.key).join(", ")}',
      );
      print('💡 Please run the SQL schema in Supabase dashboard:');
      print('   File: sos/SOS_TRACKING_SCHEMA.sql');
      return false;
    }

    print('✅ All SOS tables configured correctly');
    return true;
  }

  Future<String> triggerSOS({required String userId}) async {
    print('🚨 SOS Pressed - Initiating emergency alert');

    final setupValid = await verifySosSetup();
    if (!setupValid) {
      throw StateError('❌ SOS tables not configured. Run SQL schema in Supabase.');
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ Location disabled');
      throw StateError('Location service is disabled');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ Permission denied');
        throw StateError('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Permission permanently denied');
      throw StateError('Location permission denied forever');
    }

    try {
      print('📍 Getting current location...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final lat = position.latitude;
      final lng = position.longitude;

      print('📍 Location retrieved: $lat, $lng');

      final sosId = await _sosRepository.insertSOSAlert(
        userId: userId,
        latitude: lat,
        longitude: lng,
      );

      print('✅ SOS created with ID: $sosId');

      await _sosRepository.insertLiveTrackingPoint(
        sosId: sosId,
        userId: userId,
        latitude: lat,
        longitude: lng,
      );

      startLiveTracking(sosId: sosId, userId: userId);

      unawaited(
        _sendRelativesAlert(
          userId: userId,
          sosId: sosId.toString(),
          latitude: lat,
          longitude: lng,
          emergencyNote: 'SOS triggered in Naarixa.',
        ),
      );

      Future.delayed(const Duration(seconds: 30), () async {
        try {
          await _sosRepository.updateSOSRiskLevel(sosId: sosId, riskLevel: 'high');
          print('⚠️ Risk level updated to HIGH');

          _triggerHighRiskNotificationsForUser(sosId: sosId, userId: userId);
        } catch (e) {
          print('⚠️ Risk level update failed: $e');
        }
      });

      return sosId.toString();
    } catch (e) {
      print('❌ Error triggering SOS: $e');
      rethrow;
    }
  }

  Future<dynamic?> triggerEmergencyFlow(
    BuildContext context, {
    required bool Function() isMounted,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please login first to send SOS.')),
      );
      return null;
    }

    final setup = await _sosRepository.verifyTablesExist();
    if (setup['sos_alerts'] != true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'SOS setup incomplete in Supabase. sos_alerts table missing.',
          ),
        ),
      );
      return null;
    }

    final hasLiveTracking = setup['live_tracking'] == true;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Location service is disabled.')),
        );
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return null;
      }

      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final sosId = await _sosRepository.insertSOSAlert(
        userId: user.id,
        latitude: current.latitude,
        longitude: current.longitude,
      );

      unawaited(
        _sendRelativesAlert(
          userId: user.id,
          sosId: sosId.toString(),
          latitude: current.latitude,
          longitude: current.longitude,
          emergencyNote: 'SOS triggered in Naarixa.',
        ),
      );

      if (hasLiveTracking) {
        try {
          await _sosRepository.insertLiveTrackingPoint(
            sosId: sosId,
            userId: user.id,
            latitude: current.latitude,
            longitude: current.longitude,
          );

          await _trackingSubscription?.cancel();
          _trackingSubscription = Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((position) async {
            try {
              await _sosRepository.insertLiveTrackingPoint(
                sosId: sosId,
                userId: user.id,
                latitude: position.latitude,
                longitude: position.longitude,
              );
            } catch (_) {
              // Keep stream alive even if one insert fails.
            }
          });
        } catch (e) {
          debugPrint('Live tracking failed but SOS saved: $e');
        }
      }

      Future.delayed(const Duration(seconds: 30), () async {
        try {
          await _sosRepository.updateSOSRiskLevel(sosId: sosId, riskLevel: 'high');
          await _triggerHighRiskNotificationsForSosId(
            sosId: sosId,
            context: context,
            isMounted: isMounted,
          );
        } catch (e) {
          debugPrint('High-risk escalation failed: $e');
        }
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            hasLiveTracking
                ? 'Emergency alert sent. SOS ID: $sosId'
                : 'Emergency alert saved (tracking disabled). SOS ID: $sosId',
          ),
        ),
      );
      return sosId;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('SOS failed: $e')),
      );
      return null;
    }
  }

  Future<void> stopSOS({required dynamic sosId}) async {
    stopTracking();
    await _sosRepository.updateSOSStatus(sosId: sosId, status: 'resolved');
  }

  void startLiveTracking({required dynamic sosId, required String userId}) {
    print('🚀 Live tracking started for SOS: $sosId');

    _trackingSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen((position) async {
      try {
        await _sosRepository.insertLiveTrackingPoint(
          sosId: sosId,
          userId: userId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        print('📍 Location update: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('❌ Failed to record tracking point: $e');
      }
    });
  }

  void stopTracking() {
    _trackingSubscription?.cancel();
    _trackingSubscription = null;
    print('🛑 Tracking stopped');
  }

  void dispose() {
    stopTracking();
  }

  Future<void> _triggerHighRiskNotificationsForUser({
    required dynamic sosId,
    required String userId,
  }) async {
    try {
      print('📱 Fetching user phone number for SMS...');

      final phoneNumber = await _sosRepository.getUserPhoneNumber(userId);

      if (phoneNumber == null || phoneNumber.isEmpty) {
        print('❌ No phone number available for user');
        return;
      }

      print('📞 Sending SMS to: $phoneNumber');

      final smsSent = await _twilioService.sendSafetyCheckSMS(
        toPhoneNumber: phoneNumber,
        sosId: sosId,
        userId: userId,
      );

      if (!smsSent) {
        final smsReason = _twilioService.lastErrorMessage ?? 'Unknown SMS failure';
        if (_twilioService.isSmsDailyLimitError) {
          print('❌ Failed to send SMS. Twilio daily limit reached. Reason: $smsReason');
        } else {
          print('❌ Failed to send SMS. Reason: $smsReason');
        }

        print('📞 SMS failed, triggering immediate emergency call fallback...');
        final callSent = await _twilioService.makeEmergencyCall(
          toPhoneNumber: phoneNumber,
          sosId: sosId,
          userId: userId,
        );

        if (!callSent) {
          print('❌ Fallback emergency call also failed');
        } else {
          print('✅ Fallback emergency call initiated');
        }
        return;
      }

      print('✅ Safety check SMS sent successfully');

      Future.delayed(const Duration(minutes: 2), () async {
        try {
          final hasSafeResponse = await _twilioService.hasUserRespondedSafe(sosId);

          if (!hasSafeResponse) {
            print('📞 No response to SMS. Initiating emergency call...');

            await _twilioService.makeEmergencyCall(
              toPhoneNumber: phoneNumber,
              sosId: sosId,
              userId: userId,
            );

            print('✅ Emergency call initiated');
          } else {
            print('✅ User confirmed they are safe');
          }
        } catch (e) {
          print('❌ Error in follow-up call: $e');
        }
      });
    } catch (e) {
      print('❌ Error triggering high-risk notifications: $e');
    }
  }

  Future<void> _triggerHighRiskNotificationsForSosId({
    required dynamic sosId,
    required BuildContext context,
    required bool Function() isMounted,
  }) async {
    try {
      final ownerAndPhone = await _sosRepository.getSOSOwnerAndPhone(sosId);
      if (ownerAndPhone == null) {
        debugPrint('No renter phone found for SMS.');
        if (isMounted()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile phone missing. High-risk SMS not sent.')),
          );
        }
        return;
      }

      final ownerUserId = ownerAndPhone['userId']!;
      final phoneNumber = ownerAndPhone['phone']!;

      final smsSent = await _twilioService.sendSafetyCheckSMS(
        toPhoneNumber: phoneNumber,
        sosId: sosId,
        userId: ownerUserId,
      );

      if (!smsSent) {
        final errorReason = _twilioService.lastErrorMessage ?? 'Unknown SMS failure';
        final hitDailySmsLimit = _twilioService.isSmsDailyLimitError;
        debugPrint('High-risk SMS failed. Reason: $errorReason');

        final callSent = await _twilioService.makeEmergencyCall(
          toPhoneNumber: phoneNumber,
          sosId: sosId,
          userId: ownerUserId,
        );

        if (isMounted()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                callSent
                    ? (hitDailySmsLimit
                        ? 'Twilio daily SMS limit reached. Emergency call triggered instead.'
                        : 'High-risk SMS failed. Emergency call triggered instead.')
                    : (hitDailySmsLimit
                        ? 'Twilio daily SMS limit reached and fallback call also failed.'
                        : 'High-risk SMS failed and fallback call also failed.'),
              ),
            ),
          );
        }
        return;
      }

      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('High-risk SMS sent to $phoneNumber')),
        );
      }

      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply YES/NO to SMS. NO reply will trigger emergency call.'),
          ),
        );
      }

      unawaited(
        Future.delayed(const Duration(minutes: 2), () async {
          try {
            final hasSafeResponse = await _twilioService.hasUserRespondedSafe(sosId);

            if (!hasSafeResponse) {
              debugPrint('No response to high-risk SMS. Initiating emergency call...');

              final callSent = await _twilioService.makeEmergencyCall(
                toPhoneNumber: phoneNumber,
                sosId: sosId,
                userId: ownerUserId,
              );

              if (callSent) {
                debugPrint('Emergency follow-up call initiated successfully.');
                if (isMounted()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No SMS reply detected. Emergency call initiated.')),
                  );
                }
              } else {
                debugPrint('Emergency follow-up call failed.');
                if (isMounted()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No SMS reply detected, but emergency call failed.')),
                  );
                }
              }
            } else {
              debugPrint('User responded SAFE to high-risk SMS. Skipping call.');
            }
          } catch (e) {
            debugPrint('Error in delayed high-risk call flow: $e');
          }
        }),
      );
    } catch (e) {
      debugPrint('High-risk notification flow failed: $e');
      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('High-risk notification failed: $e')),
        );
      }
    }
  }

  Future<void> _sendRelativesAlert({
    required String userId,
    String? sosId,
    double? latitude,
    double? longitude,
    String? emergencyNote,
  }) async {
    final relatives = await _sosRepository.getRelativesEmails(userId);
    if (relatives.isEmpty) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    final displayName = _resolveDisplayName(user);
    final phone = await _sosRepository.getUserPhoneNumber(userId);

    await _relativesAlertService.sendAlertEmail(
      recipients: relatives,
      userId: userId,
      userName: displayName,
      userEmail: user?.email,
      userPhone: phone,
      latitude: latitude,
      longitude: longitude,
      sosId: sosId,
      emergencyNote: emergencyNote,
    );
  }

  String _resolveDisplayName(User? user) {
    if (user == null) return 'Naarixa User';
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final rawName = (metadata['full_name'] as String?)?.trim() ??
        (metadata['name'] as String?)?.trim() ??
        '';
    if (rawName.isNotEmpty) return rawName;
    final email = (user.email ?? '').trim();
    if (email.isEmpty) return 'Naarixa User';
    return email.split('@').first.replaceAll('.', ' ').replaceAll('_', ' ').trim();
  }
}
