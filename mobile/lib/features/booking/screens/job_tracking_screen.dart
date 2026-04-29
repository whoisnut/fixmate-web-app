import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

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
  double _technicianLat = 11.5564;
  double _technicianLng = 104.8882;
  double _estimatedMinutes = 12;
  String _jobStatus =
      'on_the_way'; // on_the_way, arrived, in_progress, completed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Job Tracking'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Map Placeholder (Using Container as placeholder)
          Expanded(
            child: Container(
              color: AppTheme.surfaceLight,
              child: Stack(
                children: [
                  // Map background
                  Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Map View',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Technician location: ${_technicianLat.toStringAsFixed(4)}, ${_technicianLng.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ETA Card at bottom
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
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: AppTheme.primary,
                                ),
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
                                    const SizedBox(height: 4),
                                    Text(
                                      _getStatusText(_jobStatus),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getStatusColor(_jobStatus),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                                  const SizedBox(height: 4),
                                  const Text(
                                    'ETA',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
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

          // Job Details Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Timeline
                Text(
                  'Job Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),

                // Timeline Items
                _buildTimelineItem(
                  'On the Way',
                  'Technician is heading to your location',
                  isActive: _jobStatus == 'on_the_way',
                  isCompleted: ['arrived', 'in_progress', 'completed']
                      .contains(_jobStatus),
                ),
                _buildTimelineItem(
                  'Arrived',
                  'Technician has arrived at your location',
                  isActive: _jobStatus == 'arrived',
                  isCompleted:
                      ['in_progress', 'completed'].contains(_jobStatus),
                ),
                _buildTimelineItem(
                  'In Progress',
                  'Work is being done',
                  isActive: _jobStatus == 'in_progress',
                  isCompleted: _jobStatus == 'completed',
                ),
                _buildTimelineItem(
                  'Completed',
                  'Work has been completed',
                  isActive: _jobStatus == 'completed',
                  isCompleted: _jobStatus == 'completed',
                ),

                const SizedBox(height: 24),

                // Contact Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement chat functionality
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Contact Technician'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String description, {
    required bool isActive,
    required bool isCompleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline marker
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
              // Connecting line
              if (title != 'Completed')
                Container(
                  width: 2,
                  height: 20,
                  color: isCompleted ? Colors.green : AppTheme.borderColor,
                ),
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
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
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
        return 'On the way...';
      case 'arrived':
        return 'Arrived';
      case 'in_progress':
        return 'Working on it';
      case 'completed':
        return 'Job completed';
      default:
        return 'Processing...';
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
