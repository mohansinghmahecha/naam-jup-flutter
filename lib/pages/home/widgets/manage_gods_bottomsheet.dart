import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/god.dart';
import '../../../../providers/god_provider.dart';
import '../controllers/home_controller.dart';

void showManageGodsSheet(
  BuildContext context,
  WidgetRef ref,
  HomeController controller,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final newGodController = TextEditingController();

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 10,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                // ---- Top Bar with Title and Close Button ----
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Manage Gods",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),

                // ---- List of Gods ----
                Expanded(
                  child: Consumer(
                    builder: (context, innerRef, _) {
                      final currentList = innerRef.watch(godListProvider);
                      return ListView.separated(
                        itemCount: currentList.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, index) {
                          final god = currentList[index];
                          return ListTile(
                            title: Text(
                              god.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () async {
                              await controller.setSelectedGod(
                                index,
                                innerRef.read(godListProvider),
                              );
                              Navigator.pop(context);
                            },
                            trailing: _GodActions(
                              god: god,
                              innerRef: innerRef,
                              controller: controller,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 0),

                // ---- Add New God Row ----
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newGodController,
                          decoration: const InputDecoration(
                            hintText: 'Add new God name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final name = newGodController.text.trim();
                          if (name.isNotEmpty) {
                            await ref
                                .read(godListProvider.notifier)
                                .addGod(name);
                            newGodController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _GodActions extends StatelessWidget {
  final God god;
  final WidgetRef innerRef;
  final HomeController controller;

  const _GodActions({
    required this.god,
    required this.innerRef,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 22),
          onPressed: () {
            final renameController = TextEditingController(text: god.name);
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Rename God'),
                content: TextField(
                  controller: renameController,
                  decoration: const InputDecoration(hintText: 'Enter new name'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final newName = renameController.text.trim();
                      if (newName.isNotEmpty) {
                        await innerRef
                            .read(godListProvider.notifier)
                            .renameGod(god.id, newName);
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            await innerRef.read(godListProvider.notifier).removeGod(god.id);
          },
        ),
      ],
    );
  }
}
