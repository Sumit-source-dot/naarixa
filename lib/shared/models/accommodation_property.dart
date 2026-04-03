class AccommodationProperty {
  const AccommodationProperty({
    required this.id,
    required this.name,
    required this.priceLabel,
    required this.location,
    required this.city,
    required this.type,
    required this.imageUrl,
    required this.safetyRating,
    required this.isVerified,
  });

  final String id;
  final String name;
  final String priceLabel;
  final String location;
  final String city;
  final String type;
  final String imageUrl;
  final double safetyRating;
  final bool isVerified;
}