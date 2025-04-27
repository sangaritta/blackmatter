import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/Widgets/Finance/earnings_card.dart';
import 'package:portal/Widgets/Finance/platform_earnings_chart.dart';
import 'package:portal/Widgets/Finance/track_earnings_list.dart';
import 'package:portal/Widgets/Finance/royalty_splits_card.dart';

class FinanceDashboard extends StatelessWidget {
  const FinanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Financial Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: fontNameBold,
              ),
            ),
            const SizedBox(height: 24),

            // Earnings Cards Row
            Row(
              children: [
                Expanded(
                  child: EarningsCard(
                    title: 'Total Earnings',
                    amount: 4441.25,
                    growth: 12.5,
                    mainColor: Colors.blue,
                    onDeposit: () {},
                    onTransfer: () {},
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: EarningsCard(
                    title: 'Available Balance',
                    amount: 2890.75,
                    growth: 8.2,
                    mainColor: Colors.green,
                    onDeposit: () {},
                    onTransfer: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Platform Earnings Chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.1),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Platform Earnings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: fontNameBold,
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: PlatformEarningsChart(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Track Earnings and Royalty Splits
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Track Earnings List
                const Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track Earnings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: fontNameBold,
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        height: 400,
                        child: TrackEarningsList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Royalty Splits
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Royalty Splits',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: fontNameBold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RoyaltySplitsCard(
                        trackTitle: 'Summer Vibes',
                        splits: const {
                          'John Doe': 0.6,
                          'Jane Smith': 0.4,
                        },
                        onEdit: () {},
                      ),
                      const SizedBox(height: 16),
                      RoyaltySplitsCard(
                        trackTitle: 'Midnight Dreams',
                        splits: const {
                          'Jane Smith': 1.0,
                        },
                        onEdit: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 