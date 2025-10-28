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
    "30 sec", // ✅ added for quick testing
    "5 mins",
    "10 mins",
    "15 mins",
    "30 mins",
    "1 hour",
  ];

  String selectedInterval = "15 mins";

  final List<String> timeSlots = [
    "6 am to 9 am",
    "9 am to 12 pm",
    "12 pm to 3 pm",
    "3 pm to 6 pm",
    "6 pm to 9 pm",
    "9 pm to 12 am",
  ];

  List<String> selectedSlots = [];
  List<String> savedReminders = [];
  bool isAddingReminder = false;

  @override
  void initState() {
    super.initState();
    loadSavedReminders();
  }

  Future<void> loadSavedReminders() async {
    final prefs = await SharedPreferences.getInstance();
    savedReminders = prefs.getStringList('reminders') ?? [];
    setState(() {});
  }

  Duration parseInterval(String text) {
    switch (text) {
      case "30 sec":
        return const Duration(seconds: 30);
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

  Future<void> saveReminder() async {
    if (selectedSlots.isEmpty) return;

    String reminderText =
        "⏱ $selectedInterval | 🕒 ${selectedSlots.join(', ')}";

    savedReminders.add(reminderText);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('reminders', savedReminders);

    // ✅ schedule repeating reminder based on chosen interval
    await scheduleRepeatingReminder();

    setState(() {});
    Navigator.pop(context);
  }

  Future<void> deleteReminder(int index) async {
    savedReminders.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('reminders', savedReminders);
    setState(() {});
  }

  void openAddForm() {
    setState(() => isAddingReminder = true);
  }

  /// ✅ One-time test notification (sound check)
  void sendTestNotification() {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: 'default_channel',
        title: '🔔 नाम जप Reminder',
        body: 'राम नाम स्मरण करें 🙏',
        customSound: 'resource://raw/ram',
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
      ),
    );
  }

  /// ✅ Repeating notification using selected interval
  Future<void> scheduleRepeatingReminder() async {
    final interval = parseInterval(selectedInterval);
    await AwesomeNotifications().cancelAllSchedules();

    // If interval < 1 minute → single schedule (for testing)
    if (interval < const Duration(minutes: 1)) {
      final scheduledTime = DateTime.now().add(interval);
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1001,
          channelKey: 'default_channel',
          title: '⏰ नाम जप Reminder (Test)',
          body: 'राम नाम स्मरण करें 🙏 (one-time after ${interval.inSeconds}s)',
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ One-time reminder scheduled after 30 seconds'),
        ),
      );
    } else {
      // Normal repeating notifications
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1001,
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Reminder scheduled every $selectedInterval successfully!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool noReminders = savedReminders.isEmpty || isAddingReminder;

    return Scaffold(
      backgroundColor: const Color(0xffFFF38B),
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        title: const Text("नाम जप Reminder"),
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: timeSlots.map((slot) {
              return FilterChip(
                label: Text(slot),
                selected: selectedSlots.contains(slot),
                onSelected: (selected) {
                  setState(() {
                    selected
                        ? selectedSlots.add(slot)
                        : selectedSlots.remove(slot);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow.shade700,
            ),
            onPressed: saveReminder,
            child: const Text("Save Reminder"),
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

  Widget buildSavedRemindersList() {
    return ListView.builder(
      itemCount: savedReminders.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text(savedReminders[index]),
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
