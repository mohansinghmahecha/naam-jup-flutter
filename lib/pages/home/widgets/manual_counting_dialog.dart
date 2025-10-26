import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/god.dart';
import '../../../../providers/god_provider.dart';

void showManualCountingDialog(BuildContext context, WidgetRef ref, God god) {
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Manual Counting'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '⚠️ Please be genuine — only counts up to 50,000 are allowed.\n'
            'This will be added to the total count of the selected God.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter manual count (max 50,000)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final input = int.tryParse(controller.text.trim()) ?? 0;
            if (input <= 0 || input > 50000) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid number (1–50,000)'),
                ),
              );
              return;
            }
            await ref.read(godListProvider.notifier).addManualCount(god.id, input);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✅ Added $input to ${god.name}!')),
            );
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
