import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/websocket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  late Future<List<dynamic>> _availableBookings;
  late Future<List<dynamic>> _activeBookings;
  late Future<List<dynamic>> _historyBookings;
  String? _technicianName;
  int _selectedTabIndex = 0;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _loadTechnicianData();
    _availableBookings = _fetchAvailableBookings();
    _activeBookings = _fetchActiveBookings();
    _historyBookings = _fetchHistoryBookings();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTechnicianData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson != null) {
      final user = jsonDecode(userJson) as Map<String, dynamic>;
      final id = user['id'] as String?;
      setState(() {
        _technicianName = user['name'] as String? ?? 'Technician';
      });
      // Connect WebSocket so customer location updates are broadcast
      final token = prefs.getString(AppConstants.tokenKey);
      if (id != null && token != null) {
        await WebSocketService().connect(userId: id, token: token);
      }
    }
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await _sendLocation();
    });
  }

  Future<void> _sendLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      // Update location on backend
      await ApiClient().put('/api/profile/location', {
        'lat': position.latitude,
        'lng': position.longitude,
      });
      // Also broadcast via WebSocket if on active job
      final active = await _fetchActiveBookings();
      for (final booking in active) {
        final b = booking as Map<String, dynamic>;
        final bookingId = b['id'] as String?;
        if (bookingId != null) {
          WebSocketService().send('location_update', {
            'lat': position.latitude,
            'lng': position.longitude,
            'booking_id': bookingId,
          });
        }
      }
    } catch (_) {}
  }

  Future<List<dynamic>> _fetchAvailableBookings() async {
    try {
      final response = await ApiClient().get('/api/bookings/available');
      if (response.statusCode == 200) {
        return response.data is List ? response.data as List : [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> _fetchActiveBookings() async {
    try {
      final response = await ApiClient().get('/api/bookings?status=accepted');
      if (response.statusCode == 200) {
        return response.data is List ? response.data as List : [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> _fetchHistoryBookings() async {
    try {
      final completed = await ApiClient().get('/api/bookings?status=completed');
      final cancelled = await ApiClient().get('/api/bookings?status=cancelled');
      final c = (completed.statusCode == 200 && completed.data is List)
          ? completed.data as List
          : [];
      final x = (cancelled.statusCode == 200 && cancelled.data is List)
          ? cancelled.data as List
          : [];
      final all = [...c, ...x];
      all.sort((a, b) {
        final aDate = DateTime.tryParse(
                ((a as Map<String, dynamic>)['created_at'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(
                ((b as Map<String, dynamic>)['created_at'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return all;
    } catch (_) {
      return [];
    }
  }

  void _refreshAll() {
    setState(() {
      _availableBookings = _fetchAvailableBookings();
      _activeBookings = _fetchActiveBookings();
      _historyBookings = _fetchHistoryBookings();
    });
  }

  Future<void> _acceptBooking(String bookingId) async {
    try {
      await ApiClient().post('/api/bookings/$bookingId/accept', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking accepted')),
      );
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept: $e')),
      );
    }
  }

  Future<void> _rejectBooking(String bookingId) async {
    try {
      await ApiClient().post('/api/bookings/$bookingId/reject', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking declined')),
      );
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline: $e')),
      );
    }
  }

  Future<void> _updateJobStatus(String bookingId, String status) async {
    try {
      final endpoint = status == 'in_progress'
          ? '/api/bookings/$bookingId/start'
          : '/api/bookings/$bookingId/complete';
      await ApiClient().post(endpoint, {});
      // Notify customer via WebSocket
      WebSocketService().send('booking_status', {
        'booking_id': bookingId,
        'status': status,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $status')),
      );
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _logout() async {
    _locationTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    await prefs.remove('user_type');
    await WebSocketService().disconnect();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Technician Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Earnings & Payouts',
            onPressed: () => Navigator.pushNamed(context, '/technician-payout'),
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined),
            tooltip: 'Profile Setup',
            onPressed: () =>
                Navigator.pushNamed(context, '/technician-profile-setup'),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAll),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _technicianName ?? 'Technician',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab selector
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildTabButton('Available', 0),
                        _buildTabButton('Active Jobs', 1),
                        _buildTabButton('History', 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_selectedTabIndex == 0)
                    FutureBuilder<List<dynamic>>(
                      future: _availableBookings,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final bookings = snapshot.data ?? [];
                        if (bookings.isEmpty) {
                          return _buildEmptyState(
                              'No available bookings nearby',
                              Icons.calendar_today_outlined);
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            final b = bookings[index] is Map
                                ? bookings[index] as Map<String, dynamic>
                                : jsonDecode(bookings[index].toString())
                                    as Map<String, dynamic>;
                            return _buildAvailableBookingCard(b);
                          },
                        );
                      },
                    ),

                  if (_selectedTabIndex == 1)
                    FutureBuilder<List<dynamic>>(
                      future: _activeBookings,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final bookings = snapshot.data ?? [];
                        if (bookings.isEmpty) {
                          return _buildEmptyState(
                              'No active jobs', Icons.work_outline);
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            final b = bookings[index] is Map
                                ? bookings[index] as Map<String, dynamic>
                                : jsonDecode(bookings[index].toString())
                                    as Map<String, dynamic>;
                            return _buildActiveJobCard(b);
                          },
                        );
                      },
                    ),

                  if (_selectedTabIndex == 2)
                    FutureBuilder<List<dynamic>>(
                      future: _historyBookings,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final bookings = snapshot.data ?? [];
                        if (bookings.isEmpty) {
                          return _buildEmptyState(
                              'No job history yet', Icons.history_outlined);
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            final b = bookings[index] is Map
                                ? bookings[index] as Map<String, dynamic>
                                : jsonDecode(bookings[index].toString())
                                    as Map<String, dynamic>;
                            return _buildHistoryJobCard(b);
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppTheme.borderColor),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableBookingCard(Map<String, dynamic> booking) {
    final bookingId = booking['id'] as String? ?? '';
    final address = booking['address'] as String? ?? 'Address not provided';
    final service = booking['service'] as Map<String, dynamic>?;
    final serviceName = service?['name'] as String? ?? 'Service';
    final price = (booking['total_price'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(serviceName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textPrimary)),
              ),
              Text('\$$price',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 15, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(address,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectBooking(bookingId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptBooking(bookingId),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobCard(Map<String, dynamic> booking) {
    final bookingId = booking['id'] as String? ?? '';
    final address = booking['address'] as String? ?? '';
    final status = booking['status'] as String? ?? 'accepted';
    final service = booking['service'] as Map<String, dynamic>?;
    final serviceName = service?['name'] as String? ?? 'Service';
    final customerId = booking['customer_id'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(serviceName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.textPrimary)),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 15, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(address,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/chat', arguments: {
                    'bookingId': bookingId,
                    'otherUserName': 'Customer',
                    'otherUserId': customerId,
                  }),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (status == 'accepted')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateJobStatus(bookingId, 'in_progress'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Start Job'),
                  ),
                ),
              if (status == 'in_progress')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateJobStatus(bookingId, 'completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Complete'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryJobCard(Map<String, dynamic> booking) {
    final bookingId = booking['id'] as String? ?? '';
    final address = booking['address'] as String? ?? '';
    final status = booking['status'] as String? ?? 'completed';
    final service = booking['service'] as Map<String, dynamic>?;
    final serviceName = service?['name'] as String? ?? 'Service';
    final price = (booking['total_price'] as num?)?.toDouble() ?? 0;
    final createdAtRaw = (booking['created_at'] ?? '').toString();
    final createdAt = DateTime.tryParse(createdAtRaw);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(serviceName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textPrimary)),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(address,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                createdAt != null
                    ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                    : '',
                style:
                    const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
              ),
              Text('\$$price',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.primary)),
            ],
          ),
          if (status == 'completed') ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/review', arguments: {
                'bookingId': bookingId,
                'technicianName': _technicianName ?? 'Technician',
                'technicianId': '',
              }),
              icon: const Icon(Icons.star_outline, size: 16),
              label: const Text('View Review'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                side: const BorderSide(color: AppTheme.primary),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final colors = {
      'accepted': Colors.blue,
      'in_progress': Colors.orange,
      'completed': Colors.green,
    };
    final color = colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
