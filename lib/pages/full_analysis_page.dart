import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/god.dart';

class FullAnalysisPage extends StatefulWidget {
  const FullAnalysisPage({Key? key}) : super(key: key);

  @override
  State<FullAnalysisPage> createState() => _FullAnalysisPageState();
}

class _FullAnalysisPageState extends State<FullAnalysisPage> {
  Map<String, dynamic> dailyData = {};
  Map<String, String> godNames = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final gods = await StorageService.loadGods();
    final data = await StorageService.loadDailyCounts();
    setState(() {
      godNames = {for (var g in gods) g.id: g.name};
      dailyData = data;
      isLoading = false;
    });
  }

  /// 🔹 Return all god counts for a specific date
  List<MapEntry<String, int>> _getCountsForDate(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    if (!dailyData.containsKey(key)) return [];

    final godsMap = dailyData[key];
    if (godsMap is Map) {
      return godsMap.entries
          .map(
            (e) => MapEntry(
              e.key.toString(),
              int.tryParse(e.value.toString()) ?? 0,
            ),
          )
          .toList();
    }
    return [];
  }

  /// 🔹 Check if the given date has any count > 0
  bool _hasData(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    if (!dailyData.containsKey(key)) return false;
    final data = dailyData[key];
    if (data is Map) {
      return data.values.any((v) => (int.tryParse(v.toString()) ?? 0) > 0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final selectedEntries =
        _selectedDay != null ? _getCountsForDate(_selectedDay!) : [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Full Analysis",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime(2023),
                    lastDay: DateTime.now().add(const Duration(days: 30)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        shape: BoxShape.circle,
                      ),
                      defaultDecoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      outsideDecoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                      weekendTextStyle: const TextStyle(color: Colors.black),
                    ),

                    /// 🔹 Custom builder for all dates
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, date, focusedDay) {
                        final hasData = _hasData(date);
                        final isSelected = isSameDay(_selectedDay, date);

                        Color bgColor;
                        Color textColor;

                        if (hasData) {
                          bgColor =
                              Colors.amber.shade600; // 🔸 orange (has data)
                          textColor = Colors.white;
                        } else {
                          bgColor = Colors.grey.shade300; // ⚪ gray (no data)
                          textColor = Colors.black54;
                        }

                        // if selected, highlight strongly
                        if (isSelected) {
                          bgColor = Colors.black;
                          textColor = Colors.white;
                        }

                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: bgColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  /// 🔹 Show list of gods and counts for selected date
                  if (_selectedDay != null)
                    Expanded(
                      child:
                          selectedEntries.isEmpty
                              ? const Center(
                                child: Text(
                                  "No data for this day",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: selectedEntries.length,
                                itemBuilder: (context, i) {
                                  final entry = selectedEntries[i];
                                  return Card(
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        godNames[entry.key] ?? 'Unknown God',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      trailing: Text(
                                        entry.value.toString(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                ],
              ),
    );
  }
}
