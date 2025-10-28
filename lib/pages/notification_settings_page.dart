import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final List<String> intervals = [
    "30 sec",
    "2 mins",
    "5 mins",
    "10 mins",
    "15 mins",
    "30 mins",
    "1 hour",
  ];

  String selectedInterval = "15 mins";

  final List<Map<String, String>> timeSlots = [
    {"label": "🌅 Early Morning", "time": "5 AM - 8 AM"},
    {"label": "🌞 Late Morning", "time": "8 AM - 12 PM"},
    {"label": "☀️ Afternoon", "time": "12 PM - 3 PM"},
    {"label": "🌇 Evening", "time": "3 PM - 6 PM"},
    {"label": "🌆 Sunset Hours", "time": "6 PM - 9 PM"},
    {"label": "🌙 Night", "time": "9 PM - 12 AM"},
  ];

  List<String> selectedSlots = [];
  List<String> savedReminders = [];
  bool isAddingReminder = false;

  @override
  void initState() {
    super.initState();
    loadSavedReminders();
  }

  /// ✅ Load saved reminders from SharedPreferences
  Future<void> loadSavedReminders() async {
    final prefs = await SharedPreferences.getInstance();
    savedReminders = prefs.getStringList('reminders') ?? [];
    debugPrint("🔹 Loaded reminders from SharedPreferences:");
    for (var r in savedReminders) {
      debugPrint("  -> $r");
    }
    setState(() {});
  }

  /// ✅ Convert interval text to Duration
  Duration parseInterval(String text) {
    switch (text) {
      case "30 sec":
        return const Duration(seconds: 30);
      case "2 mins":
        return const Duration(minutes: 2);
      case "5 mins":
        return const Duration(minutes: 5);
      case "10 mins":
        return const Duration(minutes: 10);
      case "15 mins":
        return const Duration(minutes: 15);
      case "30 mins":
        return const Duration(minutes: 30);
      case "1 hour":
        return const Duration(hours: 1);
      default:
        return const Duration(minutes: 15);
    }
  }

  /// ✅ Save new reminder and schedule notification
  Future<void> saveReminder() async {
    if (selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one time slot')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // Generate unique ID for this reminder
    int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    String reminderText =
        "⏱ $selectedInterval | 🕒 ${selectedSlots.join(', ')}";

    String combined = "$notificationId|$reminderText";
    savedReminders.add(combined);
    await prefs.setStringList('reminders', savedReminders);

    debugPrint("✅ Saved new reminder: $combined");

    await scheduleRepeatingReminder(notificationId);

    setState(() {
      isAddingReminder = false;
      selectedSlots.clear();
    });
  }

  /// ✅ Schedule notification (repeating or one-time)
  Future<void> scheduleRepeatingReminder(int id) async {
    final interval = parseInterval(selectedInterval);

    debugPrint("🔔 Scheduling notification ID: $id every $selectedInterval");

    if (interval < const Duration(minutes: 1)) {
      final scheduledTime = DateTime.now().add(interval);
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'default_channel',
          title: '⏰ नाम जप Reminder (Test)',
          body: 'राम नाम स्मरण करें 🙏 (after ${interval.inSeconds}s)',
          customSound: 'resource://raw/ram',
          wakeUpScreen: true,
          category: NotificationCategory.Reminder,
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduledTime,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
      debugPrint(
        "🟡 One-time notification scheduled after ${interval.inSeconds}s",
      );
    } else {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'default_channel',
          title: '⏰ नाम जप Reminder',
          body: 'राम नाम स्मरण करें 🙏 ($selectedInterval interval)',
          customSound: 'resource://raw/ram',
          wakeUpScreen: true,
          category: NotificationCategory.Reminder,
        ),
        schedule: NotificationInterval(
          interval: interval,
          timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
          repeats: true,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
      debugPrint("🟢 Repeating notification scheduled every $selectedInterval");
    }
  }

  /// ✅ Delete reminder and cancel its notification
  Future<void> deleteReminder(int index) async {
    final reminderData = savedReminders[index];
    final parts = reminderData.split('|');
    final idString = parts.first;
    final int? notificationId = int.tryParse(idString);

    debugPrint("🗑 Deleting reminder at index $index => $reminderData");

    if (notificationId != null) {
      await AwesomeNotifications().cancel(notificationId);
      debugPrint("❌ Cancelled notification with ID $notificationId");
    }

    savedReminders.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('reminders', savedReminders);

    debugPrint("✅ Updated SharedPreferences after delete:");
    for (var r in savedReminders) {
      debugPrint("  -> $r");
    }

    setState(() {});
  }

  /// ✅ Test sound notification (manual check)
  void sendTestNotification() {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: 'default_channel',
        title: '🔔 नाम जप Reminder',
        body: 'राम नाम स्मरण करें 🙏 (Test Sound)',
        customSound: 'resource://raw/ram',
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
      ),
    );
    debugPrint("🔊 Sent test sound notification");
  }

  void openAddForm() {
    setState(() => isAddingReminder = true);
  }

  @override
  Widget build(BuildContext context) {
    bool noReminders = savedReminders.isEmpty || isAddingReminder;

    return Scaffold(
      backgroundColor: const Color(0xffFFF38B),
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        title: const Text(
          "नाम जप Reminder",
          style: TextStyle(color: Colors.black, fontSize: 14),
        ),
      ),
      floatingActionButton: noReminders
          ? null
          : FloatingActionButton(
              onPressed: openAddForm,
              backgroundColor: Colors.yellow.shade700,
              child: const Icon(Icons.add),
            ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: noReminders ? buildAddReminderForm() : buildSavedRemindersList(),
      ),
    );
  }

  /// ✅ Reminder creation UI
  Widget buildAddReminderForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Reminder Interval",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: intervals.map((interval) {
              return ChoiceChip(
                label: Text(interval),
                selected: selectedInterval == interval,
                selectedColor: Colors.yellow.shade700,
                onSelected: (_) => setState(() => selectedInterval = interval),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            "Daily Active Hours (IST)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 2.8,
            ),
            itemCount: timeSlots.length,
            itemBuilder: (context, index) {
              final slot = timeSlots[index];
              final label = slot['label']!;
              final time = slot['time']!;
              final isSelected = selectedSlots.contains(label);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    isSelected
                        ? selectedSlots.remove(label)
                        : selectedSlots.add(label);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.yellow.shade600.withOpacity(0.8)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? Colors.orange.shade800
                          : Colors.yellow.shade700,
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(2, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isSelected
                                ? Colors.brown.shade900
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.brown.shade700
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 25),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow.shade700,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: saveReminder,
            child: const Text(
              "Save Reminder",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: sendTestNotification,
            child: const Text("Test Sound 🔔"),
          ),
        ],
      ),
    );
  }

  /// ✅ Display saved reminders list
  Widget buildSavedRemindersList() {
    return ListView.builder(
      itemCount: savedReminders.length,
      itemBuilder: (context, index) {
        final parts = savedReminders[index].split('|');
        final text = parts.length > 1 ? parts[1] : savedReminders[index];

        return Card(
          elevation: 3,
          child: ListTile(
            title: Text(text),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => deleteReminder(index),
            ),
          ),
        );
      },
    );
  }
}
