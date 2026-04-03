/// Ride service for managing ride operations
/// Handles ride creation, tracking, updates, and safety monitoring

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/ride_model.dart';
import 'location_service.dart';

class RideService {
  static final RideService _instance = RideService._internal();

  late final SupabaseClient _supabase;
  final _locationService = LocationService();

  RideService._internal();

  factory RideService() {
    return _instance;
  }

  /// Initialize RideService with Supabase client
  void initialize(SupabaseClient supabase) {
    _supabase = supabase;
  }

  /// Book a new ride
  /// Creates ride entry in Supabase and assigns driver
  Future<Ride> bookRide({
    required String userId,
    required String driverId,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropLat,
    required double dropLng,
    required String dropAddress,
  }) async {
    try {
      final rideId = const Uuid().v4();
      final now = DateTime.now();

      // Calculate distance and estimated duration
      final distance = LocationService.calculateDistance(
        pickupLat,
        pickupLng,
        dropLat,
        dropLng,
      );

      // Estimate time (assuming average speed of 40 km/h in city)
      final estimatedMinutes = ((distance / 40) * 60).toInt();

      // Estimate fare (assuming base fare + per km rate)
      const double baseFare = 50.0;
      const double perKmRate = 15.0;
      final estimatedFare = baseFare + (distance * perKmRate);

      // Create ride record in Supabase
      await _supabase.from('rides').insert({
        'id': rideId,
        'user_id': userId,
        'driver_id': driverId,
        'pickup_address': pickupAddress,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'drop_address': dropAddress,
        'drop_lat': dropLat,
        'drop_lng': dropLng,
        'status': 'pending',
        'estimated_fare': estimatedFare,
        'actual_fare': 0.0,
        'estimated_duration_minutes': estimatedMinutes,
        'actual_duration_minutes': 0,
        'distance_km': distance,
        'created_at': now.toIso8601String(),
      });

      // Set driver as unavailable
      await _supabase.from('drivers').update({'is_available': false}).eq('id', driverId);

      return Ride(
        id: rideId,
        userId: userId,
        driverId: driverId,
        pickupAddress: pickupAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropAddress: dropAddress,
        dropLat: dropLat,
        dropLng: dropLng,
        status: RideStatus.pending,
        estimatedFare: estimatedFare,
        estimatedDurationMinutes: estimatedMinutes,
        createdAt: now,
        distanceKm: distance,
      );
    } catch (e) {
      throw Exception('Error booking ride: $e');
    }
  }

  /// Get ride by ID
  Future<Ride> getRide(String rideId) async {
    try {
      final response = await _supabase
          .from('rides')
          .select()
          .eq('id', rideId)
          .single();

      return Ride.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error fetching ride: $e');
    }
  }

  /// Get user's active rides
  Future<List<Ride>> getUserActiveRides(String userId) async {
    try {
      final response = await _supabase
          .from('rides')
          .select()
          .eq('user_id', userId)
          .inFilter('status', ['pending', 'accepted', 'arriving', 'ongoing'])
          .order('created_at', ascending: false);

      return (response as List)
          .map((ride) => Ride.fromJson(ride as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching active rides: $e');
    }
  }

  /// Update ride status
  Future<void> updateRideStatus({
    required String rideId,
    required RideStatus status,
  }) async {
    try {
      final now = DateTime.now();
      final updates = {
        'status': status.toString().split('.').last,
        'updated_at': now.toIso8601String(),
      };

      if (status == RideStatus.ongoing) {
        updates['started_at'] = now.toIso8601String();
      } else if (status == RideStatus.completed) {
        updates['completed_at'] = now.toIso8601String();
      }

      await _supabase.from('rides').update(updates).eq('id', rideId);
    } catch (e) {
      throw Exception('Error updating ride status: $e');
    }
  }

  /// Stream of ride updates (real-time)
  Stream<Ride> getRideStream(String rideId) {
    return _supabase
        .from('rides')
        .stream(primaryKey: ['id'])
        .eq('id', rideId)
        .map((list) => list.isNotEmpty
            ? Ride.fromJson(list.first as Map<String, dynamic>)
            : throw Exception('Ride not found'))
        .handleError((error) => throw Exception('Ride stream error: $error'));
  }

  /// Cancel ride and make driver available
  Future<void> cancelRide(String rideId, {String? reason}) async {
    try {
      // Get ride details first
      final ride = await getRide(rideId);

      // Update ride status
      await updateRideStatus(rideId: rideId, status: RideStatus.cancelled);

      // Make driver available
      await _supabase
          .from('drivers')
          .update({'is_available': true}).eq('id', ride.driverId);
    } catch (e) {
      throw Exception('Error cancelling ride: $e');
    }
  }

  /// Complete ride with final fare calculation
  Future<void> completeRide({
    required String rideId,
    required double actualDistance,
    required int actualDurationMinutes,
  }) async {
    try {
      // Calculate actual fare
      const double baseFare = 50.0;
      const double perKmRate = 15.0;
      const double perMinuteRate = 1.0;

      final actualFare = baseFare + (actualDistance * perKmRate) + (actualDurationMinutes * perMinuteRate);

      // Get ride to make driver available
      final ride = await getRide(rideId);

      // Update ride
      await _supabase.from('rides').update({
        'status': 'completed',
        'actual_fare': actualFare,
        'actual_duration_minutes': actualDurationMinutes,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', rideId);

      // Make driver available
      await _supabase
          .from('drivers')
          .update({'is_available': true}).eq('id', ride.driverId);
    } catch (e) {
      throw Exception('Error completing ride: $e');
    }
  }

  /// Create safety alert for a ride
  /// Used when route deviation, delay, or suspicious behavior detected
  Future<SafetyAlert> createSafetyAlert({
    required String rideId,
    required AlertType alertType,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final alertId = const Uuid().v4();
      final now = DateTime.now();

      await _supabase.from('alerts').insert({
        'id': alertId,
        'ride_id': rideId,
        'alert_type': alertType.toString().split('.').last,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'detected_at': now.toIso8601String(),
        'is_resolved': false,
      });

      return SafetyAlert(
        id: alertId,
        rideId: rideId,
        alertType: alertType,
        description: description,
        detectedAt: now,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      throw Exception('Error creating safety alert: $e');
    }
  }

  /// Get alerts for a specific ride
  Future<List<SafetyAlert>> getRideAlerts(String rideId) async {
    try {
      final response = await _supabase
          .from('alerts')
          .select()
          .eq('ride_id', rideId)
          .order('detected_at', ascending: false);

      return (response as List)
          .map((alert) => SafetyAlert.fromJson(alert as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching ride alerts: $e');
    }
  }

  /// Stream of ride alerts (real-time)
  Stream<SafetyAlert> getRideAlertsStream(String rideId) {
    return _supabase
        .from('alerts')
        .stream(primaryKey: ['id'])
        .eq('ride_id', rideId)
        .map((list) => list.isNotEmpty
            ? SafetyAlert.fromJson(list.first as Map<String, dynamic>)
            : throw Exception('No alerts found'))
        .handleError((error) => throw Exception('Alerts stream error: $error'));
  }

  /// Mark alert as resolved
  Future<void> resolveAlert({
    required String alertId,
    String? resolution,
  }) async {
    try {
      await _supabase.from('alerts').update({
        'is_resolved': true,
        'resolution': resolution,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', alertId);
    } catch (e) {
      throw Exception('Error resolving alert: $e');
    }
  }
}
