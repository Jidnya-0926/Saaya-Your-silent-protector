import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../theme/app_theme.dart';
import '../widgets/emergency_button.dart';
import 'security_verification_screen.dart';
import 'change_voice_code_screen.dart';
import '../services/sms_service.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> _userDocRef(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream(String uid) {
    return _userDocRef(uid).snapshots();
  }

  Future<void> _handleSOS(BuildContext context) async {
    // Trigger SMS SOS Logic (One-time protection handled inside service)
    SMSService().sendSOS();

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is required for live tracking during emergencies.',
              ),
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied. Please enable in settings.',
            ),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.pushNamed(context, '/emergency-active');
    }
  }

  Future<void> _openSecurityVerification(BuildContext context) async {
    final user = _user;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (r) => false);
      return;
    }

    try {
      final snap = await _userDocRef(user.uid).get();
      final data = snap.data() ?? {};

      final storedQuestion =
          (data['securityQuestion'] ?? data['selectedQuestion'] ?? data['question'] ?? '')
              .toString()
              .trim();

      final storedAnswer =
          (data['securityAnswer'] ?? data['answer'] ?? '')
              .toString()
              .trim();

      if (storedQuestion.isEmpty || storedAnswer.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Security question/answer not found. Please complete profile setup again.',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SecurityVerificationScreen(
            storedQuestion: storedQuestion,
            storedAnswer: storedAnswer,
            onVerified: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangeVoiceCodeScreen(),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load security info: $e')),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Google sign out (safe even if user logged in with email)
      await GoogleSignIn().signOut();
    } catch (_) {}

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of Saaya?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(context);
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: AppTheme.primaryRed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    // If somehow user is not signed in
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in first')),
      );
    }

    return Scaffold(
      key: scaffoldKey,
      endDrawer: _buildProfileDrawer(context, user.uid),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saaya',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: AppTheme.primaryRed,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Your Silent Protector',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => scaffoldKey.currentState?.openEndDrawer(),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey.shade100,
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            EmergencyButton(
              onTap: () => _handleSOS(context),
            ),
            const SizedBox(height: 48),
            const Text(
              'Say "Help Me" or tap above',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF5C6672),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.location_on,
                          label: 'Share Location',
                          iconColor: const Color(0xFF2196F3),
                          bgColor: const Color(0xFFE3F2FD),
                          onTap: () => Navigator.pushNamed(context, '/live-location'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.phone_in_talk,
                          label: 'Emergency Call',
                          iconColor: const Color(0xFF4CAF50),
                          bgColor: const Color(0xFFE8F5E9),
                          onTap: () => Navigator.pushNamed(context, '/emergency-contacts'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _TestVoiceButton(
                    onTap: () => Navigator.pushNamed(context, '/voice-setup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDrawer(BuildContext context, String uid) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          bottomLeft: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _userDocStream(uid),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? {};

            final name = (data['name'] ?? '').toString().trim();
            final phone = (data['phone'] ?? '').toString().trim();
            final email = (_user?.email ?? '').toString().trim();

            final displayName = name.isNotEmpty ? name : 'User';
            // ✅ show phone instead of "Member"
            final subtitle = phone.isNotEmpty ? phone : (email.isNotEmpty ? email : ' ');

            return Column(
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFFF1F4F8),
                        child: Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3238),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Divider(indent: 24, endIndent: 24),
                const SizedBox(height: 8),

                _DrawerItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Secret Voice Code',
                  onTap: () {
                    Navigator.pop(context);
                    _openSecurityVerification(context);
                  },
                ),

                const Spacer(),
                const Divider(indent: 24, endIndent: 24),
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  label: 'Log Out',
                  textColor: AppTheme.primaryRed,
                  iconColor: AppTheme.primaryRed,
                  onTap: () => _showLogoutDialog(context),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.grey.shade700, size: 22),
        title: Text(
          label,
          style: TextStyle(
            color: textColor ?? const Color(0xFF2D3238),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F4F8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3238),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestVoiceButton extends StatelessWidget {
  final VoidCallback onTap;

  const _TestVoiceButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F4F8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              'Test Voice Activation',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
