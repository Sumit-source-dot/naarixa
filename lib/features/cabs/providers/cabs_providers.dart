/// Riverpod providers for cab booking and ride tracking
/// Manages state for drivers, rides, locations, and safety alerts

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver_model.dart';
import '../models/ride_model.dart';
import '../services/cab_service.dart';
import '../services/location_service.dart';
import '../services/ride_service.dart';

// ============ Service Providers ============

/// Supabase client provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Location service provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Cab service provider
final cabServiceProvider = Provider<CabService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final cabService = CabService();
  cabService.initialize(supabase);
  return cabService;
});

/// Ride service provider
final rideServiceProvider = Provider<RideService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final rideService = RideService();
  rideService.initialize(supabase);
  return rideService;
});

// ============ Location Providers ============

/// Current user location provider
final currentLocationProvider = FutureProvider<Position>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getCurrentLocation();
});

/// User location stream provider
final userLocationStreamProvider = StreamProvider<Position>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getLocationStream(
    intervalSeconds: 5,
    distanceFilterMeters: 10,
  );
});

// ============ Driver Providers ============

/// Nearby drivers provider
final nearbyDriversProvider = FutureProvider.family<List<Driver>, (double, double)>((ref, location) async {
  final cabService = ref.watch(cabServiceProvider);
  final (userLat, userLng) = location;
  return cabService.getNearbyDrivers(
    userLat: userLat,
    userLng: userLng,
    radiusKm: 5.0,
  );
});

/// Nearest driver provider
final nearestDriverProvider = FutureProvider.family<Driver?, (double, double)>((ref, location) async {
  final cabService = ref.watch(cabServiceProvider);
  final (userLat, userLng) = location;
  return cabService.getNearestDriver(
    userLat: userLat,
    userLng: userLng,
  );
});

/// Selected driver provider (state)
final selectedDriverProvider = StateProvider<Driver?>((ref) => null);

/// Driver location stream provider
final driverLocationStreamProvider =
    StreamProvider.family<Driver, String>((ref, driverId) {
  final cabService = ref.watch(cabServiceProvider);
  return cabService.getDriverLocationStream(driverId);
});

// ============ Ride Providers ============

/// Current ride provider (state)
final currentRideProvider = StateProvider<Ride?>((ref) => null);

/// Ride details provider
final rideDetailsProvider = FutureProvider.family<Ride, String>((ref, rideId) async {
  final rideService = ref.watch(rideServiceProvider);
  return rideService.getRide(rideId);
});

/// Ride stream provider (real-time updates)
final rideStreamProvider = StreamProvider.family<Ride, String>((ref, rideId) {
  final rideService = ref.watch(rideServiceProvider);
  return rideService.getRideStream(rideId);
});

/// User active rides provider
final userActiveRidesProvider = FutureProvider.family<List<Ride>, String>((ref, userId) async {
  final rideService = ref.watch(rideServiceProvider);
  return rideService.getUserActiveRides(userId);
});

// ============ Safety Alerts Providers ============

/// Ride safety alerts provider
final rideSafetyAlertsProvider = FutureProvider.family<List<SafetyAlert>, String>((ref, rideId) async {
  final rideService = ref.watch(rideServiceProvider);
  return rideService.getRideAlerts(rideId);
});

/// Ride alerts stream provider (real-time)
final rideAlertsStreamProvider =
    StreamProvider.family<SafetyAlert, String>((ref, rideId) {
  final rideService = ref.watch(rideServiceProvider);
  return rideService.getRideAlertsStream(rideId);
});

/// Current safety alert provider (state)
final currentSafetyAlertProvider = StateProvider<SafetyAlert?>((ref) => null);

// ============ Loading State Providers ============

/// Ride booking loading provider
final bookingLoadingProvider = StateProvider<bool>((ref) => false);

/// Ride completion loading provider
final completionLoadingProvider = StateProvider<bool>((ref) => false);

// ============ Safety Monitoring Providers ============

/// Route deviation detector provider
final routeDeviationProvider =
    StateProvider<bool>((ref) => false);

/// Delay detection provider
final delayDetectionProvider =
    StateProvider<bool>((ref) => false);

/// Safety monitoring provider for a ride
final safetyMonitoringProvider =
    StreamProvider.family<SafetyStatus, String>((ref, rideId) async* {
  final rideService = ref.watch(rideServiceProvider);
  
  try {
    final alerts = rideService.getRideAlertsStream(rideId);
    await for (final alert in alerts) {
      yield SafetyStatus(
        hasAlert: true,
        lastAlert: alert,
        alertType: alert.alertType,
      );
    }
  } catch (e) {
    yield SafetyStatus(
      hasAlert: false,
      error: e.toString(),
    );
  }
});

// ============ Models ============

/// Safety status model
class SafetyStatus {
  final bool hasAlert;
  final SafetyAlert? lastAlert;
  final AlertType? alertType;
  final String? error;

  SafetyStatus({
    required this.hasAlert,
    this.lastAlert,
    this.alertType,
    this.error,
  });
}
