import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';

class RoyaltySplitsCard extends StatelessWidget {
  final String trackTitle;
  final Map<String, double> splits;
  final VoidCallback? onEdit;

  const RoyaltySplitsCard({
    super.key,
    required this.trackTitle,
    required this.splits,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trackTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: fontNameBold,
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit,
                  color: Colors.grey,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Splits List
          ...splits.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    fontFamily: fontNameSemiBold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${(entry.value * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: fontNameBold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 100,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: entry.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
} 