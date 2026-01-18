import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  CollectionReference<Map<String, dynamic>> _contactsRef(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trusted_contacts'); // ✅ ONE single source of truth
  }

  Future<void> _deleteContact(BuildContext context, String uid, String docId) async {
    try {
      await _contactsRef(uid).doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact removed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // ✅ If user is not logged in, block this screen
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Emergency Contacts'),
          centerTitle: true,
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
            child: const Text('Sign in first'),
          ),
        ),
      );
    }

    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _contactsRef(uid).orderBy('createdAt', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return Column(
            children: [
              Expanded(
                child: docs.isEmpty
                    ? const Center(
                        child: Text(
                          'No emergency contacts yet.\nTap "Add New Contact" to add one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();

                          final name = (data['name'] ?? 'Unnamed').toString();
                          final relation = (data['relation'] ?? 'Contact').toString();
                          final phone = (data['phone'] ?? '').toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                                child: const Icon(Icons.person, color: AppTheme.primaryRed),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Text(
                                '$relation • $phone',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),

                              // ✅ Call + Delete actions
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.call, color: AppTheme.secondaryGreen),
                                    onPressed: () {
                                      // For now: just show message
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Calling $name...')),
                                      );

                                      // Later you can use url_launcher:
                                      // launchUrl(Uri.parse('tel:$phone'));
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: Colors.grey.shade700),
                                    onPressed: () => _deleteContact(context, uid, doc.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/add-contact'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Contact'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
