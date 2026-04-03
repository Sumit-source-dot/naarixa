import '../../domain/entities/accommodation.dart';
import '../../domain/repositories/accommodation_repository.dart';

class AccommodationRepositoryImpl implements AccommodationRepository {
  @override
  Future<List<Accommodation>> fetchVerifiedAccommodations() async {
    return const [];
  }
}