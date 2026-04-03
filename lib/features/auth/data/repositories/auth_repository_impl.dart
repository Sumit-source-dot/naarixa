import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<AppUser?> getCurrentUser() async {
    return null;
  }

  @override
  Future<void> signIn(String phone, String password) async {}

  @override
  Future<void> signOut() async {}
} //hello suno
