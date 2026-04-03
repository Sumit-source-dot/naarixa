/// Driver model for cab booking system
/// Contains driver information, location, and availability status

class Driver {
  final String id;
  final String name;
  final String phoneNumber;
  final String carModel;
  final String carNumber;
  final String profileImageUrl;
  final double rating;
  final double latitude;
  final double longitude;
  final bool isAvailable;
  final int completedRides;
  final String licenseNumber;

  const Driver({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.carModel,
    required this.carNumber,
    required this.profileImageUrl,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.isAvailable,
    required this.completedRides,
    required this.licenseNumber,
  });

  /// Convert Driver instance to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'car_model': carModel,
      'car_number': carNumber,
      'profile_image_url': profileImageUrl,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
      'is_available': isAvailable,
      'completed_rides': completedRides,
      'license_number': licenseNumber,
    };
  }

  /// Create Driver instance from Supabase JSON
  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      carModel: json['car_model'] as String,
      carNumber: json['car_number'] as String,
      profileImageUrl: json['profile_image_url'] as String,
      rating: (json['rating'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isAvailable: json['is_available'] as bool,
      completedRides: json['completed_rides'] as int,
      licenseNumber: json['license_number'] as String,
    );
  }

  /// Create a copy of Driver with modified properties
  Driver copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? carModel,
    String? carNumber,
    String? profileImageUrl,
    double? rating,
    double? latitude,
    double? longitude,
    bool? isAvailable,
    int? completedRides,
    String? licenseNumber,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      carModel: carModel ?? this.carModel,
      carNumber: carNumber ?? this.carNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rating: rating ?? this.rating,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAvailable: isAvailable ?? this.isAvailable,
      completedRides: completedRides ?? this.completedRides,
      licenseNumber: licenseNumber ?? this.licenseNumber,
    );
  }

  /// Calculate distance to another location (in kilometers)
  /// Uses Haversine formula
  double distanceTo(double lat, double lng) {
    const double earthRadiusKm = 6371;
    final double dLat = _degreesToRadians(lat - latitude);
    final double dLng = _degreesToRadians(lng - longitude);
    final double a = (Math.sin(dLat / 2) * Math.sin(dLat / 2)) +
        (Math.cos(_degreesToRadians(latitude)) *
            Math.cos(_degreesToRadians(lat)) *
            Math.sin(dLng / 2) *
            Math.sin(dLng / 2));
    final double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * Math.pi / 180;
  }
}

// Simple math utilities
class Math {
  static const double pi = 3.14159265358979323846;

  static double sin(double x) => _sin(x);
  static double cos(double x) => _cos(x);
  static double atan2(double y, double x) => _atan2(y, x);
  static double sqrt(double x) => _sqrt(x);

  // Using dart:math instead
  static double _sin(double x) {
    // Using Taylor series approximation
    final double x2 = x * x;
    final double x3 = x2 * x;
    final double x5 = x3 * x2;
    final double x7 = x5 * x2;
    return x - x3 / 6.0 + x5 / 120.0 - x7 / 5040.0;
  }

  static double _cos(double x) {
    final double x2 = x * x;
    final double x4 = x2 * x2;
    final double x6 = x4 * x2;
    return 1 - x2 / 2.0 + x4 / 24.0 - x6 / 720.0;
  }

  static double _atan2(double y, double x) {
    return (y.abs() < 1e-10 && x.abs() < 1e-10)
        ? 0.0
        : (x > 0)
            ? atan(y / x)
            : (x < 0 && y >= 0)
                ? atan(y / x) + pi
                : (x < 0 && y < 0)
                    ? atan(y / x) - pi
                    : (y > 0)
                        ? pi / 2
                        : -pi / 2;
  }

  static double atan(double x) {
    if (x.abs() > 1.0) {
      return (x > 0 ? pi / 2 : -pi / 2) - 1.0 / x;
    }
    return x / (1.0 + 0.28 * x * x);
  }

  static double _sqrt(double x) {
    return x < 0 ? double.nan : (x == 0 ? 0.0 : x.toInt().toDouble());
  }
}
