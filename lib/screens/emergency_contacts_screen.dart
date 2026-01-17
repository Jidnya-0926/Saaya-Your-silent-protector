import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'add_contact_screen.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for contacts - in a real app, this would come from a database/provider
    final List<Map<String, String>> contacts = [
      {'name': 'Mom', 'relation': 'Parent', 'phone': '+1 234 567 8901'},
      {'name': 'John (Brother)', 'relation': 'Sibling', 'phone': '+1 987 654 3210'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
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
                      contact['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      '${contact['relation']} • ${contact['phone']}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.call, color: AppTheme.secondaryGreen),
                      onPressed: () {
                        // Mock call action
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling ${contact['name']}...')),
                        );
                      },
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
      ),
    );
  }
}
