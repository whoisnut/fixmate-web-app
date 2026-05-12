import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/websocket_service.dart';

class JobTrackingScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String technicianName;

  const JobTrackingScreen({
    super.key,
    required this.bookingId,
    required this.technicianName,
  });

  @override
  ConsumerState<JobTrackingScreen> createState() => _JobTrackingScreenState();
}

class _JobTrackingScreenState extends ConsumerState<JobTrackingScreen> {
  double? _technicianLat;
  double? _technicianLng;
  double? _customerLat;
  double? _customerLng;
  double _estimatedMinutes = 0;
  String _jobStatus = 'accepted';
  Map<String, dynamic>? _bookingData;

  final MapController _mapController = MapController();
  bool _mapReady = false;

  StreamSubscription<Map<String, dynamic>>? _wsSub;
  Timer? _pollTimer;
  String? _otherUserId;
  String? _currentUserId;

  // Default center — will be updated once booking loads
  static const _defaultCenter = LatLng(13.7563, 100.5018); // Bangkok

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _pollTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadBookingDetails() async {
    try {
      final response = await ApiClient().get('/api/bookings/${widget.bookingId}');
      if (response.statusCode == 200) {
        final booking = response.data as Map<String, dynamic>;
        final lat = (booking['lat'] as num?)?.toDouble();
        final lng = (booking['lng'] as num?)?.toDouble();
        setState(() {
          _customerLat = lat;
          _customerLng = lng;
          _jobStatus = booking['status'] ?? 'accepted';
          _otherUserId = booking['technician_id'] as String? ?? '';
          _bookingData = booking;
        });
        _recalcEta();
        _fitMap();
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    final token = prefs.getString(AppConstants.tokenKey);
    if (userJson != null) {
      final user = jsonDecode(userJson) as Map<String, dynamic>;
      final userId = user['id'] as String?;
      setState(() => _currentUserId = userId);

      // Connect WebSocket and listen for real-time updates
      if (userId != null && token != null) {
        final ws = WebSocketService();
        await ws.connect(userId: userId, token: token);
        _wsSub = ws.events.listen((event) {
          final type = event['type'] as String?;
          final data = event['data'] as Map<String, dynamic>? ?? {};

          if (type == 'location_update' &&
              data['booking_id'] == widget.bookingId) {
            final lat = (data['lat'] as num?)?.toDouble();
            final lng = (data['lng'] as num?)?.toDouble();
            if (lat != null && lng != null) {
              setState(() {
                _technicianLat = lat;
                _technicianLng = lng;
              });
              _recalcEta();
              _fitMap();
            }
          } else if (type == 'booking_status' &&
              data['booking_id'] == widget.bookingId) {
            final status = data['status'] as String?;
            if (status != null) {
              setState(() {
                _jobStatus = status;
                if (status == 'completed') _estimatedMinutes = 0;
              });
            }
          } else if (type == 'eta_update' &&
              data['booking_id'] == widget.bookingId) {
            final eta = (data['eta_minutes'] as num?)?.toDouble();
            if (eta != null) setState(() => _estimatedMinutes = eta);
          }
        });
      }
    }

    // Polling fallback every 5 s — keeps status in sync even if WebSocket drops
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_jobStatus == 'completed') {
        _pollTimer?.cancel();
        return;
      }
      try {
        final res = await ApiClient().get('/api/bookings/${widget.bookingId}');
        if (res.statusCode == 200 && mounted) {
          final booking = res.data as Map<String, dynamic>;
          final status = booking['status'] as String? ?? _jobStatus;
          setState(() {
            _jobStatus = status;
            _bookingData = booking;
            if (status == 'completed') _estimatedMinutes = 0;
          });
        }
      } catch (_) {}
    });
  }

  void _recalcEta() {
    if (_technicianLat == null || _technicianLng == null ||
        _customerLat == null || _customerLng == null) { return; }
    final distKm = _haversineKm(
        _technicianLat!, _technicianLng!, _customerLat!, _customerLng!);
    setState(() => _estimatedMinutes = (distKm / 30.0 * 60).roundToDouble());
  }

  void _fitMap() {
    if (!_mapReady) return;
    final points = <LatLng>[
      if (_customerLat != null && _customerLng != null)
        LatLng(_customerLat!, _customerLng!),
      if (_technicianLat != null && _technicianLng != null)
        LatLng(_technicianLat!, _technicianLng!),
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
    );
  }

  static double _haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final dphi = (lat2 - lat1) * math.pi / 180;
    final dlambda = (lon2 - lon1) * math.pi / 180;
    final a = math.pow(math.sin(dphi / 2), 2) +
        math.cos(phi1) * math.cos(phi2) * math.pow(math.sin(dlambda / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  String _displayStatus() {
    switch (_jobStatus) {
      case 'accepted':
        return 'on_the_way';
      case 'in_progress':
        return 'in_progress';
      case 'completed':
        return 'completed';
      default:
        return _jobStatus;
    }
  }

  LatLng get _mapCenter {
    if (_customerLat != null && _customerLng != null) {
      return LatLng(_customerLat!, _customerLng!);
    }
    if (_technicianLat != null && _technicianLng != null) {
      return LatLng(_technicianLat!, _technicianLng!);
    }
    return _defaultCenter;
  }

  @override
  Widget build(BuildContext context) {
    final displayStatus = _displayStatus();

    final customerPoint = (_customerLat != null && _customerLng != null)
        ? LatLng(_customerLat!, _customerLng!)
        : null;
    final techPoint = (_technicianLat != null && _technicianLng != null)
        ? LatLng(_technicianLat!, _technicianLng!)
        : null;

    final markers = <Marker>[
      if (customerPoint != null)
        Marker(
          point: customerPoint,
          width: 48,
          height: 56,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: const Icon(Icons.home, color: Colors.white, size: 18),
              ),
              const CustomPaint(size: Size(12, 8), painter: _PinTailPainter(Colors.blue)),
            ],
          ),
        ),
      if (techPoint != null)
        Marker(
          point: techPoint,
          width: 48,
          height: 56,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: const Icon(Icons.build, color: Colors.white, size: 18),
              ),
              const CustomPaint(size: Size(12, 8), painter: _PinTailPainter(AppTheme.primary)),
            ],
          ),
        ),
    ];

    final polylines = (customerPoint != null && techPoint != null)
        ? [
            Polyline(
              points: [techPoint, customerPoint],
              color: AppTheme.primary.withValues(alpha: 0.6),
              strokeWidth: 3,
              pattern: StrokePattern.dashed(segments: const [10, 6]),
            ),
          ]
        : <Polyline>[];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Job Tracking'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _mapCenter,
                    initialZoom: 14,
                    onMapReady: () {
                      setState(() => _mapReady = true);
                      _fitMap();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.fixmate.app',
                      maxZoom: 19,
                    ),
                    if (polylines.isNotEmpty)
                      PolylineLayer(polylines: polylines),
                    if (markers.isNotEmpty)
                      MarkerLayer(markers: markers),
                  ],
                ),

                // Legend
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _legendItem(Colors.blue, Icons.home, 'Your Location'),
                        const SizedBox(height: 4),
                        _legendItem(AppTheme.primary, Icons.build,
                            techPoint != null ? 'Technician' : 'Awaiting technician'),
                      ],
                    ),
                  ),
                ),

                // Waiting overlay when no technician location yet
                if (techPoint == null && _jobStatus != 'completed')
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Waiting for technician location…',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ),

                // ETA card
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.technicianName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getStatusText(displayStatus),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getStatusColor(displayStatus),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_estimatedMinutes > 0 && _jobStatus != 'completed')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_estimatedMinutes.toInt()} min',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const Text('ETA',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textTertiary)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Job status timeline + actions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Job Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                _buildTimelineItem(
                  'On the Way',
                  'Technician is heading to your location',
                  isActive: displayStatus == 'on_the_way',
                  isCompleted: ['arrived', 'in_progress', 'completed']
                      .contains(displayStatus),
                ),
                _buildTimelineItem(
                  'Arrived',
                  'Technician has arrived',
                  isActive: displayStatus == 'arrived',
                  isCompleted:
                      ['in_progress', 'completed'].contains(displayStatus),
                ),
                _buildTimelineItem(
                  'In Progress',
                  'Work is being done',
                  isActive: displayStatus == 'in_progress',
                  isCompleted: displayStatus == 'completed',
                ),
                _buildTimelineItem(
                  'Completed',
                  'Work has been completed',
                  isActive: displayStatus == 'completed',
                  isCompleted: displayStatus == 'completed',
                ),
                const SizedBox(height: 20),
                if (_jobStatus == 'completed') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/payment-checkout',
                            arguments:
                                _bookingData ?? {'id': widget.bookingId},
                          ),
                          icon: const Icon(Icons.payment, size: 18),
                          label: const Text('Pay Now'),
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/review',
                            arguments: {
                              'bookingId': widget.bookingId,
                              'technicianName': widget.technicianName,
                              'technicianId': _otherUserId ?? '',
                            },
                          ),
                          icon: const Icon(Icons.star_outline, size: 18),
                          label: const Text('Rate'),
                          style: OutlinedButton.styleFrom(
                            side:
                                const BorderSide(color: AppTheme.primary),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _currentUserId != null
                          ? () => Navigator.pushNamed(context, '/chat',
                              arguments: {
                                'bookingId': widget.bookingId,
                                'otherUserName': widget.technicianName,
                                'otherUserId': _otherUserId ?? '',
                              })
                          : null,
                      icon: const Icon(Icons.chat),
                      label: const Text('Contact Technician'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 12),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildTimelineItem(String title, String description,
      {required bool isActive, required bool isCompleted}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green
                        : isActive
                            ? AppTheme.primary
                            : AppTheme.borderColor,
                    width: 2,
                  ),
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.1)
                      : isActive
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.green)
                      : isActive
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary,
                              ),
                            )
                          : const SizedBox(),
                ),
              ),
              if (title != 'Completed')
                Container(
                    width: 2,
                    height: 20,
                    color: isCompleted ? Colors.green : AppTheme.borderColor),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? AppTheme.primary
                        : isCompleted
                            ? Colors.green
                            : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'on_the_way':
        return 'On the way…';
      case 'arrived':
        return 'Arrived';
      case 'in_progress':
        return 'Working on it';
      case 'completed':
        return 'Job completed';
      default:
        return 'Processing…';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'on_the_way':
        return AppTheme.primary;
      case 'arrived':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return AppTheme.textSecondary;
    }
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}
