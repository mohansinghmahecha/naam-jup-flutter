import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onManualCounting;
  final VoidCallback onNotificationTap;
  // final VoidCallback onChangeName;

  const ActionButtons({
    super.key,
    required this.onManualCounting,
    required this.onNotificationTap,
    // required this.onChangeName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ElevatedButton(
        //   onPressed: onChangeName,
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: Colors.black,
        //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        //   ),
        //   child: const Text(
        //     "Change Name",
        //     style: TextStyle(color: Colors.white, fontSize: 16),
        //   ),
        // ),
        // const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.edit, color: Colors.white),
          label: const Text(
            "Manual Counting",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          onPressed: onManualCounting,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.notifications, color: Colors.white),
          label: const Text(
            "Notification Settings",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          onPressed: onNotificationTap,
        ),
      ],
    );
  }
}
