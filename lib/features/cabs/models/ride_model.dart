/// Ride model for cab booking system
/// Contains information about a ride: start location, destination, driver, etc.

class Ride {
  final String id;
  final String userId;
  final String driverId;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropAddress;
  final double dropLat;
  final double dropLng;
  final RideStatus status;
  final double estimatedFare;
  final double actualFare;
  final int estimatedDurationMinutes;
  final int actualDurationMinutes;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<LatLng> routePolyline;
  final double distanceKm;
  final SafetyAlert? safetyAlert;

  const Ride({
    required this.id,
    required this.userId,
    required this.driverId,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropAddress,
    required this.dropLat,
    required this.dropLng,
    required this.status,
    required this.estimatedFare,
    this.actualFare = 0.0,
    required this.estimatedDurationMinutes,
    this.actualDurationMinutes = 0,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.routePolyline = const [],
    this.distanceKm = 0.0,
    this.safetyAlert,
  });

  /// Convert Ride instance to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'driver_id': driverId,
      'pickup_address': pickupAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'drop_address': dropAddress,
      'drop_lat': dropLat,
      'drop_lng': dropLng,
      'status': status.toString().split('.').last,
      'estimated_fare': estimatedFare,
      'actual_fare': actualFare,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'actual_duration_minutes': actualDurationMinutes,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'distance_km': distanceKm,
    };
  }

  /// Create Ride instance from Supabase JSON
  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      driverId: json['driver_id'] as String,
      pickupAddress: json['pickup_address'] as String,
      pickupLat: (json['pickup_lat'] as num).toDouble(),
      pickupLng: (json['pickup_lng'] as num).toDouble(),
      dropAddress: json['drop_address'] as String,
      dropLat: (json['drop_lat'] as num).toDouble(),
      dropLng: (json['drop_lng'] as num).toDouble(),
      status: RideStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => RideStatus.pending,
      ),
      estimatedFare: (json['estimated_fare'] as num).toDouble(),
      actualFare: (json['actual_fare'] as num?)?.toDouble() ?? 0.0,
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int,
      actualDurationMinutes: (json['actual_duration_minutes'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Create a copy of Ride with modified properties
  Ride copyWith({
    String? id,
    String? userId,
    String? driverId,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    String? dropAddress,
    double? dropLat,
    double? dropLng,
    RideStatus? status,
    double? estimatedFare,
    double? actualFare,
    int? estimatedDurationMinutes,
    int? actualDurationMinutes,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    List<LatLng>? routePolyline,
    double? distanceKm,
    SafetyAlert? safetyAlert,
  }) {
    return Ride(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      driverId: driverId ?? this.driverId,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropAddress: dropAddress ?? this.dropAddress,
      dropLat: dropLat ?? this.dropLat,
      dropLng: dropLng ?? this.dropLng,
      status: status ?? this.status,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      actualFare: actualFare ?? this.actualFare,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      routePolyline: routePolyline ?? this.routePolyline,
      distanceKm: distanceKm ?? this.distanceKm,
      safetyAlert: safetyAlert ?? this.safetyAlert,
    );
  }

  /// Check if ride is currently active
  bool get isActive => status == RideStatus.accepted || status == RideStatus.ongoing;

  /// Check if ride has been completed
  bool get isCompleted => status == RideStatus.completed;

  /// Get elapsed time in minutes
  int getElapsedMinutes() {
    if (startedAt == null) return 0;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt!).inMinutes;
  }
}

/// Ride status enum
enum RideStatus {
  pending, // Waiting for driver acceptance
  accepted, // Driver accepted the ride
  arriving, // Driver is arriving at pickup location
  ongoing, // Ride is in progress
  completed, // Ride completed
  cancelled, // Ride was cancelled
}

/// Safety Alert model for tracking anomalies during rides
class SafetyAlert {
  final String id;
  final String rideId;
  final AlertType alertType;
  final String description;
  final DateTime detectedAt;
  final double latitude;
  final double longitude;
  final bool isResolved;
  final String? resolution;

  const SafetyAlert({
    required this.id,
    required this.rideId,
    required this.alertType,
    required this.description,
    required this.detectedAt,
    required this.latitude,
    required this.longitude,
    this.isResolved = false,
    this.resolution,
  });

  /// Convert SafetyAlert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ride_id': rideId,
      'alert_type': alertType.toString().split('.').last,
      'description': description,
      'detected_at': detectedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'is_resolved': isResolved,
      'resolution': resolution,
    };
  }

  /// Create SafetyAlert from JSON
  factory SafetyAlert.fromJson(Map<String, dynamic> json) {
    return SafetyAlert(
      id: json['id'] as String,
      rideId: json['ride_id'] as String,
      alertType: AlertType.values.firstWhere(
        (e) => e.toString().split('.').last == json['alert_type'],
        orElse: () => AlertType.routeDeviation,
      ),
      description: json['description'] as String,
      detectedAt: DateTime.parse(json['detected_at'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isResolved: json['is_resolved'] as bool,
      resolution: json['resolution'] as String?,
    );
  }
}

/// Types of safety alerts
enum AlertType {
  routeDeviation, // Driver deviating from expected route
  delayDetected, // Ride taking longer than expected
  abnormalSpeeding, // Unusual acceleration/deceleration
  unexpectedStop, // Unplanned stop detected
  driverBehavior, // Suspicious driver behavior
}

/// Simple LatLng model for polyline points
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng({required this.latitude, required this.longitude});

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  factory LatLng.fromJson(Map<String, dynamic> json) => LatLng(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
}
