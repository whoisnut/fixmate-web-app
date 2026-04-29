import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as flutter_material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/technician/screens/technician_home_screen.dart';
import 'features/technician/screens/technician_profile_setup_screen.dart';
import 'features/services/screens/services_screen.dart';
import 'features/booking/screens/booking_screen.dart';
import 'features/booking/screens/booking_history_screen.dart';
import 'features/booking/screens/job_tracking_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/review/screens/review_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'models/service.dart';

void main() {
  runApp(const ProviderScope(child: FixMateApp()));
}

class FixMateApp extends StatelessWidget {
  const FixMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.splash:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case AppRoutes.onboarding:
            return MaterialPageRoute(builder: (_) => const OnboardingScreen());
          case AppRoutes.login:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case AppRoutes.register:
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case AppRoutes.home:
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case AppRoutes.technicianHome:
            return MaterialPageRoute(
                builder: (_) => const TechnicianHomeScreen());
          case AppRoutes.services:
            final category = settings.arguments as Category;
            return MaterialPageRoute(
              builder: (_) => ServicesScreen(category: category),
            );
          case AppRoutes.booking:
            final service = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => BookingScreen(service: service),
            );
          case AppRoutes.bookingHistory:
            return MaterialPageRoute(
                builder: (_) => const BookingHistoryScreen());
          case AppRoutes.profile:
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case '/technician-profile-setup':
            return MaterialPageRoute(
                builder: (_) => const TechnicianProfileSetupScreen());
          case '/job-tracking':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => JobTrackingScreen(
                bookingId: args['bookingId']!,
                technicianName: args['technicianName']!,
              ),
            );
          case '/review':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => ReviewScreen(
                bookingId: args['bookingId']!,
                technicianName: args['technicianName']!,
                technicianId: args['technicianId']!,
              ),
            );
          case '/chat':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => ChatScreen(
                bookingId: args['bookingId']!,
                otherUserName: args['otherUserName']!,
                otherUserId: args['otherUserId']!,
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: flutter_material.Text('Page not found')),
              ),
            );
        }
      },
    );
  }
}
