import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/map_placeholder.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryRed.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryRed),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User is moving',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
                      ),
                      Text(
                        'Last updated: Just now',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    minimumSize: const Size(100, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('POLICE', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Expanded(
            child: MapPlaceholderWidget(label: 'Tracking Sarah J.'),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _StatusHistoryItem(
                  time: '10:45 PM',
                  event: 'Emergency Triggered',
                  location: 'West 1st St, Los Angeles',
                  isLast: false,
                ),
                const _StatusHistoryItem(
                  time: '10:47 PM',
                  event: 'Location Updated',
                  location: 'Broad Ave, Los Angeles',
                  isLast: true,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share Link'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Call Sarah'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryGreen,
                          minimumSize: const Size(0, 56),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHistoryItem extends StatelessWidget {
  final String time;
  final String event;
  final String location;
  final bool isLast;

  const _StatusHistoryItem({
    required this.time,
    required this.event,
    required this.location,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isLast ? AppTheme.primaryRed : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(event, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
              Text(location, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
