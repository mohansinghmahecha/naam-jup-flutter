import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/god.dart';
import '../../../../widgets/god_counter_widget.dart';

class GodProgressSection extends StatelessWidget {
  final God currentGod;
  final double progress;
  final bool isResetting;
  final VoidCallback onTap;
  final VoidCallback onChangeName;

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
    final screenWidth = MediaQuery.of(context).size.width;

    // Adjust font size dynamically
    final baseFontSize = screenWidth < 360
        ? 50.0
        : screenWidth < 600
        ? 70.0
        : 100.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 25),

        // शीर्ष भाग — श्री टेक्स्ट
        Text(
          "||  श्री  ||",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12), // 🔹 reduced to 2px gap
        // Responsive God name text with auto-scaling
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth * 0.9;
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    currentGod.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.alkatra(
                      fontSize: baseFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 1),

        // Change Name button close to the name
        TextButton(
          onPressed: onChangeName,
          style: TextButton.styleFrom(
            foregroundColor: Colors.black, // Text color
            side: const BorderSide(
              color: Colors.black,
              width: 1,
            ), // 🔹 black border
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                100,
              ), // 🔹 full round pill shape
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            backgroundColor: Colors.white.withOpacity(
              0.1,
            ), // light background touch
          ),
          child: const Text(
            "Change Name",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Counter Widget (main tappable area)
        GodCounterWidget(
          god: currentGod,
          progress: progress,
          isResetting: isResetting,
          onTap: onTap,
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
