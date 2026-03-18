import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActiveServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? status;
  final String? eta;
  final String? trailingText;
  final VoidCallback? onTap;

  const ActiveServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.status,
    this.eta,
    this.trailingText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFC29B40),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  if (status != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      status!,
                      style: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (eta != null)
                  Text(
                    eta!,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFC29B40),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (trailingText != null)
                  Text(
                    trailingText!,
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 11,
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
