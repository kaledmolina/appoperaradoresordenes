import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PriorityBadge extends StatelessWidget {
  final int priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    if (priority <= 0) return const SizedBox.shrink();

    Color bgColor = Colors.orange.shade50;
    Color textColor = Colors.orange.shade800;
    Color borderColor = Colors.orange.shade200;

    if (priority >= 5) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade800;
      borderColor = Colors.red.shade200;
    } else if (priority >= 3) {
      bgColor = Colors.amber.shade50;
      textColor = Colors.amber.shade900;
      borderColor = Colors.amber.shade300;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, size: 14, color: textColor),
          const SizedBox(width: 3),
          Text(
            'Prioridad: $priority',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
