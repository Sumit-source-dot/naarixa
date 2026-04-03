/// Cab service for managing cab/driver operations
/// Handles fetching nearby drivers, driver information, and driver status updates

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver_model.dart';

class CabService {
  static final CabService _instance = CabService._internal();

  static const String _driversTable = 'cab_drivers';
  static const String _bookingsTable = 'cab_bookings';

  late final SupabaseClient _supabase;

  CabService._internal();

  factory CabService() {
    return _instance;
  }

  /// Initialize CabService with Supabase client
  void initialize(SupabaseClient supabase) {
    _supabase = supabase;
  }

  /// Get all available drivers
  Future<List<Driver>> getAvailableDrivers() async {
    try {
      final response = await _supabase
          .from(_driversTable)
          .select()
          .eq('is_available', true)
          .order('rating', ascending: false);

      return (response as List)
          .map((driver) => Driver.fromJson(driver as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching available drivers: $e');
    }
  }

  /// Find nearby drivers within specified radius
  /// [userLat] - User latitude
  /// [userLng] - User longitude
  /// [radiusKm] - Search radius in kilometers (default: 5 km)
  /// Returns list of drivers within radius, sorted by distance
  Future<List<Driver>> getNearbyDrivers({
    required double userLat,
    required double userLng,
    double radiusKm = 5.0,
    int maxDrivers = 5,
  }) async {
    try {
      // Fetch all available drivers from Supabase
      final drivers = await getAvailableDrivers();

      // Filter and sort by distance
      final nearbyDrivers = drivers
          .where((driver) {
            final distance = _calculateDistance(
              userLat,
              userLng,
              driver.latitude,
              driver.longitude,
            );
            return distance <= radiusKm;
          })
          .toList();

      // Sort by distance (nearest first)
      nearbyDrivers.sort((a, b) {
        final distA = _calculateDistance(userLat, userLng, a.latitude, a.longitude);
        final distB = _calculateDistance(userLat, userLng, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });

      return nearbyDrivers.take(maxDrivers).toList(growable: false);
    } catch (e) {
      throw Exception('Error fetching nearby drivers: $e');
    }
  }

  /// Get single driver by ID
  Future<Driver> getDriver(String driverId) async {
    try {
      final response = await _supabase
          .from(_driversTable)
          .select()
          .eq('id', driverId)
          .single();

      return Driver.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching driver: $e');
    }
  }

  /// Update driver's current location
  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _supabase.from(_driversTable).update({
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', driverId);
    } catch (e) {
      throw Exception('Error updating driver location: $e');
    }
  }

  /// Update driver availability status
  Future<void> setDriverAvailability({
    required String driverId,
    required bool isAvailable,
  }) async {
    try {
      await _supabase.from(_driversTable).update({
        'is_available': isAvailable,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', driverId);
    } catch (e) {
      throw Exception('Error updating driver availability: $e');
    }
  }

  /// Get nearest driver to user location
  Future<Driver?> getNearestDriver({
    required double userLat,
    required double userLng,
  }) async {
    try {
      final drivers = await getNearbyDrivers(
        userLat: userLat,
        userLng: userLng,
        radiusKm: 10.0,
      );
      return drivers.isNotEmpty ? drivers.first : null;
    } catch (e) {
      throw Exception('Error getting nearest driver: $e');
    }
  }

  /// Stream of driver location updates (real-time)
  Stream<Driver> getDriverLocationStream(String driverId) {
    return _supabase
        .from(_driversTable)
        .stream(primaryKey: ['id'])
        .eq('id', driverId)
        .map((list) => list.isNotEmpty
          ? Driver.fromJson(list.first)
            : throw Exception('Driver not found'))
        .handleError((error) => throw Exception('Driver stream error: $error'));
  }

  /// Create a new booking for selected driver.
  Future<String> createBooking({
    required String userId,
    required String driverId,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    String status = 'booked',
  }) async {
    try {
      final response = await _supabase
          .from(_bookingsTable)
          .insert({
            'user_id': userId,
            'driver_id': driverId,
            'pickup_lat': pickupLat,
            'pickup_lng': pickupLng,
            'pickup_address': pickupAddress,
            'status': status,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Error creating booking: $e');
    }
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadiusKm = 6371;

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = (_sin(dLat / 2) * _sin(dLat / 2)) +
        (_cos(_degreesToRadians(lat1)) *
            _cos(_degreesToRadians(lat2)) *
            _sin(dLng / 2) *
            _sin(dLng / 2));

    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * 3.14159265358979323846 / 180;

  double _sin(double x) {
    final double x2 = x * x;
    final double x3 = x2 * x;
    final double x5 = x3 * x2;
    final double x7 = x5 * x2;
    return x - x3 / 6.0 + x5 / 120.0 - x7 / 5040.0;
  }

  double _cos(double x) {
    final double x2 = x * x;
    final double x4 = x2 * x2;
    final double x6 = x4 * x2;
    return 1 - x2 / 2.0 + x4 / 24.0 - x6 / 720.0;
  }

  double _atan2(double y, double x) {
    if (y.abs() < 1e-10 && x.abs() < 1e-10) return 0.0;
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265358979323846;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265358979323846;
    return y > 0 ? 3.14159265358979323846 / 2 : -3.14159265358979323846 / 2;
  }

  double _atan(double x) {
    if (x.abs() > 1.0) {
      return (x > 0 ? 3.14159265358979323846 / 2 : -3.14159265358979323846 / 2) - 1.0 / x;
    }
    return x / (1.0 + 0.28 * x * x);
  }

  double _sqrt(double x) {
    if (x < 0) return double.nan;
    if (x == 0) return 0.0;
    double guess = x / 2.0;
    for (int i = 0; i < 50; i++) {
      final double nextGuess = (guess + x / guess) / 2.0;
      if ((nextGuess - guess).abs() < 1e-10) return nextGuess;
      guess = nextGuess;
    }
    return guess;
  }
}
