import '../../domain/entities/accommodation.dart';

class AccommodationModel extends Accommodation {
  const AccommodationModel({required super.id, required super.name, required super.city, required super.rating});

  factory AccommodationModel.fromJson(Map<String, dynamic> json) {
    return AccommodationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      rating: (json['rating'] as num).toDouble(),
    );
  }
}