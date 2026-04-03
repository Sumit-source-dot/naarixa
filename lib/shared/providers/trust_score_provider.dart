import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Calculates trust score (0-100) based on verification completion
class TrustScoreStatus {
  final int score; // 0-100
  final int completedItems;
  final int totalItems;
  final bool emailVerified;
  final bool phoneVerified;
  final bool emergencyPhoneVerified;
  final bool idVerified;

  const TrustScoreStatus({
    required this.score,
    required this.completedItems,
    required this.totalItems,
    required this.emailVerified,
    required this.phoneVerified,
    required this.emergencyPhoneVerified,
    required this.idVerified,
  });

  bool get isFullyVerified => completedItems == totalItems;
  double get progress => completedItems / totalItems;
}

/// Provider that calculates trust score dynamically
final trustScoreProvider = FutureProvider<TrustScoreStatus>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    return const TrustScoreStatus(
      score: 0,
      completedItems: 0,
      totalItems: 4,
      emailVerified: false,
      phoneVerified: false,
      emergencyPhoneVerified: false,
      idVerified: false,
    );
  }

  final emailVerified = user.emailConfirmedAt != null;
  var phoneVerified = user.phoneConfirmedAt != null;

  var emergencyPhoneVerified = false;
  var idVerified = false;

  try {
    final profile = await supabase
        .from('profiles')
        .select('emergency_contact_verified, phone_verified')
        .eq('id', user.id)
        .maybeSingle();

    final profilePhoneVerified = profile?['phone_verified'];
    if (profilePhoneVerified is bool) {
      phoneVerified = profilePhoneVerified;
    }
    emergencyPhoneVerified = profile?['emergency_contact_verified'] == true;
  } catch (_) {
    emergencyPhoneVerified = false;
  }

  try {
    final owners = await supabase
        .from('owner_verifications')
        .select()
        .eq('owner_id', user.id)
        .maybeSingle();

    final explicitVerified = owners?['id_verified'] == true;
    final status = (owners?['status']?.toString().toLowerCase() ?? '');
    idVerified = explicitVerified || status == 'approved' || status == 'verified';
  } catch (_) {
    idVerified = false;
  }

  // Calculate score: each item = 25 points
  int completedItems = 0;
  if (emailVerified) completedItems++;
  if (phoneVerified) completedItems++;
  if (emergencyPhoneVerified) completedItems++;
  if (idVerified) completedItems++;

  final score = (completedItems * 25);

  return TrustScoreStatus(
    score: score,
    completedItems: completedItems,
    totalItems: 4,
    emailVerified: emailVerified,
    phoneVerified: phoneVerified,
    emergencyPhoneVerified: emergencyPhoneVerified,
    idVerified: idVerified,
  );
});
