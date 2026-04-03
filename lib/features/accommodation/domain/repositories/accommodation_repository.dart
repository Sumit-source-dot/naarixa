import '../entities/accommodation.dart';

abstract class AccommodationRepository {
  Future<List<Accommodation>> fetchVerifiedAccommodations();
}