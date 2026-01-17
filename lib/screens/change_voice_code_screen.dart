import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChangeVoiceCodeScreen extends StatefulWidget {
  const ChangeVoiceCodeScreen({super.key});

  @override
  State<ChangeVoiceCodeScreen> createState() => _ChangeVoiceCodeScreenState();
}

class _ChangeVoiceCodeScreenState extends State<ChangeVoiceCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _confirmController = TextEditingController();

  void _updateCode() {
    if (_formKey.currentState!.validate()) {
      // Logic to update code would go here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Secret voice code updated successfully!'),
          backgroundColor: AppTheme.secondaryGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Secret Code'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set a new voice keyword to trigger your emergency alerts.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              _buildCodeField('New Secret Keyword', _codeController, 'Eg: Help Me Now'),
              const SizedBox(height: 24),
              _buildCodeField('Confirm Keyword', _confirmController, 'Repeat your keyword'),
              const Spacer(),
              ElevatedButton(
                onPressed: _updateCode,
                child: const Text('Confirm & Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeField(String label, TextEditingController controller, String hint) {
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
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a keyword';
            }
            if (controller == _confirmController && value != _codeController.text) {
              return 'Keywords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }
}
