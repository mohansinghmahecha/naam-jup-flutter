import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/god_provider.dart';
import '../models/god.dart';
import '../widgets/god_counter_widget.dart';
import 'notification_settings_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  late AnimationController _resetController;
  double animatedProgress = 0.0;
  bool isResetting = false;
  int selectedGodIndex = 0;

  @override
  void initState() {
    super.initState();
    _resetController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 700),
        )..addListener(() {
          setState(() {
            animatedProgress = 1.0 - _resetController.value;
          });
        });

    _loadSelectedGod();
  }
    @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSelectedGodWithPrefs();
  }

  Future<void> _loadSelectedGod() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedGodId = prefs.getString('selected_god_id');
    if (selectedGodId != null) {
      final gods = ref.read(godListProvider);
      final index = gods.indexWhere((god) => god.id == selectedGodId);
      if (index != -1) {
        setState(() {
          selectedGodIndex = index;
        });
      }
    }
  }

  Future<void> _setSelectedGod(int index, List<God> gods) async {
    setState(() {
      selectedGodIndex = index;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_god_id', gods[index].id);
  }

  Future<void> _syncSelectedGodWithPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedGodId = prefs.getString('selected_god_id');
    if (selectedGodId == null) return;

    final gods = ref.read(godListProvider);
    final index = gods.indexWhere((god) => god.id == selectedGodId);
    if (index != -1 && index != selectedGodIndex) {
      setState(() {
        selectedGodIndex = index;
      });
    }
  }



  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onTap(God currentGod) {
    if (isResetting) return;

    ref.read(godListProvider.notifier).incrementCount(currentGod.id);
    final progress = currentGod.sessionCount >= 108
        ? 1.0
        : currentGod.sessionCount / 108.0;

    setState(() {
      animatedProgress = progress;
    });

    if (currentGod.sessionCount + 1 >= 108) {
      Future.delayed(const Duration(milliseconds: 250), () {
        _animateReset(currentGod.id);
      });
    }
  }

  void _animateReset(String godId) {
    if (isResetting) return;
    isResetting = true;

    _resetController.reset();
    _resetController.forward().whenComplete(() async {
      final notifier = ref.read(godListProvider.notifier);
      final gods = notifier.state.map((god) {
        if (god.id == godId) {
          return God(
            id: god.id,
            name: god.name,
            sessionCount: 0,
            totalCount: god.totalCount,
          );
        }
        return god;
      }).toList();

      notifier.state = gods;
      await Future.delayed(const Duration(milliseconds: 100));

      setState(() {
        animatedProgress = 0.0;
        isResetting = false;
      });

      _resetController.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gods = ref.watch(godListProvider);
    if (gods.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentGod = gods[selectedGodIndex];
    final progress = isResetting
        ? animatedProgress
        : (currentGod.sessionCount % 108) / 108.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 243, 241, 234), Color(0xFFFFB74D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "||  श्री  ||",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    currentGod.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.alkatra(
                      fontSize: 98,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _showManageGodsScreen(context, ref, gods),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Change Name",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 40),
                  GodCounterWidget(
                    god: currentGod,
                    progress: progress,
                    isResetting: isResetting,
                    onTap: () => _onTap(currentGod),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Malla: ${currentGod.sessionCount % 108} / 108",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
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
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      "Manual Counting",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () =>
                        _showManualCountingDialog(context, ref, currentGod),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= FULL-SCREEN GOD MANAGER =================
  void _showManageGodsScreen(
    BuildContext context,
    WidgetRef ref,
    List<God> gods,
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

        return StatefulBuilder(
          builder: (context, setModalState) {
            void refresh() => setModalState(() {});

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 20, // Top margin to avoid touching top
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.97 - 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Manage Gods",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
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
                      Expanded(
                        child: Consumer(
                          builder: (context, innerRef, _) {
                            final currentList = innerRef.watch(godListProvider);

                            return ListView.separated(
                              itemCount: currentList.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 0),
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
                                    await _setSelectedGod(
                                      index,
                                      innerRef.read(godListProvider),
                                    );
                                    Navigator.pop(context);
                                  },
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 22),
                                        onPressed: () {
                                          final renameController =
                                              TextEditingController(
                                                text: god.name,
                                              );
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Rename God'),
                                              content: TextField(
                                                controller: renameController,
                                                decoration:
                                                    const InputDecoration(
                                                      hintText:
                                                          'Enter new name',
                                                    ),
                                                autofocus: true,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    final newName =
                                                        renameController.text
                                                            .trim();
                                                    if (newName.isNotEmpty) {
                                                      await innerRef
                                                          .read(
                                                            godListProvider
                                                                .notifier,
                                                          )
                                                          .renameGod(
                                                            god.id,
                                                            newName,
                                                          );
                                                      Navigator.pop(ctx);
                                                      refresh();
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
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: currentList.length == 1
                                            ? null
                                            : () async {
                                                final removedId = god.id;
                                                await innerRef
                                                    .read(
                                                      godListProvider.notifier,
                                                    )
                                                    .removeGod(removedId);
                                                setModalState(() {
                                                  final newList = innerRef.read(
                                                    godListProvider,
                                                  );
                                                  if (selectedGodIndex >=
                                                      newList.length) {
                                                    selectedGodIndex =
                                                        newList.length - 1;
                                                  }
                                                });
                                                refresh();
                                              },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const Divider(height: 0),
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
                                  setModalState(() {});
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
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
      },
    );
  }

  // ================= MANUAL COUNTING =================
  void _showManualCountingDialog(BuildContext context, WidgetRef ref, God god) {
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

              await ref
                  .read(godListProvider.notifier)
                  .addManualCount(god.id, input);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✅ Added $input to ${god.name}\'s total count!',
                  ),
                ),
              );

              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
