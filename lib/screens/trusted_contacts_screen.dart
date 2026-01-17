import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/contact_card.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  final List<Map<String, String>> _contacts = [
    {'name': 'Mom', 'relation': 'Parent', 'phone': '+1 234 567 8901'},
    {'name': 'John (Brother)', 'relation': 'Sibling', 'phone': '+1 987 654 3210'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Contacts'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_contacts.length}/5',
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
                itemCount: _contacts.length + 1,
                itemBuilder: (context, index) {
                  if (index == _contacts.length) {
                    return _buildAddContactButton();
                  }
                  final contact = _contacts[index];
                  return ContactCard(
                    name: contact['name']!,
                    relation: contact['relation']!,
                    phone: contact['phone']!,
                    onDelete: () {
                      setState(() {
                        _contacts.removeAt(index);
                      });
                    },
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
  }

  Widget _buildAddContactButton() {
    return InkWell(
      onTap: () {},
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Add Trusted Contact',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
