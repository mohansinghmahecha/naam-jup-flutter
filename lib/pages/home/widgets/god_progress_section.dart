import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/god.dart';
import '../../../../widgets/god_counter_widget.dart';

class GodProgressSection extends StatelessWidget {
  final God currentGod;
  final double progress;
  final bool isResetting;
  final VoidCallback onTap;
  final VoidCallback onChangeName; // <-- callback for Change Name

  const GodProgressSection({
    super.key,
    required this.currentGod,
    required this.progress,
    required this.isResetting,
    required this.onTap,
    required this.onChangeName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Text(
            "||  श्री  ||",
            style: GoogleFonts.inter(fontSize: 18, color: Colors.black87),
          ),
        ),

        const SizedBox(height: 2),

        Text(
          currentGod.name,
          style: GoogleFonts.alkatra(
            fontSize: 100, // adjusted to fit screen better
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 0),

        // ---- Change Name Button ----
        TextButton(
          onPressed: onChangeName, // <-- use the callback
          child: const Text("Change Name", style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 20),

        GodCounterWidget(
          god: currentGod,
          progress: progress,
          isResetting: isResetting,
          onTap: onTap,
        ),
      ],
    );
  }
}
