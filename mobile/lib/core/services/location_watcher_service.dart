import 'dart:async';

import 'websocket_service.dart';

class LocationWatcherService {
  final String bookingId;

  void Function(double lat, double lng, String timestamp)? onLocationUpdate;
  void Function(Object error)? onError;

  StreamSubscription<Map<String, dynamic>>? _subscription;

  LocationWatcherService({required this.bookingId});

  Future<void> startWatching() async {
    _subscription?.cancel();
    _subscription = WebSocketService().events.listen(
      (event) {
        final type = event['type'] as String?;
        final data = event['data'] as Map<String, dynamic>? ?? {};

        if (type == 'location_update' && data['booking_id'] == bookingId) {
          final lat = (data['lat'] as num?)?.toDouble();
          final lng = (data['lng'] as num?)?.toDouble();
          final timestamp =
              (event['timestamp'] ?? DateTime.now().toIso8601String())
                  .toString();

          if (lat != null && lng != null) {
            onLocationUpdate?.call(lat, lng, timestamp);
          }
        }
      },
      onError: (error) => onError?.call(error),
    );
  }

  Future<void> stopWatching() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
