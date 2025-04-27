import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/Widgets/Finance/earnings_card.dart';
import 'package:portal/Widgets/Finance/platform_earnings_chart.dart';
import 'package:portal/Widgets/Finance/track_earnings_list.dart';
import 'package:portal/Widgets/Finance/royalty_splits_card.dart';

class FinanceDashboard extends StatefulWidget {
  const FinanceDashboard({super.key});

  @override
  State<FinanceDashboard> createState() => _FinanceDashboardState();
}

class _FinanceDashboardState extends State<FinanceDashboard> {
  final ScrollController _scrollController = ScrollController();
  final DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0B1F),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontFamily: fontNameBold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Track your earnings and manage royalty splits',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontFamily: fontNameSemiBold,
                      ),
                    ),
                  ],
                ),
                // Date Range Selector
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B2C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedDateRange.start.toString().substring(0, 10)} - ${_selectedDateRange.end.toString().substring(0, 10)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: fontNameSemiBold,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column - Charts and Stats
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Earnings Cards Row
                        Row(
                          children: [
                            Expanded(
                              child: EarningsCard(
                                title: 'Total Balance',
                                amount: 80300,
                                growth: 12,
                                mainColor: Colors.blue,
                                onDeposit: () {},
                                onTransfer: () {},
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: EarningsCard(
                                title: 'Monthly Earnings',
                                amount: 12450,
                                growth: 8.5,
                                mainColor: Colors.green,
                                showButtons: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Platform Earnings Chart
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1B2C),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Earnings by Platform',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontFamily: fontNameBold,
                                  ),
                                ),
                                SizedBox(height: 24),
                                Expanded(
                                  child: PlatformEarningsChart(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right Column - Track List and Royalty Management
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B2C),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Track Earnings Header
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Track Earnings',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontFamily: fontNameBold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    // Navigate to detailed track list
                                  },
                                  icon: const Icon(Icons.list, size: 18),
                                  label: const Text('View All'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Track List
                          const Expanded(
                            child: TrackEarningsList(),
                          ),

                          // Royalty Management Button
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => const RoyaltySplitsCard(
                                    trackTitle: 'Manage Royalty Splits',
                                    splits: {'Artist': 1.0},
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.pie_chart),
                                  SizedBox(width: 8),
                                  Text(
                                    'Manage Royalty Splits',
                                    style: TextStyle(
                                      fontFamily: fontNameBold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
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
    );
  }
}
