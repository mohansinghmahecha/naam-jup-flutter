import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/god_provider.dart';
import '../models/god.dart';
import '../widgets/god_counter_widget.dart';

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
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addListener(() {
      setState(() {
        animatedProgress = 1.0 - _resetController.value;
      });
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  // 🧘‍♂️ Handle Tap
  void _onTap(God currentGod) {
    if (isResetting) return;

    ref.read(godListProvider.notifier).incrementCount(currentGod.id);

    final progress =
        currentGod.sessionCount >= 108 ? 1.0 : currentGod.sessionCount / 108.0;

    setState(() {
      animatedProgress = progress;
    });

    // Auto reset after 108
    if (currentGod.sessionCount + 1 >= 108) {
      Future.delayed(const Duration(milliseconds: 250), () {
        _animateReset(currentGod.id);
      });
    }
  }

  // 🔄 Reset animation
  void _animateReset(String godId) {
    if (isResetting) return;
    isResetting = true;

    _resetController.reset();
    _resetController.forward().whenComplete(() async {
      final notifier = ref.read(godListProvider.notifier);
      final gods =
          notifier.state.map((god) {
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
    final progress =
        isResetting
            ? animatedProgress
            : (currentGod.sessionCount % 108) / 108.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ---------- GOD NAME ----------
              GestureDetector(
                onTap: () => _showGodSelectionDialog(context, ref, gods),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    currentGod.name,
                    style: GoogleFonts.alkatra(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ---------- COUNTER WIDGET ----------
              GodCounterWidget(
                god: currentGod,
                progress: progress,
                isResetting: isResetting,
                onTap: () => _onTap(currentGod),
              ),

              const SizedBox(height: 30),

              // ---------- COUNTERS ----------
              Text(
                'Malla: ${currentGod.sessionCount % 108} / 108',
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                'Total: ${currentGod.totalCount}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 40),

              // ---------- MANUAL COUNT BUTTON ----------
              ElevatedButton.icon(
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  "Manual Counting",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    () => _showManualCountingDialog(context, ref, currentGod),
              ),
            ],
          ),
        ),
      ),

      // ---------- ADD NEW GOD ----------
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGodDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ================= DIALOGS =================

  void _showGodSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    List<God> gods,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select or Rename God'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: gods.length,
                itemBuilder: (context, index) {
                  final god = gods[index];
                  return ListTile(
                    title: Text(god.name),
                    onTap: () {
                      setState(() => selectedGodIndex = index);
                      Navigator.pop(context);
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        Navigator.pop(context);
                        _showRenameDialog(context, ref, god);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, God god) {
    final controller = TextEditingController(text: god.name);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rename God'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Enter new name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    ref.read(godListProvider.notifier).renameGod(god.id, name);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showAddGodDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add God'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Enter name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    ref.read(godListProvider.notifier).addGod(name);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  // ✅ Manual Counting Dialog
  void _showManualCountingDialog(BuildContext context, WidgetRef ref, God god) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
