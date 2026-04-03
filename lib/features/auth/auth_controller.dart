import '../../core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController {
  bool get isLoggedIn => SupabaseService.client.auth.currentSession != null;

  bool _hasText(dynamic value) {
    return value is String && value.trim().isNotEmpty;
  }

  String? getRoleFromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    final role = profile['role'];
    if (role is String && role.trim().isNotEmpty) {
      final normalized = role.trim().toLowerCase();
      if (normalized == 'owner' || normalized == 'renter') {
        return normalized;
      }
    }
    return null;
  }

  bool isProfileComplete(Map<String, dynamic>? profile) {
    if (profile == null) return false;

    final completeFlag = profile['is_profile_complete'];
    if (completeFlag is bool) return completeFlag;

    final role = getRoleFromProfile(profile);
    if (role == null) return false;

    final hasBase = _hasText(profile['full_name']) && _hasText(profile['phone']);

    if (role == 'renter') {
      return hasBase && _hasText(profile['city']);
    }
    if (role == 'owner') {
      return hasBase;
    }
    return false;
  }

  bool _isMissingTableError(PostgrestException error) {
    final code = (error.code ?? '').toUpperCase();
    final message = error.message.toLowerCase();
    return code == 'PGRST205' ||
        message.contains('could not find the table') ||
        message.contains('relation') && message.contains('does not exist');
  }

  User _requireAuthenticatedUser() {
    final user = SupabaseService.client.auth.currentUser ??
        SupabaseService.client.auth.currentSession?.user;
    if (user == null) {
      throw const AuthException('Session expired. Please login again.');
    }
    return user;
  }

  Future<void> login({required String email, required String password}) async {
    await SupabaseService.client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
  }) async {
    final response = await SupabaseService.client.auth.signUp(
      email: email.trim(),
      password: password,
    );

    final user = response.user;

    // When email confirmation is enabled, session can be null after sign-up.
    // In that case we create the profile at first successful login.
    if (user != null && response.session != null) {
      try {
        await _upsertDefaultUserProfile(user);
      } on PostgrestException {
        // Auth account is already created; profile can be retried after login.
      }
    }

    return response;
  }

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }

  Future<void> ensureUserProfile() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    await _upsertDefaultUserProfile(user);
  }

  Future<void> _upsertDefaultUserProfile(User user) async {
    try {
      await SupabaseService.client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
      }, onConflict: 'id');
    } on PostgrestException catch (error) {
      if (!_isMissingTableError(error)) rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return null;

    try {
      final profile = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return profile;
    } on PostgrestException catch (error) {
      if (!_isMissingTableError(error)) rethrow;
      return null;
    }
  }

  Future<void> updateRole({required String role}) async {
    final user = _requireAuthenticatedUser();

    try {
      await SupabaseService.client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'role': role,
      }, onConflict: 'id');
    } on PostgrestException catch (error) {
      if (!_isMissingTableError(error)) rethrow;
      throw const AuthException(
        'Profile tables not configured. Please run Supabase schema SQL first.',
      );
    }
  }

  Future<void> createRenterProfile({
    required String fullName,
    required String phone,
    required String city,
  }) async {
    final user = _requireAuthenticatedUser();
    var saved = false;

    try {
      await SupabaseService.client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'role': 'renter',
        'full_name': fullName,
        'phone': phone,
        'city': city,
      }, onConflict: 'id');
      saved = true;
    } on PostgrestException catch (error) {
      if (!_isMissingTableError(error)) rethrow;
    }

    if (!saved) {
      throw const AuthException(
        'Profiles table not configured. Please run Supabase schema SQL first.',
      );
    }
  }

  Future<void> createOwnerProfile({
    required String fullName,
    required String phone,
  }) async {
    final user = _requireAuthenticatedUser();
    var saved = false;

    try {
      await SupabaseService.client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'role': 'owner',
        'full_name': fullName,
        'phone': phone,
      }, onConflict: 'id');
      saved = true;
    } on PostgrestException catch (error) {
      if (!_isMissingTableError(error)) rethrow;
    }

    if (!saved) {
      throw const AuthException(
        'Profiles table not configured. Please run Supabase schema SQL first.',
      );
    }
  }

}


