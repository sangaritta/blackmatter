import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/Models/track_earnings.dart';

class TrackEarningsList extends StatelessWidget {
  const TrackEarningsList({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for demonstration
    final List<TrackEarnings> tracks = [
      TrackEarnings(
        trackId: '1',
        title: 'Summer Vibes',
        artist: 'John Doe',
        totalEarnings: 2590.50,
        platformEarnings: {
          'Spotify': 1200.00,
          'Apple Music': 800.50,
          'YouTube': 590.00,
        },
        royaltySplits: {
          'John Doe': 0.6,
          'Jane Smith': 0.4,
        },
        lastUpdated: DateTime.now(),
      ),
      TrackEarnings(
        trackId: '2',
        title: 'Midnight Dreams',
        artist: 'Jane Smith',
        totalEarnings: 1850.75,
        platformEarnings: {
          'Spotify': 900.00,
          'Apple Music': 600.75,
          'YouTube': 350.00,
        },
        royaltySplits: {
          'Jane Smith': 1.0,
        },
        lastUpdated: DateTime.now(),
      ),
      // Add more dummy tracks as needed
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              // Track Info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: fontNameBold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artist,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                        fontFamily: fontNameSemiBold,
                      ),
                    ),
                  ],
                ),
              ),

              // Earnings Info
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${track.totalEarnings.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: fontNameBold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${track.platformEarnings.length} platforms',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                        fontFamily: fontNameSemiBold,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Button
              IconButton(
                onPressed: () {
                  // Show detailed earnings breakdown
                },
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 