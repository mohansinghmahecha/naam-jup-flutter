import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../models/god.dart';
import '../../../../providers/god_provider.dart';
import '../../../../providers/selected_god_index_provider.dart';
import '../../../pages/notification_settings_page.dart';

class HomeController {
  final WidgetRef ref;
  final TickerProvider tickerProvider;

  late AnimationController resetController;
  double animatedProgress = 0.0;
  bool isResetting = false;

  HomeController(this.ref, this.tickerProvider);

  void init() {
    resetController =
        AnimationController(
          vsync: tickerProvider,
          duration: const Duration(milliseconds: 700),
        )..addListener(() {
          animatedProgress = 1.0 - resetController.value;
        });

    _loadSelectedGod();
  }

  void dispose() {
    resetController.dispose();
  }

  // ---- SharedPrefs Sync ----
  Future<void> _loadSelectedGod() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedGodId = prefs.getString('selected_god_id');
    if (selectedGodId != null) {
      final gods = ref.read(godListProvider);
      final index = gods.indexWhere((g) => g.id == selectedGodId);
      if (index != -1) {
        ref.read(selectedGodIndexProvider.notifier).state = index;
      }
    }
  }

  Future<void> setSelectedGod(int index, List<God> gods) async {
    ref.read(selectedGodIndexProvider.notifier).state = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_god_id', gods[index].id);
  }

  // ---- Tap Logic ----
  void onTap(God currentGod) {
    if (isResetting) return;

    ref.read(godListProvider.notifier).incrementCount(currentGod.id);
    final progress = currentGod.sessionCount >= 108
        ? 1.0
        : currentGod.sessionCount / 108.0;

    animatedProgress = progress;

    if (currentGod.sessionCount + 1 >= 108) {
      Future.delayed(const Duration(milliseconds: 250), () {
        _animateReset(currentGod.id);
      });
    }
  }

  void _animateReset(String godId) {
    if (isResetting) return;
    isResetting = true;

    resetController.reset();
    resetController.forward().whenComplete(() async {
      final notifier = ref.read(godListProvider.notifier);
      final gods = notifier.state.map((g) {
        if (g.id == godId) {
          return God(
            id: g.id,
            name: g.name,
            sessionCount: 0,
            totalCount: g.totalCount,
          );
        }
        return g;
      }).toList();

      notifier.state = gods;
      await Future.delayed(const Duration(milliseconds: 100));
      animatedProgress = 0.0;
      isResetting = false;
      resetController.stop();
    });
  }

  // ---- Helper ----
  double calculateProgress(God god) {
    return isResetting ? animatedProgress : (god.sessionCount % 108) / 108.0;
  }

  void goToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationSettingsPage()),
    );
  }
}
