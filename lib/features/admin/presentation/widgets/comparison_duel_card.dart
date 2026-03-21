import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ComparisonDuelCard extends StatelessWidget {
  final String title;
  final String bestLabel;
  final String bestValue;
  final String worstLabel;
  final String worstValue;

  const ComparisonDuelCard({
    super.key,
    required this.title,
    required this.bestLabel,
    required this.bestValue,
    required this.worstLabel,
    required this.worstValue,
  });

  @override
  Widget build(BuildContext context) {
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
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Side(
                  label: 'Best',
                  name: bestLabel,
                  value: bestValue,
                  color: Colors.greenAccent,
                ),
              ),
              Container(
                width: 1,
                height: 70,
                color: Colors.white10,
              ),
              Expanded(
                child: _Side(
                  label: 'Needs Attention',
                  name: worstLabel,
                  value: worstValue,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  final String label;
  final String name;
  final String value;
  final Color color;

  const _Side({
    required this.label,
    required this.name,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: const Color(0xFFC29B40),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
