import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _darkMode = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notifications Section
            _buildSectionHeader('Notifications'),
            SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Enable Notifications'),
                    subtitle: Text('Receive service updates'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                    },
                  ),
                  if (_notificationsEnabled) ...[
                    Divider(),
                    SwitchListTile(
                      title: Text('Email Notifications'),
                      subtitle: Text('Send updates via email'),
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() => _emailNotifications = value);
                      },
                    ),
                    Divider(),
                    SwitchListTile(
                      title: Text('Push Notifications'),
                      subtitle: Text('Send push notifications'),
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() => _pushNotifications = value);
                      },
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 32),

            // Preferences Section
            _buildSectionHeader('Preferences'),
            SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Dark Mode'),
                    subtitle: Text('Coming soon'),
                    value: _darkMode,
                    onChanged: null,
                  ),
                  Divider(),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Language',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        DropdownButton<String>(
                          value: _language,
                          isExpanded: true,
                          items: ['English', 'Spanish', 'French', 'German']
                              .map((lang) => DropdownMenuItem(
                                    value: lang,
                                    child: Text(lang),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => _language = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Privacy & Security Section
            _buildSectionHeader('Privacy & Security'),
            SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text('Privacy Policy'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Privacy Policy - Coming soon')),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    title: Text('Terms of Service'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Terms of Service - Coming soon')),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    title: Text('Data & Privacy'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Data & Privacy - Coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // App Info Section
            _buildSectionHeader('About'),
            SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('App Version'),
                            Text('1.0.0'),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Build Number'),
                            Text('001'),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Database Version'),
                            Text('1.0'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        '© 2026 FixMate. All rights reserved.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
      ),
    );
  }
}
