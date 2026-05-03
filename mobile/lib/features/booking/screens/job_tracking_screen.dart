import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  StreamSubscription<Map<String, dynamic>>? _wsSub;
  String? _otherUserId;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadBookingDetails() async {
    try {
      final response =
          await ApiClient().get('/api/bookings/${widget.bookingId}');
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
      }
    } catch (_) {}

    // Load current user id for chat
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson != null) {
      final user = jsonDecode(userJson) as Map<String, dynamic>;
      setState(() {
        _currentUserId = user['id'] as String?;
      });
    }
  }

  void _connectWebSocket() {
    final ws = WebSocketService();
    _wsSub = ws.events.listen((event) {
      final type = event['type'] as String?;
      final data = event['data'] as Map<String, dynamic>? ?? {};

      if (type == 'location_update' && data['booking_id'] == widget.bookingId) {
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          setState(() {
            _technicianLat = lat;
            _technicianLng = lng;
          });
          _recalcEta();
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

  void _recalcEta() {
    if (_technicianLat == null ||
        _technicianLng == null ||
        _customerLat == null ||
        _customerLng == null) {
      return;
    }
    final distKm = _haversineKm(
        _technicianLat!, _technicianLng!, _customerLat!, _customerLng!);
    // Assume 30 km/h average speed in urban area
    setState(() => _estimatedMinutes = (distKm / 30.0 * 60).roundToDouble());
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

  @override
  Widget build(BuildContext context) {
    final displayStatus = _displayStatus();
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
            child: Container(
              color: Colors.grey[200],
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Live Map',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        if (_technicianLat != null)
                          Text(
                            'Technician: ${_technicianLat!.toStringAsFixed(4)}, ${_technicianLng!.toStringAsFixed(4)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          )
                        else
                          Text(
                            'Waiting for technician location…',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  ),
                  // ETA Card
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
                            color: Colors.black.withOpacity(0.08),
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
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person,
                                color: AppTheme.primary),
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
                          if (_estimatedMinutes > 0 &&
                              _jobStatus != 'completed')
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
          ),

          // Job status + actions
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
                    'On the Way', 'Technician is heading to your location',
                    isActive: displayStatus == 'on_the_way',
                    isCompleted: ['arrived', 'in_progress', 'completed']
                        .contains(displayStatus)),
                _buildTimelineItem('Arrived', 'Technician has arrived',
                    isActive: displayStatus == 'arrived',
                    isCompleted:
                        ['in_progress', 'completed'].contains(displayStatus)),
                _buildTimelineItem('In Progress', 'Work is being done',
                    isActive: displayStatus == 'in_progress',
                    isCompleted: displayStatus == 'completed'),
                _buildTimelineItem('Completed', 'Work has been completed',
                    isActive: displayStatus == 'completed',
                    isCompleted: displayStatus == 'completed'),
                const SizedBox(height: 20),
<<<<<<< HEAD
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _currentUserId != null
                        ? () =>
                            Navigator.pushNamed(context, '/chat', arguments: {
=======
                if (_jobStatus == 'completed') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/payment-checkout',
                            arguments: _bookingData ?? {'id': widget.bookingId},
                          ),
                          icon: const Icon(Icons.payment, size: 18),
                          label: const Text('Pay Now'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
>>>>>>> 6e87012b2b3d3a7389c8900d627fcec7ac98db8c
                              'bookingId': widget.bookingId,
                              'technicianName': widget.technicianName,
                              'technicianId': _otherUserId ?? '',
                            },
                          ),
                          icon: const Icon(Icons.star_outline, size: 18),
                          label: const Text('Rate'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                      ? Colors.green.withOpacity(0.1)
                      : isActive
                          ? AppTheme.primary.withOpacity(0.1)
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
