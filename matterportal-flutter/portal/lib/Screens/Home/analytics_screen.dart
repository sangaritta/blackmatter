import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import the fl_chart package
import 'package:portal/Widgets/Common/under_construction_overlay.dart';
import 'package:portal/main.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UnderConstructionOverlay(
      show: showUnderConstructionOverlay,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Analytics',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              // Use LayoutBuilder to get the available width
              builder: (context, constraints) {
                // Calculate the number of cards per row based on width
                int cardsPerRow = (constraints.maxWidth / 300)
                    .floor(); // Assuming each card is 200 wide
                cardsPerRow = cardsPerRow < 1
                    ? 1
                    : cardsPerRow; // Ensure at least 1 card per row
                cardsPerRow = cardsPerRow > 3
                    ? 3
                    : cardsPerRow; // Limit to max 3 cards per row
                return Column(
                  children: [
                    for (int i = 0;
                        i < 6;
                        i += cardsPerRow) // Iterate in steps of cardsPerRow
                      SizedBox(
                        width: constraints.maxWidth, // Use full available width
                        child: Row(
                          children: List.generate(
                            cardsPerRow,
                            (index) => Expanded(
                              child: AnalyticsCard(
                                title: 'Stream Analytics',
                                data: [
                                  ChartData('Platform', 'YouTube'),
                                  ChartData('Total Views', '10,000'),
                                  ChartData('Average Watch Time', '5 minutes'),
                                ],
                                chartData: const [
                                  FlSpot(0, 10),
                                  FlSpot(1, 15),
                                  FlSpot(2, 20),
                                  FlSpot(3, 25),
                                  FlSpot(4, 30),
                                  FlSpot(5, 35),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class AnalyticsCard extends StatelessWidget {
  final String title;
  final List<ChartData> data;
  final List<FlSpot> chartData;
  final bool showChart;

  const AnalyticsCard({
    super.key,
    required this.title,
    required this.data,
    required this.chartData,
    this.showChart = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Data Display
            for (var item in data)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.x,
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    item.y,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            // Spline Chart
            if (showChart)
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    // ... existing code ...
                    lineBarsData: [
                      LineChartBarData(
                        // ... existing code ...
                        spots: chartData,
                        // ... existing code ...
                      ),
                    ],
                    // ... existing code ...
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  ChartData(this.x, this.y);
  final String x;
  final String y;
}
