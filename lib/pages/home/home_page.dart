import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/god_provider.dart';
import '../../../models/god.dart';
import 'controllers/home_controller.dart';
import 'widgets/god_progress_section.dart';
import 'widgets/count_summary_card.dart';
import 'widgets/action_buttons.dart';
import 'widgets/manage_gods_bottomsheet.dart';
import 'widgets/manual_counting_dialog.dart';
import '../../../providers/selected_god_index_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  late final HomeController controller;

  @override
  void initState() {
    super.initState();
    controller = HomeController(ref, this);
    controller.init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gods = ref.watch(godListProvider);
    final selectedIndex = ref.watch(selectedGodIndexProvider);

    if (gods.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentGod = gods[selectedIndex];
    final progress = controller.calculateProgress(currentGod);

    return Scaffold(
      body: Container(
        width: double.infinity, // <-- full width
        height: double.infinity, // <-- full height
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F1EA), Color(0xFFFFB74D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // <-- full width children
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => controller.onTap(currentGod),
                  behavior: HitTestBehavior.translucent,
                  child: GodProgressSection(
                    currentGod: currentGod,
                    progress: progress,
                    isResetting: controller.isResetting,
                    onTap: () => controller.onTap(currentGod),
                    onChangeName: () =>
                        showManageGodsSheet(context, ref, controller),
                  ),
                ),

                const SizedBox(height: 30),
                CountSummaryCard(currentGod: currentGod),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ActionButtons(
                    onManualCounting: () =>
                        showManualCountingDialog(context, ref, currentGod),
                    onNotificationTap: () =>
                        controller.goToNotifications(context),
                    // onChangeName: () =>
                    //     showManageGodsSheet(context, ref, controller),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
