import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();
  Future<void> signIn(String phone, String password);
  Future<void> signOut();
}