import 'package:flutter/material.dart';
import '../../../../models/god.dart';

class CountSummaryCard extends StatelessWidget {
  final God currentGod;

  const CountSummaryCard({super.key, required this.currentGod});

  @override
  Widget build(BuildContext context) {
    return Center(
      // <-- centers the card horizontally
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // <-- shrink to fit content
          children: [
            Text(
              "Malla: ${currentGod.sessionCount % 108} / 108",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              "Total: ${currentGod.totalCount}",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
