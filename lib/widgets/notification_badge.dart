import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final Color color;
  final double size;

  const NotificationBadge({
    super.key,
    required this.count,
    this.color = Colors.red,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Center(
        child: Text(
          count > 9 ? '9+' : count.toString(),
          style: GoogleFonts.inter(
            fontSize: size * 0.6,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
