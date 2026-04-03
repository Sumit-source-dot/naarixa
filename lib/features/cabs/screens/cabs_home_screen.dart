import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../notifications/presentation/providers/notifications_provider.dart';
import '../models/driver_model.dart';
import '../providers/cabs_providers.dart';
import '../services/location_service.dart';

class CabsHomeScreen extends ConsumerStatefulWidget {
  const CabsHomeScreen({super.key});

  @override
  ConsumerState<CabsHomeScreen> createState() => _CabsHomeScreenState();
}

class _CabsHomeScreenState extends ConsumerState<CabsHomeScreen> {
  static const double _searchRadiusKm = 5;
  static const double _averageCabSpeedKmH = 30;
  static const double _initialMapZoom = 14;
  static const List<List<double>> _demoOffsets = [
    [0.0020, 0.0015],
    [0.0045, -0.0032],
    [-0.0038, 0.0042],
    [-0.0060, -0.0025],
    [0.0065, 0.0055],
  ];

  late MapController _mapController;
  Position? _userPosition;
  LatLng? _initialMapCenter;
  LatLng? _mapCenter;
  double _mapZoom = _initialMapZoom;
  List<Driver> _nearbyDrivers = const [];
  bool _loadingLocation = true;
  bool _loadingDrivers = false;
  bool _bookingInProgress = false;
  bool _isDemoMode = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    setState(() {
      _loadingLocation = true;
      _error = null;
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      final locationEnabled = await locationService.isLocationServiceEnabled();
      if (!locationEnabled) {
        throw Exception(
          'Location services are disabled. Please enable GPS from settings.',
        );
      }

      final hasPermission = await locationService.requestLocationPermission();
      if (!hasPermission) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.deniedForever) {
          throw Exception(
            'Location permission is permanently denied. Open app settings and allow location access.',
          );
        }
        throw Exception(
          'Location permission denied. Allow permission to find cabs.',
        );
      }

      final position = await locationService.getCurrentLocation();
      if (!mounted) return;
      final initialCenter = LatLng(position.latitude, position.longitude);
      setState(() {
        _userPosition = position;
        _initialMapCenter = initialCenter;
        _mapCenter = initialCenter;
        _mapZoom = _initialMapZoom;
        _loadingLocation = false;
      });

