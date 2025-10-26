import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          '🔔 Notification settings UI will come here later.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
