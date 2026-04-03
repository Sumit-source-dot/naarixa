import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_controller.dart';

final userRoleProvider = FutureProvider<String>((ref) async {
  final auth = AuthController();
  final profile = await auth.getUserProfile();
  return auth.getRoleFromProfile(profile) ?? 'renter';
});
