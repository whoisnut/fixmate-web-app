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
        title: Text('Booking History'),
      ),
      body: bookingsAsyncValue.when(
        loading: () => Center(
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
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Failed to load bookings',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(bookingsProvider);
                },
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
              ),
            ],
          ),
        ),
        data: (bookings) => bookings.isEmpty
            ? Center(
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
                  padding: EdgeInsets.all(16),
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

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking #${(bookingId).substring(0, 8)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking['address'] ?? 'Unknown location',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  booking['created_at'] ?? 'N/A',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${(booking['total_price'] ?? 0).toString()}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),

            // Action buttons for technicians
            if (_isTechnician) ...[
              SizedBox(height: 16),
              _buildTechnicianActions(context, ref, status, bookingId),
            ] else if (status == 'completed') ...[
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to rating screen
                },
                child: Text('Rate Service'),
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
          icon: Icon(Icons.play_arrow),
          label: Text('Start Job'),
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
          icon: Icon(Icons.check_circle),
          label: Text('Complete Job'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
          ),
        ),
      );
    }
    return SizedBox.shrink();
  }

  Future<void> _startBooking(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
  ) async {
    ref.read(bookingActionProvider.notifier).startBooking(bookingId);

    // Refresh bookings after a short delay
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job completed successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
    ref.invalidate(bookingsProvider);
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
