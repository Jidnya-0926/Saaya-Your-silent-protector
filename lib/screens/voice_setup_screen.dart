import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VoiceSetupScreen extends StatefulWidget {
  const VoiceSetupScreen({super.key});

  @override
  State<VoiceSetupScreen> createState() => _VoiceSetupScreenState();
}

class _VoiceSetupScreenState extends State<VoiceSetupScreen> with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isFinished = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _waveController.repeat();
    });
    
    // Simulate recording for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isFinished = true;
          _waveController.stop();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Keyword')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Set a secret phrase to trigger SOS',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const Spacer(),
            if (!_isFinished) ...[
              _buildRecordingUI(),
              const SizedBox(height: 48),
              const Text(
                'Tap the button below and say your\nsecret word loudly',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black87),
              ),
            ] else ...[
              _buildSuccessUI(),
            ],
            const Spacer(),
            if (!_isFinished)
              ElevatedButton(
                onPressed: _isRecording ? null : _startRecording,
                child: Text(_isRecording ? 'Listening...' : 'Start Recording'),
              )
            else
              Column(
                children: [
                  OutlinedButton(
                    onPressed: () => setState(() => _isFinished = false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(Icons.refresh), SizedBox(width: 8), Text('Retake')],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryGreen),
                    child: const Text('Finish Setup'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingUI() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            return Icon(
              Icons.mic_rounded,
              size: 80,
              color: _isRecording ? AppTheme.primaryRed : Colors.grey.shade400,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSuccessUI() {
    return Column(
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: AppTheme.secondaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            size: 100,
            color: AppTheme.secondaryGreen,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Code Set!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.secondaryGreen),
        ),
        const SizedBox(height: 8),
        const Text(
          '"Help me now"',
          style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ],
    );
  }
}
