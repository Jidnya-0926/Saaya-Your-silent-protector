import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/contact_card.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  static const int _maxContacts = 5;

  CollectionReference<Map<String, dynamic>> _contactsRef(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trusted_contacts'); // ✅ ONLY THIS
  }

  Future<void> _deleteContact(String uid, String contactDocId) async {
    try {
      await _contactsRef(uid).doc(contactDocId).delete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete contact: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // ✅ Wait for auth state (prevents permission denied during startup)
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        // Still checking auth
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnap.data;

        // Not logged in
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Trusted Contacts')),
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/auth'),
                child: const Text('Sign in first'),
              ),
            ),
          );
        }

        final uid = user.uid;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _contactsRef(uid)
              .orderBy('createdAt', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Trusted Contacts')),
                body: Center(child: Text('Error: ${snapshot.error}')),
              );
            }

            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final docs = snapshot.data!.docs;
            final count = docs.length;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Trusted Contacts'),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count/$_maxContacts',
                          style: const TextStyle(
                            color: AppTheme.primaryRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'They will receive your SOS alerts',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: ListView.builder(
                        itemCount: count + 1,
                        itemBuilder: (context, index) {
                          if (index == count) {
                            return _buildAddContactButton(
                              enabled: count < _maxContacts,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/add-contact',
                              ),
                            );
                          }

                          final doc = docs[index];
                          final data = doc.data();

                          final name = (data['name'] ?? '').toString();
                          final relation = (data['relation'] ?? '').toString();
                          final phone = (data['phone'] ?? '').toString();

                          return ContactCard(
                            name: name.isEmpty ? 'Unnamed' : name,
                            relation:
                                relation.isEmpty ? 'Contact' : relation,
                            phone: phone,
                            onDelete: () => _deleteContact(uid, doc.id),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/voice-setup'),
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddContactButton({
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add,
                  color: enabled ? Colors.grey : Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                enabled ? 'Add Trusted Contact' : 'Max 5 contacts reached',
                style: TextStyle(
                  color: enabled ? Colors.grey : Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
