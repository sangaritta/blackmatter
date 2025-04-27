import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/Widgets/Common/loading_indicator.dart';

class ProductStatusOverlay extends StatelessWidget {
  final String userId;
  final String projectId;
  final String productId;
  final String currentStatus;

  const ProductStatusOverlay({
    super.key,
    required this.userId,
    required this.projectId,
    required this.productId,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status = data['state'] as String? ?? currentStatus;

        if (!_shouldShowOverlay(status)) {
          return const SizedBox();
        }

        // Full screen overlay with a simple, beautiful design
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.95),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getStatusTitle(status),
                    style: const TextStyle(
                      fontSize: 28,
                      fontFamily: fontNameBold,
                      color: Color(0xFF9D6BFF),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  _buildProgressStepper(status),
                  const SizedBox(height: 40),
                  Text(
                    _getStatusMessage(status),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      fontFamily: fontName,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (status == 'Approved')
                    _buildPlatformLinksButton(context, data),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _shouldShowOverlay(String status) {
    return status == 'Processing' ||
        status == 'In Review' ||
        status == 'Approved';
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'Processing':
        return 'Processing Your Release';
      case 'In Review':
        return 'Your Release Is Under Review';
      case 'Approved':
        return 'Congratulations! Your Release Is Live';
      default:
        return 'Release Status';
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'Processing':
        return 'Our servers are processing your files and metadata to ensure the highest quality before distribution. This usually takes 1-2 business days.';
      case 'In Review':
        return 'We are taking a close inspection of your music before distribution. Our team ensures your content meets all platform requirements. This should be completed within 3-5 business days.';
      case 'Approved':
        return 'Your release has been approved and is now live on distribution platforms! Click below to see your platform links.';
      default:
        return '';
    }
  }

  Widget _buildProgressStepper(String status) {
    final steps = [
      {'title': 'Processing', 'icon': Icons.settings, 'completed': true},
      {
        'title': 'In Review',
        'icon': Icons.fact_check,
        'completed': status == 'In Review' || status == 'Approved'
      },
      {
        'title': 'Approved',
        'icon': Icons.celebration,
        'completed': status == 'Approved'
      },
    ];

    return SizedBox(
      height: 100,
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isCompleted = step['completed'] as bool;
          final isActive = status == step['title'];

          final completedColor = const Color(0xFF9D6BFF);
          final inactiveColor = Colors.grey.withOpacity(0.3);

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: isCompleted ? completedColor : inactiveColor,
                        ),
                      ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? completedColor : inactiveColor,
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(
                                step['icon'] as IconData,
                                color: Colors.white,
                                size: 24,
                              )
                            : Text(
                                (index + 1).toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: isCompleted ? completedColor : inactiveColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  step['title'] as String,
                  style: TextStyle(
                    fontFamily: fontNameBold,
                    color: isActive ? Colors.white : Colors.grey,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlatformLinksButton(
      BuildContext context, Map<String, dynamic> data) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9D6BFF),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () {
        _showPlatformLinksDialog(context, data);
      },
      child: const Text(
        'View Platform Links',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: fontNameSemiBold,
        ),
      ),
    );
  }

  void _showPlatformLinksDialog(
      BuildContext context, Map<String, dynamic> data) {
    final Map<String, String> platformLinks = {
      'Spotify': data['spotifyUrl'] ?? '',
      'Apple Music': data['appleMusicUrl'] ?? '',
      'YouTube Music': data['youtubeUrl'] ?? '',
      'Deezer': data['deezerUrl'] ?? '',
      'Tidal': data['tidalUrl'] ?? '',
      'Amazon Music': data['amazonUrl'] ?? '',
    };

    // Filter out empty links
    final Map<String, String> availableLinks = {};
    platformLinks.forEach((platform, url) {
      if (url.isNotEmpty) {
        availableLinks[platform] = url;
      }
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your Release Is Available On',
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: fontNameBold,
                  color: Color(0xFF9D6BFF),
                ),
              ),
              const SizedBox(height: 24),
              if (availableLinks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Your release is live, but platform links are not yet available. Links will appear here within a few days as platforms process your release.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: fontName),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableLinks.length,
                  itemBuilder: (context, index) {
                    final platform = availableLinks.keys.elementAt(index);
                    final url = availableLinks[platform]!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(_getPlatformIcon(platform), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              platform,
                              style: const TextStyle(
                                fontFamily: fontNameBold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            tooltip: 'Copy link',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: url));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '$platform link copied to clipboard'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.open_in_new),
                            tooltip: 'Open link',
                            onPressed: () async {
                              // Use url_launcher or similar package to open the URL
                              // For now, just copy to clipboard
                              Clipboard.setData(ClipboardData(text: url));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Link copied. Use a browser to open.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'spotify':
        return Icons.music_note;
      case 'apple music':
        return Icons.apple;
      case 'youtube music':
        return Icons.play_circle_fill;
      case 'deezer':
        return Icons.headphones;
      case 'tidal':
        return Icons.waves;
      case 'amazon music':
        return Icons.shopping_cart;
      default:
        return Icons.link;
    }
  }
}
