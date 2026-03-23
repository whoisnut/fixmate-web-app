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
import 'features/services/screens/services_screen.dart';
import 'features/booking/screens/booking_screen.dart';
import 'features/booking/screens/booking_history_screen.dart';
import 'features/profile/screens/profile_screen.dart';
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
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(child: flutter_material.Text('Page not found')),
              ),
            );
        }
      },
    );
  }
}
