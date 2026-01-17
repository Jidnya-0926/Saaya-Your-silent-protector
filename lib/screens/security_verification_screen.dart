import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SecurityVerificationScreen extends StatefulWidget {
  final VoidCallback onVerified;
  final String storedQuestion;
  final String storedAnswer;

  const SecurityVerificationScreen({
    super.key,
    required this.onVerified,
    required this.storedQuestion,
    required this.storedAnswer,
  });

  @override
  State<SecurityVerificationScreen> createState() => _SecurityVerificationScreenState();
}

class _SecurityVerificationScreenState extends State<SecurityVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedQuestion;
  final _answerController = TextEditingController();

  final List<String> _questions = [
    'Favourite Place',
    'Favourite Person',
  ];

  @override
  void initState() {
    super.initState();
    // Start with no selection as per UX guidelines "no selection by default"
    _selectedQuestion = null;
  }

  void _verify() {
    if (_formKey.currentState!.validate()) {
      // Comparison: Case-insensitive and trimmed
      if (_selectedQuestion == widget.storedQuestion &&
          _answerController.text.trim().toLowerCase() == widget.storedAnswer.trim().toLowerCase()) {
        widget.onVerified();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect password. Please try again.'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Password'),
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
                'Enter the password you set during login',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3238),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verify your identity using your security question.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select your Security Question',
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
                ),
                value: _selectedQuestion,
                items: _questions.map((String q) {
                  return DropdownMenuItem<String>(
                    value: q,
                    child: Text(q),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedQuestion = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a question' : null,
              ),
              if (_selectedQuestion != null) ...[
                const SizedBox(height: 24),
                TextFormField(
                  controller: _answerController,
                  obscureText: true, // Obscured text as per security requirement
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Enter your answer',
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
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: _verify,
                child: const Text('Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
