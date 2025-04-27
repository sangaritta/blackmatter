import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';

class EarningsCard extends StatelessWidget {
  final String title;
  final double amount;
  final double growth;
  final Color mainColor;
  final VoidCallback? onDeposit;
  final VoidCallback? onTransfer;
  final bool showButtons;

  const EarningsCard({
    super.key,
    required this.title,
    required this.amount,
    required this.growth,
    required this.mainColor,
    this.onDeposit,
    this.onTransfer,
    this.showButtons = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontFamily: fontNameSemiBold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      color: mainColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${growth.abs()}%',
                      style: TextStyle(
                        color: mainColor,
                        fontSize: 12,
                        fontFamily: fontNameBold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontFamily: fontNameBold,
              shadows: [
                Shadow(
                  color: mainColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          if (showButtons) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDeposit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Deposit',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: fontNameBold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTransfer,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: mainColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Transfer',
                      style: TextStyle(
                        fontFamily: fontNameBold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
} 