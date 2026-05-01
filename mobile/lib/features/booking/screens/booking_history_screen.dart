import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/booking_provider.dart';

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> {
  bool _isTechnician = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      setState(() {
        _isTechnician = userMap['role'] == 'technician';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsyncValue = ref.watch(bookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
      ),
      body: bookingsAsyncValue.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading bookings...'),
            ],
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to load bookings',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(bookingsProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (bookings) => bookings.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No bookings yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(bookingsProvider);
                  await ref.watch(bookingsProvider.future);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    return _buildBookingCard(context, ref, bookings[index]);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> booking,
  ) {
    final status = booking['status'] as String? ?? 'pending';
    final bookingId = booking['id'] as String? ?? '';
    final service = booking['service'] as Map<String, dynamic>? ?? {};
    final serviceName = service['name'] as String? ?? 'Unknown Service';
    final totalPrice = booking['total_price'] as num? ?? 0;
    final priceFormatted = totalPrice.toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking #${bookingId.length >= 8 ? bookingId.substring(0, 8) : bookingId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 12),
            // Location
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking['address'] ?? 'Unknown location',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Scheduled Date
            if (booking['scheduled_at'] != null) ...[
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Scheduled: ${_formatDateTime(booking['scheduled_at'])}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Created Date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Created: ${_formatDateTime(booking['created_at'])}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$$priceFormatted',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),

            // Action buttons for technicians
            if (_isTechnician) ...[
              const SizedBox(height: 16),
              _buildTechnicianActions(context, ref, status, bookingId),
            ] else if (status == 'completed') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final technicianId =
                            booking['technician_id'] as String? ?? '';
                        Navigator.pushNamed(context, '/review',
                            arguments: {
                              'bookingId': bookingId,
                              'technicianName': 'Your Technician',
                              'technicianId': technicianId,
                            });
                      },
                      icon: const Icon(Icons.star_outline, size: 16),
                      label: const Text('Rate'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                          context, '/payment-checkout',
                          arguments: booking),
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Pay'),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'accepted' || status == 'in_progress') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/job-tracking',
                      arguments: {
                        'bookingId': bookingId,
                        'technicianName': 'Your Technician',
                      }),
                  icon: const Icon(Icons.location_on, size: 16),
                  label: const Text('Track Job'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianActions(
    BuildContext context,
    WidgetRef ref,
    String status,
    String bookingId,
  ) {
    if (status == 'accepted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _startBooking(context, ref, bookingId),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Job'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
          ),
        ),
      );
    } else if (status == 'in_progress') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _completeBooking(context, ref, bookingId),
          icon: const Icon(Icons.check_circle),
          label: const Text('Complete Job'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _startBooking(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
  ) async {
    ref.read(bookingActionProvider.notifier).startBooking(bookingId);

    // Refresh bookings after a short delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job started successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
    ref.invalidate(bookingsProvider);
  }

  Future<void> _completeBooking(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
  ) async {
    ref.read(bookingActionProvider.notifier).completeBooking(bookingId);

    // Refresh bookings after a short delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job completed successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
    ref.invalidate(bookingsProvider);
  }

  String _formatDateTime(dynamic raw) {
    if (raw == null) return 'N/A';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString();
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'in_progress':
        return AppTheme.primary;
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