      await _loadNearbyDrivers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingLocation = false;
      });
    }
  }

  Future<void> _loadNearbyDrivers() async {
    final position = _userPosition;
    if (position == null) return;

    setState(() {
      _loadingDrivers = true;
      _error = null;
    });

    try {
      debugPrint(
        'Loading drivers from lat: ${position.latitude}, lng: ${position.longitude}',
      );
      final drivers = await ref
          .read(cabServiceProvider)
          .getNearbyDrivers(
            userLat: position.latitude,
            userLng: position.longitude,
            radiusKm: _searchRadiusKm,
            maxDrivers: 5,
          );

      var driversToShow = drivers;
      var demoMode = false;

      if (driversToShow.isEmpty) {
        final availableDrivers = await ref
            .read(cabServiceProvider)
            .getAvailableDrivers();
        driversToShow = _buildDemoDriversAroundUser(position, availableDrivers);
        demoMode = driversToShow.isNotEmpty;
      }

      if (!mounted) return;
      debugPrint(
        'Loaded ${driversToShow.length} drivers (demoMode: $demoMode)',
      );
      setState(() {
        _nearbyDrivers = driversToShow;
        _loadingDrivers = false;
        _isDemoMode = demoMode;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error loading drivers: $e');
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingDrivers = false;
        _isDemoMode = false;
      });
    }
  }

  List<Driver> _buildDemoDriversAroundUser(
    Position userPosition,
    List<Driver> availableDrivers,
  ) {
    if (availableDrivers.isEmpty) return const [];

    final source = availableDrivers.take(5).toList(growable: false);
    return List.generate(source.length, (index) {
      final offset = _demoOffsets[index % _demoOffsets.length];
      return source[index].copyWith(
        latitude: userPosition.latitude + offset[0],
        longitude: userPosition.longitude + offset[1],
      );
    }, growable: false);
  }

  Future<void> _bookRide(
    Driver driver, {
    required String contactName,
    required String contactPhone,
    String notes = '',
  }) async {
    final position = _userPosition;
    if (position == null) return;

    if (_bookingInProgress) return;
    setState(() {
      _bookingInProgress = true;
      _error = null;
    });

    try {
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('You must be signed in to book a ride.');
      }

      final bookingId = await ref
          .read(cabServiceProvider)
          .createBooking(
            userId: userId,
            driverId: driver.id,
            pickupLat: position.latitude,
            pickupLng: position.longitude,
            pickupAddress:
                '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} | Contact: $contactName ($contactPhone)${notes.isEmpty ? '' : ' | Notes: $notes'}',
            status: 'booked',
          );

      await ref
          .read(notificationsControllerProvider.notifier)
          .addNotification(
            title: 'Ride booked successfully',
            body: 'Driver ${driver.name} is on the way. Booking ID: $bookingId',
            bookingId: bookingId,
          );

      if (!mounted) return;
      setState(() {
        _bookingInProgress = false;
      });

      Navigator.pop(context); // Close booking form

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('✅ Ride booked with ${driver.name}!'),
            duration: const Duration(seconds: 3),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bookingInProgress = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: ${_error!}')));
    }
  }

  void _centerOnUser() {
    final target = _initialMapCenter;
    if (target == null) return;
    _mapController.move(target, _initialMapZoom);
    setState(() {
      _mapCenter = target;
      _mapZoom = _initialMapZoom;
    });
  }

  void _zoomBy(double delta) {
    final center = _mapCenter;
    if (center == null) return;
    final nextZoom = (_mapZoom + delta).clamp(5.0, 18.0);
    _mapController.move(center, nextZoom);
    setState(() {
      _mapZoom = nextZoom;
    });
  }

  void _openBookingForm(Driver driver) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final notesController = TextEditingController();
    var formError = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm Booking with ${driver.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Contact Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Pickup Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (formError.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        formError,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _bookingInProgress
                            ? null
                            : () {
                                final name = nameController.text.trim();
                                final phone = phoneController.text.trim();
                                if (name.isEmpty ||
                                    phone.isEmpty ||
                                    phone.length < 8) {
                                  setModalState(() {
                                    formError =
                                        'Enter valid name and contact number.';
                                  });
                                  return;
                                }
                                _bookRide(
                                  driver,
                                  contactName: name,
                                  contactPhone: phone,
                                  notes: notesController.text.trim(),
                                );
                              },
                        icon: _bookingInProgress
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.local_taxi),
                        label: Text(
                          _bookingInProgress ? 'Booking...' : 'Confirm Booking',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      phoneController.dispose();
      notesController.dispose();
    });
  }

  List<Marker> _buildMarkers() {
    final position = _userPosition;
    if (position == null) return [];

    final markers = <Marker>[];

    // User location marker
    markers.add(
      Marker(
        point: LatLng(position.latitude, position.longitude),
        width: 80,
        height: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Driver markers
    for (final driver in _nearbyDrivers) {
      final distanceKm = _distanceKm(driver);
      markers.add(
        Marker(
          point: LatLng(driver.latitude, driver.longitude),
          width: 90,
          height: 90,
          child: GestureDetector(
            onTap: () => _showDriverBottomSheet(driver),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_taxi,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        driver.name.split(' ')[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${distanceKm.toStringAsFixed(2)}km',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _showDriverBottomSheet(Driver driver) {
    final distanceKm = _distanceKm(driver);
    final etaMinutes = _etaMinutes(distanceKm);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              driver.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoTile(label: 'Car', value: driver.carModel),
                _InfoTile(
                  label: 'Distance',
                  value: '${distanceKm.toStringAsFixed(2)}km',
                ),
                _InfoTile(label: 'ETA', value: '$etaMinutes min'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoTile(label: 'Rating', value: '⭐${driver.rating}'),
                _InfoTile(label: 'Plate', value: driver.carNumber),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _bookingInProgress
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        _openBookingForm(driver);
                      },
                icon: _bookingInProgress
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_bookingInProgress ? 'Booking...' : 'Book Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _distanceKm(Driver driver) {
    final position = _userPosition;
    if (position == null) return 0;
    return LocationService.calculateDistance(
      position.latitude,
      position.longitude,
      driver.latitude,
      driver.longitude,
    );
  }

  int _etaMinutes(double distanceKm) {
    final minutes = (distanceKm / _averageCabSpeedKmH) * 60;
    return minutes.ceil().clamp(1, 120);
  }

  @override
  Widget build(BuildContext context) {
    final position = _userPosition;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_taxi, color: Colors.orange),
            SizedBox(width: 8),
            Text('Nearby Cabs'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh drivers',
            onPressed: _loadingLocation || _loadingDrivers
                ? null
                : _loadNearbyDrivers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _loadingLocation
            ? const Center(child: CircularProgressIndicator())
            : _error != null && position == null
            ? _ErrorState(
                message: _error!,
                onRetry: _initialize,
                showLocationSettings: _error!.toLowerCase().contains(
                  'location services are disabled',
                ),
                showAppSettings: _error!.toLowerCase().contains(
                  'permanently denied',
                ),
              )
            : CustomScrollView(
                slivers: [
                  if (_isDemoMode) SliverToBoxAdapter(),
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: position == null
                          ? const SizedBox.shrink()
                          : Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: LatLng(
                                      position.latitude,
                                      position.longitude,
                                    ),
                                    initialZoom: _initialMapZoom,
                                    onPositionChanged: (pos, hasGesture) {
                                      if (pos.center != null &&
                                          pos.zoom != null) {
                                        setState(() {
                                          _mapCenter = pos.center;
                                          _mapZoom = pos.zoom!;
                                        });
                                      }
                                    },
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.naarixa.app',
                                    ),
                                    MarkerLayer(markers: _buildMarkers()),
                                  ],
                                ),
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: Column(
                                    children: [
                                      _MapControlButton(
                                        icon: Icons.add,
                                        tooltip: 'Zoom in',
                                        onPressed: () => _zoomBy(1),
                                      ),
                                      const SizedBox(height: 8),
                                      _MapControlButton(
                                        icon: Icons.remove,
                                        tooltip: 'Zoom out',
                                        onPressed: () => _zoomBy(-1),
                                      ),
                                      const SizedBox(height: 8),
                                      _MapControlButton(
                                        icon: Icons.my_location,
                                        tooltip: 'Reset map view',
                                        onPressed: _centerOnUser,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Text(
                            '${_nearbyDrivers.length} cabs available',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          if (_loadingDrivers)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_nearbyDrivers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(12, 4, 12, 2),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _nearbyDrivers
                              .map(
                                (driver) => Chip(
                                  label: Text(
                                    '${driver.name} • ${_distanceKm(driver).toStringAsFixed(2)}km',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 6)),
                  SliverToBoxAdapter(child: _buildDriverList()),
                ],
              ),
      ),
    );
  }

  Widget _buildDriverList() {
    if (_loadingDrivers) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _nearbyDrivers.isEmpty) {
      return SizedBox(
        height: 280,
        child: _ErrorState(
          message: _error!,
          onRetry: _loadNearbyDrivers,
          showLocationSettings: _error!.toLowerCase().contains(
            'location services are disabled',
          ),
          showAppSettings: _error!.toLowerCase().contains('permanently denied'),
        ),
      );
    }

    if (_nearbyDrivers.isEmpty) {
      return SizedBox(
        height: 280,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_taxi, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                const Text(
                  'No drivers found within 5 km',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try again in a moment',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadNearbyDrivers,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _error!,
              style: TextStyle(color: Colors.orange.shade900),
            ),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          itemCount: _nearbyDrivers.length,
          itemBuilder: (context, index) {
            final driver = _nearbyDrivers[index];
            final distanceKm = _distanceKm(driver);
            final etaMinutes = _etaMinutes(distanceKm);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_taxi, color: Colors.orange),
                ),
                title: Text(
                  driver.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('${driver.carModel} • ${driver.carNumber}'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${driver.rating} • ${distanceKm.toStringAsFixed(2)}km away • ETA: $etaMinutes min',
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: ElevatedButton.icon(
                  onPressed: _bookingInProgress
                      ? null
                      : () => _openBookingForm(driver),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Book'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 20, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    this.showLocationSettings = false,
    this.showAppSettings = false,
  });

  final String message;
  final Future<void> Function() onRetry;
  final bool showLocationSettings;
  final bool showAppSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            if (showLocationSettings) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: Geolocator.openLocationSettings,
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('Open Location Settings'),
              ),
            ],
            if (showAppSettings) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: Geolocator.openAppSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Open App Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

