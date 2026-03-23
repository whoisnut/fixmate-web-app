import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../payment/screens/payment_methods_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsyncValue = ref.watch(profileProvider);
    final technicianStatsAsyncValue = _isTechnician
        ? ref.watch(technicianStatsProvider)
        : AsyncValue.data(<String, dynamic>{});

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: profileAsyncValue.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              SizedBox(height: 16),
              Text('Failed to load profile'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(profileProvider),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) => SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text(
                  (profile['name'] as String? ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                profile['name'] as String? ?? 'User',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _isTechnician ? 'Technician' : 'Customer',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        profile: profile,
                      ),
                    ),
                  );
                  if (result == true) {
                    // Refresh profile data
                    ref.invalidate(profileProvider);
                  }
                },
                icon: Icon(Icons.edit),
                label: Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
              ),
              SizedBox(height: 16),
              Text(
                profile['email'] as String? ?? '',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
              if (profile['phone'] != null) ...[
                SizedBox(height: 4),
                Text(
                  profile['phone'] as String,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              SizedBox(height: 32),

              // Technician Stats
              if (_isTechnician)
                technicianStatsAsyncValue.when(
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (error, stack) => SizedBox.shrink(),
                  data: (stats) => Column(
                    children: [
                      Card(
                        color: AppTheme.primary.withOpacity(0.1),
                        margin: EdgeInsets.only(bottom: 24),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatCard(
                                label: 'Jobs Completed',
                                value: (stats['total_jobs'] ?? 0).toString(),
                              ),
                              _buildStatCard(
                                label: 'Rating',
                                value:
                                    (stats['rating'] ?? 0.0).toStringAsFixed(1),
                              ),
                              _buildStatCard(
                                label: 'Verified',
                                value:
                                    stats['is_verified'] == true ? 'Yes' : 'No',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Menu Items
              _buildMenuItem(
                icon: Icons.history,
                title: 'Booking History',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.bookingHistory);
                },
              ),
              if (!_isTechnician)
                _buildMenuItem(
                  icon: Icons.favorite_border,
                  title: 'Favorites',
                  onTap: () {},
                ),
              if (!_isTechnician)
                _buildMenuItem(
                  icon: Icons.payment,
                  title: 'Payment Methods',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PaymentMethodsScreen()),
                    );
                  },
                ),
              _buildMenuItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SettingsScreen()),
                  );
                },
              ),
              SizedBox(height: 16),
              _buildMenuItem(
                icon: Icons.logout,
                title: 'Logout',
                onTap: _logout,
                isDestructive: true,
              ),
              SizedBox(height: 32),
              Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppTheme.error : AppTheme.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? AppTheme.error : null,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
