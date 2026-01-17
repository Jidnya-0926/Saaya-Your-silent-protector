import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/contact_card.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();

  // Initial list of contacts (Mocked data)
  final List<Map<String, String>> _contacts = [
    {'name': 'Mom', 'relation': 'Parent', 'phone': '+1 234 567 8901'},
    {'name': 'John (Brother)', 'relation': 'Sibling', 'phone': '+1 987 654 3210'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  void _saveContact() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _contacts.add({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'relation': _relationController.text.trim().isEmpty 
              ? 'Contact' 
              : _relationController.text.trim(),
        });
      });

      _nameController.clear();
      _phoneController.clear();
      _relationController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact added successfully!'),
          backgroundColor: AppTheme.secondaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Contacts'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                    '${_contacts.length}/5',
                    style: const TextStyle(
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            if (_contacts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Text('No contacts added yet.', style: TextStyle(color: Colors.grey)),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: _contacts.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final contact = entry.value;
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
                  }).toList(),
                ),
              ),

            const Divider(height: 48, thickness: 1, indent: 24, endIndent: 24),

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
                    _buildTextField('Contact Name', 'Enter name', Icons.person_outline, _nameController),
                    const SizedBox(height: 24),
                    _buildTextField('Phone Number', 'Enter phone number', Icons.phone_android_outlined, _phoneController, keyboardType: TextInputType.phone),
                    const SizedBox(height: 24),
                    _buildTextField('Relation (Optional)', 'e.g. Brother, Friend', Icons.people_outline, _relationController),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _saveContact,
                      child: const Text('Save Contact'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, IconData icon, TextEditingController controller, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3238)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
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
              borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1.5),
            ),
          ),
          validator: (value) {
            if (label != 'Relation (Optional)' && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}
