import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyticsBarChartCard extends StatelessWidget {
  final String title;
  final Map<String, num> data;
  final bool isCurrency;
  final String emptyLabel;

  const AnalyticsBarChartCard({
    super.key,
    required this.title,
    required this.data,
    required this.isCurrency,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = entries.take(6).toList();
    final maxValue = topEntries.isEmpty
        ? 1.0
        : topEntries
            .map((e) => e.value.toDouble())
            .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171A21),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          if (topEntries.isEmpty)
            Text(
              emptyLabel,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            )
          else
            ...topEntries.map((entry) {
              final ratio = maxValue == 0 ? 0.0 : entry.value.toDouble() / maxValue;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCurrency
                              ? '₦${entry.value.toStringAsFixed(0)}'
                              : '${entry.value}',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFC29B40),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFC29B40),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
