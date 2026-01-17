import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/map_placeholder.dart';

class AuthorityViewScreen extends StatelessWidget {
  const AuthorityViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Incident Control'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar (Optional/Minimal for mobile)
          if (MediaQuery.of(context).size.width > 600)
            Container(
              width: 250,
              color: Colors.white,
              child: const Center(child: Text('Sidebar')),
            ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Incident #8492',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Sarah J. • Active since 4 mins',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const StatusBadge(text: 'HIGH SEVERITY', color: AppTheme.primaryRed),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 400,
                              child: MapPlaceholderWidget(label: 'Live Incident Tracking'),
                            ),
                            const SizedBox(height: 24),
                            _buildAudioPlayerCard(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            _buildDispatchStatusCard(),
                            const SizedBox(height: 24),
                            _buildMovementTimeline(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Audio Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.play_circle_filled, size: 48, color: AppTheme.primaryRed),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: 0.4,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0:12', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        Text('0:30', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dispatch Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          _buildDispatchStep('Units Dispatched', 'Unit 4B, Unit 2A', true),
          _buildDispatchStep('Estimated Arrival', '3 mins', true),
          _buildDispatchStep('Police Notification', 'Confirmed', true),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryGreen),
            child: const Text('Update Dispatch'),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchStep(String label, String value, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMovementTimeline() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          _buildTimelineItem('Stopped', '10:52 PM'),
          _buildTimelineItem('Moving North', '10:50 PM'),
          _buildTimelineItem('Moving North', '10:48 PM'),
          _buildTimelineItem('SOS Triggered', '10:45 PM'),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String event, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(event, style: TextStyle(color: Colors.grey.shade700)),
          Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }
}
