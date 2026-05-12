import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_streaming_service.dart';
import '../services/location_watcher_service.dart';

// Location Streaming Service Provider (for technicians)
final locationStreamingServiceProvider = StateNotifierProvider.family<
    LocationStreamingNotifier,
    AsyncValue<void>,
    Map<String, String>>((ref, params) {
  return LocationStreamingNotifier(
    bookingId: params['booking_id'] ?? '',
    technicianId: params['technician_id'] ?? '',
  );
});

class LocationStreamingNotifier extends StateNotifier<AsyncValue<void>> {
  final LocationStreamingService service;

  LocationStreamingNotifier({
    required String bookingId,
    required String technicianId,
  })  : service = LocationStreamingService(
          bookingId: bookingId,
          technicianId: technicianId,
        ),
        super(const AsyncValue.data(null)) {
    _setupCallbacks();
  }

  void _setupCallbacks() {
    service.onStarted = () {
      state = const AsyncValue.data(null);
    };

    service.onError = (error) {
      state = AsyncValue.error(error, StackTrace.current);
    };

    service.onStopped = () {
      state = const AsyncValue.data(null);
    };
  }

  Future<void> startTracking() async {
    state = const AsyncValue.loading();
    try {
      await service.startTracking();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> stopTracking() async {
    await service.stopTracking();
  }

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }
}

// Location Watcher Service Provider (for customers)
final locationWatcherServiceProvider = StateNotifierProvider.family<
    LocationWatcherNotifier,
    AsyncValue<LocationUpdate?>,
    String>((ref, bookingId) {
  return LocationWatcherNotifier(bookingId: bookingId);
});

class LocationWatcherNotifier
    extends StateNotifier<AsyncValue<LocationUpdate?>> {
  final LocationWatcherService service;

  LocationWatcherNotifier({required String bookingId})
      : service = LocationWatcherService(bookingId: bookingId),
        super(const AsyncValue.data(null)) {
    _setupCallbacks();
  }

  void _setupCallbacks() {
    service.onLocationUpdate = (lat, lng, timestamp) {
      state = AsyncValue.data(LocationUpdate(
        latitude: lat,
        longitude: lng,
        timestamp: timestamp,
      ));
    };

    service.onError = (error) {
      state = AsyncValue.error(error, StackTrace.current);
    };
  }

  Future<void> startWatching() async {
    state = const AsyncValue.loading();
    try {
      await service.startWatching();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> stopWatching() async {
    await service.stopWatching();
  }

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }
}

class LocationUpdate {
  final double latitude;
  final double longitude;
  final String timestamp;

  LocationUpdate({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}
