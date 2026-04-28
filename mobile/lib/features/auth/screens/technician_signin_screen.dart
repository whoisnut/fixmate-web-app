import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class TechnicianSigninScreen extends ConsumerStatefulWidget {
  const TechnicianSigninScreen({super.key});

  @override
  ConsumerState<TechnicianSigninScreen> createState() =>
      _TechnicianSigninScreenState();
}

class _TechnicianSigninScreenState extends ConsumerState<TechnicianSigninScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showPassword = false;

  // Login controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Register controllers
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerBioController = TextEditingController();
  final List<String> _selectedSpecialties = [];
  final List<String> _documents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    _registerBioController.dispose();
    super.dispose();
  }

  Future<void> _handleTechnicianLogin() async {
    if (_loginEmailController.text.isEmpty ||
        _loginPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    await ref.read(authStateProvider.notifier).loginTechnician(
          email: _loginEmailController.text,
          password: _loginPasswordController.text,
        );

    // Just navigate after a short delay to ensure state is updated
    Future.delayed(const Duration(milliseconds: 500), () {
      final authState = ref.read(authStateProvider);
      if (authState.toString().contains('_Authenticated')) {
        Navigator.of(context).pushReplacementNamed('/technician-home');
      }
    });
  }

  Future<void> _handleTechnicianRegister() async {
    if (_registerNameController.text.isEmpty ||
        _registerEmailController.text.isEmpty ||
        _registerPhoneController.text.isEmpty ||
        _registerPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    await ref.read(authStateProvider.notifier).registerTechnician(
          name: _registerNameController.text,
          email: _registerEmailController.text,
          phone: _registerPhoneController.text,
          password: _registerPasswordController.text,
          bio: _registerBioController.text,
          specialties: _selectedSpecialties,
          documents: _documents,
        );

    // Just navigate after a short delay to ensure state is updated
    Future.delayed(const Duration(milliseconds: 500), () {
      final authState = ref.read(authStateProvider);
      if (authState.toString().contains('_Authenticated')) {
        Navigator.of(context).pushReplacementNamed('/technician-verification');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FixMate Technician'),
        elevation: 0,
      ),
      body: authState is _Loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab bar
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.login),
                      text: 'Sign In',
                    ),
                    Tab(
                      icon: Icon(Icons.app_registration),
                      text: 'Register',
                    ),
                  ],
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Sign In Tab
                      _buildSignInTab(),
                      // Register Tab
                      _buildRegisterTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSignInTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Technician Sign In',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Access your technician account',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          // Email field
          TextFormField(
            controller: _loginEmailController,
            decoration: InputDecoration(
              hintText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          // Password field
          TextFormField(
            controller: _loginPasswordController,
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            obscureText: !_showPassword,
          ),
          const SizedBox(height: 24),
          // Sign In Button
          ElevatedButton(
            onPressed: _handleTechnicianLogin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Forgot Password
          Center(
            child: TextButton(
              onPressed: () {
                // TODO: Implement forgot password
              },
              child: const Text('Forgot Password?'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Register as Technician',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your professional technician account',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          // Full Name
          TextFormField(
            controller: _registerNameController,
            decoration: InputDecoration(
              hintText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
          // Email
          TextFormField(
            controller: _registerEmailController,
            decoration: InputDecoration(
              hintText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          // Phone
          TextFormField(
            controller: _registerPhoneController,
            decoration: InputDecoration(
              hintText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          // Password
          TextFormField(
            controller: _registerPasswordController,
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          // Bio
          TextFormField(
            controller: _registerBioController,
            decoration: InputDecoration(
              hintText: 'Professional Bio',
              prefixIcon: const Icon(Icons.description_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          // Specialties
          const Text(
            'Specialties',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              'AC Repair',
              'Plumbing',
              'Electrical',
              'Carpentry',
              'Appliance Repair'
            ].map((specialty) {
              return FilterChip(
                label: Text(specialty),
                selected: _selectedSpecialties.contains(specialty),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSpecialties.add(specialty);
                    } else {
                      _selectedSpecialties.remove(specialty);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Register Button
          ElevatedButton(
            onPressed: _handleTechnicianRegister,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification Required',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'After registration, you\'ll need to upload your documents for verification. This typically takes 1-2 business days.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
