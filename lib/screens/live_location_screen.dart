import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';

class LiveLocationScreen extends StatefulWidget {
  const LiveLocationScreen({super.key});

  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLocation;
  bool _isMapReady = false;
  bool _permissionDenied = false;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _checkingPermission = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      bool? allow = await _showPermissionPopup();
      if (allow == true) {
        permission = await Geolocator.requestPermission();
      } else {
        setState(() {
          _permissionDenied = true;
          _checkingPermission = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() {
        _permissionDenied = true;
        _checkingPermission = false;
      });
      return;
    }

    setState(() => _checkingPermission = false);
  }

  Future<bool?> _showPermissionPopup() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Allow Location Access'),
        content: const Text(
          'Saaya needs your live location to share it with emergency contacts and authorities.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Deny', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _startTracking() {
    // Requirements: Start tracking only after onMapReady
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          // Mandatory Guard: Move only if map is ready
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
      appBar: AppBar(
        title: const Text('Live Location'),
        centerTitle: true,
      ),
      body: _buildBody(),
      bottomNavigationBar: !_isMapReady || _permissionDenied ? null : _buildBottomActions(),
    );
  }

  Widget _buildBody() {
    if (_checkingPermission) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Location permission is required to continue',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkPermission,
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Requirement: Wrap in SizedBox with explicit height for Web stability
        SizedBox(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(20.5937, 78.9629), // Default center
              initialZoom: 15.0,
              onMapReady: () {
                if (mounted) {
                  setState(() => _isMapReady = true);
                  _startTracking(); // Start tracking ONLY after render
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
                      child: const _PulseMarker(),
                    ),
                  ],
                ),
            ],
          ),
        ),
        
        // Custom Loading Overlay until map is ready
        if (!_isMapReady)
          Container(
            color: Colors.white,
            child: const Center(child: CircularProgressIndicator()),
          ),

        if (_isMapReady)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Live location sharing active',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location shared with police')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text('Share with Police'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location shared with contacts')),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              side: const BorderSide(color: AppTheme.primaryRed),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Share with Emergency Contacts', style: TextStyle(color: AppTheme.primaryRed)),
          ),
        ],
      ),
    );
  }
}

class _PulseMarker extends StatefulWidget {
  const _PulseMarker();

  @override
  State<_PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<_PulseMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
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
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        );
      },
    );
  }
}
