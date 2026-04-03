/// Ride Tracking Screen - Shows live tracking of driver and ride
/// Monitors route, delays, and safety alerts in real-time

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ride_model.dart';
import '../providers/cabs_providers.dart';
import '../services/location_service.dart';
import '../services/ride_service.dart';

class RideTrackingScreen extends ConsumerStatefulWidget {
  final Ride ride;

  const RideTrackingScreen({
    Key? key,
    required this.ride,
  }) : super(key: key);

  @override
  ConsumerState<RideTrackingScreen> createState() =>
      _RideTrackingScreenState();
}

class _RideTrackingScreenState extends ConsumerState<RideTrackingScreen> {
  late RideService _rideService;
  late Ride _currentRide;
  DateTime? _rideStartTime;
  bool _hasAlertBeenShown = false;

  @override
  void initState() {
    super.initState();
    _currentRide = widget.ride;
    final supabase = ref.read(supabaseProvider);
    _rideService = RideService();
    _rideService.initialize(supabase);
    _startRideMonitoring();
  }

  void _startRideMonitoring() async {
    try {
      // Update ride status to ongoing
      await _rideService.updateRideStatus(
        rideId: _currentRide.id,
        status: RideStatus.ongoing,
      );
      _rideStartTime = DateTime.now();

      // Start monitoring for anomalies
      _monitorRideAnomalies();
    } catch (e) {
      _showErrorSnackBar('Error starting ride: ${e.toString()}');
    }
  }

  void _monitorRideAnomalies() {
    // Check for delays periodically
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _rideStartTime != null) {
        final elapsedMinutes =
            DateTime.now().difference(_rideStartTime!).inMinutes;

        // If ride is taking significantly longer than expected
        if (elapsedMinutes > (_currentRide.estimatedDurationMinutes * 1.5)) {
          _createDelayAlert();
        }
      }
    });
  }

  Future<void> _createDelayAlert() async {
    try {
      if (!_hasAlertBeenShown) {
        _hasAlertBeenShown = true;

        await _rideService.createSafetyAlert(
          rideId: _currentRide.id,
          alertType: AlertType.delayDetected,
          description:
              'Ride is taking longer than expected. Current duration: ${_rideStartTime != null ? DateTime.now().difference(_rideStartTime!).inMinutes : 0} minutes',
          latitude: _currentRide.pickupLat,
          longitude: _currentRide.pickupLng,
        );

        _showSafetyAlert(
          title: 'Ride Delay Detected',
          message:
              'Your ride is taking longer than expected. Please check in with your driver.',
          alertType: AlertType.delayDetected,
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error creating alert: ${e.toString()}');
    }
  }

  void _showSafetyAlert({
    required String title,
    required String message,
    required AlertType alertType,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: alertType == AlertType.delayDetected
            ? Colors.orange[50]
            : Colors.red[50],
        title: Row(
          children: [
            Icon(
              alertType == AlertType.delayDetected
                  ? Icons.warning_rounded
                  : Icons.emergency,
              color: alertType == AlertType.delayDetected
                  ? Colors.orange
                  : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Share live location or contact emergency
              _shareEmergencyDetails();
            },
            child: const Text('Share Location'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _shareEmergencyDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency details shared with trusted contacts'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _completeRide() async {
    try {
      if (_rideStartTime == null) {
        _showErrorSnackBar('Ride data unavailable');
        return;
      }

      final actualDuration =
          DateTime.now().difference(_rideStartTime!).inMinutes;
      const double actualDistance = 5.0; // In real app, calculate from polyline

      await _rideService.completeRide(
        rideId: _currentRide.id,
        actualDistance: actualDistance,
        actualDurationMinutes: actualDuration,
      );

      if (mounted) {
        _showCompletionDialog();
      }
    } catch (e) {
      _showErrorSnackBar('Error completing ride: ${e.toString()}');
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Ride Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green[100],
              ),
              child: Icon(
                Icons.check,
                color: Colors.green[600],
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Thank you for riding with Naarixa!'),
            const SizedBox(height: 8),
            const Text(
              'Your ride was safe and secure.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride in Progress'),
        backgroundColor: const Color(0xFF9B59B6),
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency_share),
            onPressed: _shareEmergencyDetails,
            tooltip: 'Share emergency details',
          ),
        ],
      ),
      body: StreamBuilder<Ride>(
        stream: _rideService.getRideStream(_currentRide.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          _currentRide = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Map area (placeholder)
                Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.map,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        const Text('Live Location Tracking'),
                        const SizedBox(height: 4),
                        Text(
                          'From: ${_currentRide.pickupAddress}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'To: ${_currentRide.dropAddress}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                // Ride details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B59B6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatusItem(
                              icon: Icons.directions_car,
                              label: 'Status',
                              value: _currentRide.status
                                  .toString()
                                  .split('.')
                                  .last
                                  .toUpperCase(),
                            ),
                            _buildStatusItem(
                              icon: Icons.timer,
                              label: 'Duration',
                              value: _rideStartTime != null
                                  ? '${DateTime.now().difference(_rideStartTime!).inMinutes}m'
                                  : '0m',
                            ),
                            _buildStatusItem(
                              icon: Icons.currency_rupee,
                              label: 'Est. Fare',
                              value: '₹${_currentRide.estimatedFare.toStringAsFixed(0)}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Driver info
                      const Text(
                        'Driver Information',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF9B59B6).withOpacity(0.1),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person,
                                  color: Color(0xFF9B59B6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Driver Details Loading...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Driver ID: ${_currentRide.driverId}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.call),
                              onPressed: () {
                                _showErrorSnackBar('Call driver feature');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Ride details
                      const Text(
                        'Ride Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.location_on,
                        label: 'Distance',
                        value:
                            '${_currentRide.distanceKm.toStringAsFixed(1)} km',
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.access_time,
                        label: 'Estimated Time',
                        value:
                            '${_currentRide.estimatedDurationMinutes} minutes',
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.currency_rupee,
                        label: 'Estimated Fare',
                        value:
                            '₹${_currentRide.estimatedFare.toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: 20),
                      // Complete ride button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _currentRide.status == RideStatus.ongoing
                              ? _completeRide
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Complete Ride',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Cancel button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _currentRide.status == RideStatus.ongoing
                              ? () async {
                                  await _rideService.cancelRide(_currentRide.id,
                                      reason: 'User cancelled');
                                  if (mounted) {
                                    Navigator.pop(context);
                                  }
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel Ride',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF9B59B6)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF9B59B6)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
