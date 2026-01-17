import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _loadingGoogle = false;

  bool _isProfileComplete(Map<String, dynamic>? data) {
    if (data == null) return false;

    final name = (data['name'] ?? '').toString().trim();
    final phone = (data['phone'] ?? '').toString().trim();

    final securityQuestion = (data['securityQuestion'] ?? '').toString().trim();
    // NOTE: your DB screenshot showed securityAnswerHash, but your UI takes plain answer.
    // We'll accept either securityAnswerHash or securityAnswer
    final securityAnswerHash = (data['securityAnswerHash'] ?? '').toString().trim();
    final securityAnswer = (data['securityAnswer'] ?? '').toString().trim();

    return name.isNotEmpty &&
        phone.isNotEmpty &&
        securityQuestion.isNotEmpty &&
        (securityAnswerHash.isNotEmpty || securityAnswer.isNotEmpty);
  }

  Future<void> _goNextAfterLogin(User user) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await docRef.get();

    if (!snap.exists) {
      // First time: create minimal doc
      await docRef.set({
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/profile-setup');
      return;
    }

    final data = snap.data() as Map<String, dynamic>?;
    final complete = _isProfileComplete(data);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, complete ? '/home' : '/profile-setup');
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _loadingGoogle = true);

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _loadingGoogle = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) throw Exception('Google sign-in failed: user is null');

      // Only merge base fields; DO NOT overwrite profile fields
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await _goNextAfterLogin(user);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  void _continueWithEmail() {
    Navigator.pushNamed(context, '/email-auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield, size: 60, color: AppTheme.primaryRed),
              ),
              const SizedBox(height: 32),
              Text('Welcome', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue to SAFE-VOICE',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 48),

              _SocialAuthButton(
                icon: Icons.g_mobiledata,
                text: _loadingGoogle ? 'Signing in...' : 'Continue with Google',
                onPressed: _loadingGoogle ? null : _continueWithGoogle,
                isPrimary: false,
              ),
              const SizedBox(height: 16),

              _SocialAuthButton(
                icon: Icons.email_outlined,
                text: 'Continue with Email',
                onPressed: _continueWithEmail,
                isPrimary: true,
              ),

              const Spacer(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy. Your safety is our priority.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _SocialAuthButton({
    required this.icon,
    required this.text,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.black87 : Colors.white,
          foregroundColor: isPrimary ? Colors.white : Colors.black87,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
