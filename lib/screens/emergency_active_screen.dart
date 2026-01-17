import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';

class EmergencyActiveScreen extends StatefulWidget {
  const EmergencyActiveScreen({super.key});

  @override
  State<EmergencyActiveScreen> createState() => _EmergencyActiveScreenState();
}

class _EmergencyActiveScreenState extends State<EmergencyActiveScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLocation;
  bool _isMapReady = false;

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _startLiveTracking() {
    // Requirements: Start location streaming only after map is ready
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          // Mandatory guard: Check _isMapReady before moving
          if (_isMapReady) {
            _mapController.move(_currentLocation!, 15.0);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryRed,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
              child: Column(
                children: [
                  const _PulsingAlertIcon(),
                  const SizedBox(height: 24),
                  const Text(
                    'Emergency Alert Activated',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentLocation != null
                        ? 'Live GPS: ${_currentLocation!.latitude.toStringAsFixed(4)}° N, ${_currentLocation!.longitude.toStringAsFixed(4)}° W'
                        : 'Connecting to GPS...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 250,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildOSMView(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Status Timeline',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF2D3238),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildTimelineItem('Alert sent', true),
                              _buildTimelineItem('Contacts notified', true),
                              _buildTimelineItem('Authorities alerted', true),
                              _buildTimelineItem('Live tracking active', _currentLocation != null),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => _showCancelConfirmation(context),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppTheme.primaryRed, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Cancel SOS',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOSMView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? const LatLng(0, 0),
                initialZoom: 15.0,
                onMapReady: () {
                  // Requirement: Use onMapReady callback
                  if (mounted) {
                    setState(() {
                      _isMapReady = true;
                    });
                    // Requirement: Start location streaming only after map is ready
                    _startLiveTracking();
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.saaya.app',
                ),
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation!,
                        width: 60,
                        height: 60,
                        child: const _LocationMarker(),
                      ),
                    ],
                  ),
              ],
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gps_fixed, size: 14, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      _currentLocation != null ? 'Live Tracking Active' : 'Waiting for Map...',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String label, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? AppTheme.secondaryGreen : Colors.grey.shade400,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: completed ? const Color(0xFF2D3238) : Colors.grey.shade500,
              fontWeight: completed ? FontWeight.w600 : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel SOS?'),
        content: const Text('Are you sure you want to deactivate the emergency alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Active', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationMarker extends StatefulWidget {
  const _LocationMarker();

  @override
  State<_LocationMarker> createState() => _LocationMarkerState();
}

class _LocationMarkerState extends State<_LocationMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 60 * _controller.value,
              height: 60 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(1 - _controller.value),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PulsingAlertIcon extends StatefulWidget {
  const _PulsingAlertIcon();

  @override
  State<_PulsingAlertIcon> createState() => _PulsingAlertIconState();
}

class _PulsingAlertIconState extends State<_PulsingAlertIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15 + (0.35 * _controller.value)),
          ),
          child: const Icon(Icons.warning_rounded, color: Colors.white, size: 42),
        );
      },
    );
  }
}
