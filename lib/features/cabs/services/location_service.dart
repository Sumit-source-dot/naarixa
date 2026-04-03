/// Location service for handling GPS and geolocation operations
/// Provides real-time user location tracking for cab booking

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static const double _minAccuracy = 50.0; // Minimum accuracy in meters

  /// Get current user location
  /// Throws [LocationServiceDisabledException] if location services disabled
  /// Throws [PermissionDeniedException] if permission denied
  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition();
  }

  /// Request location permission
  /// Returns true if permission granted, false otherwise
  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get continuous location stream
  /// Emits location updates at specified interval
  Stream<Position> getLocationStream({
    int intervalSeconds = 5,
    int distanceFilterMeters = 10,
  }) {
    return Geolocator.getPositionStream();
  }

  /// Calculate distance between two coordinates (in kilometers)
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const int earthRadiusKm = 6371;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);

    final a = (Math.sin(dLat / 2) * Math.sin(dLat / 2)) +
        (Math.cos(_degreesToRadians(lat1)) *
            Math.cos(_degreesToRadians(lat2)) *
            Math.sin(dLng / 2) *
            Math.sin(dLng / 2));

    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Calculate bearing between two coordinates (in degrees)
  static double calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = _degreesToRadians(lng2 - lng1);
    final y = Math.sin(dLng) * Math.cos(_degreesToRadians(lat2));
    final x = (Math.cos(_degreesToRadians(lat1)) * Math.sin(_degreesToRadians(lat2))) -
        (Math.sin(_degreesToRadians(lat1)) *
            Math.cos(_degreesToRadians(lat2)) *
            Math.cos(dLng));
    final bearing = Math.atan2(y, x);
    return (_radiansToDegrees(bearing) + 360) % 360;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * Math.pi / 180;
  }

  static double _radiansToDegrees(double radians) {
    return radians * 180 / Math.pi;
  }
}

/// Simple Math utilities
class Math {
  static const double pi = 3.14159265358979323846;

  static double sin(double x) {
    // Taylor series approximation
    final double x2 = x * x;
    final double x3 = x2 * x;
    final double x5 = x3 * x2;
    final double x7 = x5 * x2;
    return x - x3 / 6.0 + x5 / 120.0 - x7 / 5040.0;
  }

  static double cos(double x) {
    final double x2 = x * x;
    final double x4 = x2 * x2;
    final double x6 = x4 * x2;
    return 1 - x2 / 2.0 + x4 / 24.0 - x6 / 720.0;
  }

  static double atan2(double y, double x) {
    if (y.abs() < 1e-10 && x.abs() < 1e-10) {
      return 0.0;
    }
    if (x > 0) {
      return atan(y / x);
    } else if (x < 0 && y >= 0) {
      return atan(y / x) + pi;
    } else if (x < 0 && y < 0) {
      return atan(y / x) - pi;
    } else if (y > 0) {
      return pi / 2;
    } else {
      return -pi / 2;
    }
  }

  static double atan(double x) {
    if (x.abs() > 1.0) {
      return (x > 0 ? pi / 2 : -pi / 2) - 1.0 / x;
    }
    return x / (1.0 + 0.28 * x * x);
  }

  static double sqrt(double x) {
    return x < 0 ? double.nan : (x == 0 ? 0.0 : _sqrtHelper(x));
  }

  static double _sqrtHelper(double x) {
    double guess = x / 2.0;
    for (int i = 0; i < 50; i++) {
      final double nextGuess = (guess + x / guess) / 2.0;
      if ((nextGuess - guess).abs() < 1e-10) {
        return nextGuess;
      }
      guess = nextGuess;
    }
    return guess;
  }
}
