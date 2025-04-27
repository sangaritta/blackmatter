import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:portal/Widgets/Common/under_construction_overlay.dart';
import 'package:portal/main.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  final Map<String, Map<String, dynamic>> _platformStats = {
    'Instagram': {
      'followers': 12500,
      'engagement': 8.5,
      'posts': 45,
      'growth': 2.3,
      'color': const Color(0xFFE1306C),
      'icon': 'instagram.png',
    },
    'TikTok': {
      'followers': 25000,
      'engagement': 12.8,
      'posts': 60,
      'growth': 5.7,
      'color': const Color(0xFF000000),
      'icon': 'tiktok.png',
    },
    'YouTube': {
      'followers': 8000,
      'engagement': 6.2,
      'posts': 25,
      'growth': 1.5,
      'color': const Color(0xFFFF0000),
      'icon': 'youtube.png',
    },
    'Spotify': {
      'followers': 15000,
      'engagement': 4.5,
      'posts': 120,
      'growth': 3.2,
      'color': const Color(0xFF1DB954),
      'icon': 'spotify.png',
    },
  };

  @override
  Widget build(BuildContext context) {
    return UnderConstructionOverlay(
      show: showUnderConstructionOverlay,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Marketing Insights',
              style: TextStyle(
                fontSize: 28,
                fontFamily: fontNameBold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your social media performance across platforms',
              style: TextStyle(
                fontSize: 16,
                fontFamily: fontNameSemiBold,
                color: Theme.of(context).primaryColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Platform Stats Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _platformStats.length,
              itemBuilder: (context, index) {
                String platform = _platformStats.keys.elementAt(index);
                Map<String, dynamic> stats = _platformStats[platform]!;
                return _buildPlatformCard(platform, stats);
              },
            ),

            const SizedBox(height: 32),

            // Engagement Chart
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B2C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Engagement Rate',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: fontNameBold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontFamily: fontNameSemiBold,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Sun'
                                ];
                                if (value.toInt() >= 0 &&
                                    value.toInt() < days.length) {
                                  return Text(
                                    days[value.toInt()],
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontFamily: fontNameSemiBold,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 4),
                              FlSpot(1, 3.5),
                              FlSpot(2, 4.5),
                              FlSpot(3, 5),
                              FlSpot(4, 4.8),
                              FlSpot(5, 5.2),
                              FlSpot(6, 5.5),
                            ],
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement post creation
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Post'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildPlatformCard(String platform, Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/dsps/${stats['icon']}',
                height: 24,
                width: 24,
              ),
              const SizedBox(width: 8),
              Text(
                platform,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: fontNameBold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${stats['followers'].toString()} followers',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: fontNameBold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${stats['engagement']}% engagement',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontFamily: fontNameSemiBold,
                ),
              ),
              Row(
                children: [
                  Icon(
                    stats['growth'] > 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: stats['growth'] > 0 ? Colors.green : Colors.red,
                    size: 14,
                  ),
                  Text(
                    '${stats['growth']}%',
                    style: TextStyle(
                      color: stats['growth'] > 0 ? Colors.green : Colors.red,
                      fontSize: 14,
                      fontFamily: fontNameSemiBold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
