import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/contact_card.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  static const int _maxContacts = 5;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  User get _user {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      throw Exception('User not logged in');
    }
    return u;
  }

  /// ✅ IMPORTANT: This MUST match your rules + TrustedContactsScreen
  /// users/{uid}/trusted_contacts/{contactId}
  CollectionReference<Map<String, dynamic>> _contactsRef() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('trusted_contacts');
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final relation = _relationController.text.trim().isEmpty
          ? 'Contact'
          : _relationController.text.trim();

      // ✅ Prevent more than 5 contacts
      final currentCountSnap = await _contactsRef().count().get();
      final currentCount = currentCountSnap.count ?? 0;

      if (currentCount >= _maxContacts) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can add maximum 5 trusted contacts.'),
          ),
        );
        return;
      }

      await _contactsRef().add({
        'name': name,
        'phone': phone,
        'relation': relation,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      _nameController.clear();
      _phoneController.clear();
      _relationController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact added successfully!'),
          backgroundColor: AppTheme.secondaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add contact: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteContact(String docId) async {
    try {
      await _contactsRef().doc(docId).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If user is logged out somehow, show message
    if (FirebaseAuth.instance.currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in first')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Contacts'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _contactsRef().orderBy('createdAt', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section A: Existing Trusted Contacts
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trusted Contacts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3238),
                        ),
                      ),
                      Text(
                        '${docs.length}/$_maxContacts',
                        style: const TextStyle(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                if (docs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                    child: Text(
                      'No contacts added yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: docs.map((doc) {
                        final data = doc.data();
                        final name = (data['name'] ?? '').toString();
                        final phone = (data['phone'] ?? '').toString();
                        final relation =
                            (data['relation'] ?? 'Contact').toString();

                        return ContactCard(
                          name: name.isEmpty ? 'Unnamed' : name,
                          relation: relation.isEmpty ? 'Contact' : relation,
                          phone: phone,
                          onDelete: () => _deleteContact(doc.id),
                        );
                      }).toList(),
                    ),
                  ),

                const Divider(
                  height: 48,
                  thickness: 1,
                  indent: 24,
                  endIndent: 24,
                ),

                // Section B: Add New Contact Form
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add New Contact',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3238),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter details for your trusted emergency contact.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 32),

                        _buildTextField(
                          'Contact Name',
                          'Enter name',
                          Icons.person_outline,
                          _nameController,
                        ),
                        const SizedBox(height: 24),

                        _buildTextField(
                          'Phone Number',
                          'Enter phone number',
                          Icons.phone_android_outlined,
                          _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 24),

                        _buildTextField(
                          'Relation (Optional)',
                          'e.g. Brother, Friend',
                          Icons.people_outline,
                          _relationController,
                        ),
                        const SizedBox(height: 40),

                        ElevatedButton(
                          onPressed: _saving ? null : _saveContact,
                          child: Text(_saving ? 'Saving...' : 'Save Contact'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF2D3238),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey, size: 20),
            filled: true,
            fillColor: const Color(0xFFF8F9FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.primaryRed,
                width: 1.5,
              ),
            ),
          ),
          validator: (value) {
            if (label != 'Relation (Optional)' &&
                (value == null || value.trim().isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}
