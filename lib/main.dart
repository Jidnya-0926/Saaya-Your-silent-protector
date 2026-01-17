import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/email_auth_screen.dart'; // ✅ ADD THIS
import 'screens/profile_setup_screen.dart';
import 'screens/trusted_contacts_screen.dart';
import 'screens/voice_setup_screen.dart';
import 'screens/home_dashboard.dart';
import 'screens/emergency_active_screen.dart';
import 'screens/live_tracking_screen.dart';
import 'screens/authority_view_screen.dart';
import 'screens/add_contact_screen.dart';
import 'screens/emergency_contacts_screen.dart';
import 'screens/live_location_screen.dart';

void main() async {
  // 🔥 REQUIRED for Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Firebase (VERY IMPORTANT)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SaayaApp());
}

class SaayaApp extends StatelessWidget {
  const SaayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saaya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/auth': (context) => const AuthScreen(),

        '/email-auth': (context) => const EmailAuthScreen(), // ✅ ADD THIS

        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/trusted-contacts': (context) => const TrustedContactsScreen(),
        '/add-contact': (context) => const AddContactScreen(),
        '/voice-setup': (context) => const VoiceSetupScreen(),
        '/home': (context) => const HomeDashboard(),
        '/emergency-active': (context) => const EmergencyActiveScreen(),
        '/live-tracking': (context) => const LiveTrackingScreen(),
        '/authority-view': (context) => const AuthorityViewScreen(),
        '/emergency-contacts': (context) => const EmergencyContactsScreen(),
        '/live-location': (context) => const LiveLocationScreen(),
      },
    );
  }
}
