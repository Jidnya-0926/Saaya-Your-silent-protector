import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedQuestion;

  // ✅ Controllers so we can save to Firebase
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _answerController = TextEditingController();

  bool _saving = false;

  final List<String> _questions = const [
    'Favourite Place',
    'Favourite Person',
  ];

  @override
  void initState() {
    super.initState();

    // ✅ Prefill if available (Google sign-in usually has name/photo)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not logged in')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          // ✅ Use same field names like your Firestore screenshot
          'name': _nameController.text.trim(),
          'Phone': _phoneController.text.trim(), // keeping "Phone" exactly
          'photoUrl': user.photoURL ?? '',
          'securityQuestion': _selectedQuestion ?? '',
          'securityAnswerHash': _answerController.text.trim(), // simple for now
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/trusted-contacts');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Help rescuers identify you',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade100,
                      child: const Icon(Icons.person, size: 60, color: Colors.grey),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryRed,
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // ✅ Full Name (with controller)
              _buildTextField(
                label: 'Full Name',
                hint: 'Jane Doe',
                controller: _nameController,
              ),
              const SizedBox(height: 24),

              // ✅ Phone Number (with controller)
              _buildTextField(
                label: 'Phone Number',
                hint: '+91XXXXXXXXXX',
                icon: Icons.phone_android,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 32),

              const Text(
                'Select a Security Question',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedQuestion,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                hint: const Text('Choose a question'),
                items: _questions.map((String question) {
                  return DropdownMenuItem<String>(
                    value: question,
                    child: Text(question),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedQuestion = value;
                    _answerController.clear();
                  });
                },
                validator: (value) => value == null ? 'Please select a question' : null,
              ),

              if (_selectedQuestion != null) ...[
                const SizedBox(height: 24),
                Text(
                  _selectedQuestion == 'Favourite Place'
                      ? 'Enter your favourite place'
                      : 'Enter your favourite person',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _answerController,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    hintText: 'Type your answer',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (_selectedQuestion != null &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please enter your answer';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 48),

              // ✅ Save button (writes to Firestore)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _saving ? 'Saving...' : 'Save & Continue',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}
