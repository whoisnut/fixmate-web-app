import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../network/api_client.dart';
import 'websocket_service.dart';

class LocationStreamingService {
  final String bookingId;
  final String technicianId;

  VoidCallback? onStarted;
  VoidCallback? onStopped;
  void Function(Object error)? onError;

  Timer? _timer;
  bool _isRunning = false;

  LocationStreamingService({
    required this.bookingId,
    required this.technicianId,
  });

  Future<void> startTracking() async {
    if (_isRunning) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        throw StateError('Location permission is required to start tracking.');
      }
    }

    _isRunning = true;
    onStarted?.call();
    await _sendLocation();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      _sendLocation();
    });
  }

  Future<void> _sendLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await ApiClient().put('/api/profile/location', {
        'lat': position.latitude,
        'lng': position.longitude,
      });

      WebSocketService().send('location_update', {
        'lat': position.latitude,
        'lng': position.longitude,
        'booking_id': bookingId,
        'technician_id': technicianId,
      });
    } catch (error) {
      onError?.call(error);
    }
  }

  Future<void> stopTracking() async {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    onStopped?.call();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
