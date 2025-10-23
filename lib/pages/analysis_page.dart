import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';
import '../models/god.dart';
import 'full_analysis_page.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({Key? key}) : super(key: key);

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> dailyData = {};
  Map<String, String> godNames = {};
  bool isLoading = false;
  late TabController _tabController;

  // --- UI Theme Colors ---
  // Define a cohesive color palette for the stats page
  static const Color _primaryColor = Color(
    0xFFD35400,
  ); // A strong, saffron-like orange
  static const Color _secondaryColor = Color(
    0xFFF39C12,
  ); // A bright, golden-yellow
  static final Color _scaffoldBgColor = Colors.grey.shade100;
  static const Color _cardBgColor = Colors.white;
  static final Color _darkTextColor = Colors.grey.shade900;
  static final Color _lightTextColor = Colors.grey.shade600;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  // --- Data Loading (Unchanged) ---
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

  // --- Data Filtering (Unchanged) ---
  Map<String, int> _getFilteredCounts(String range) {
    final now = DateTime.now();
    final Map<String, int> totals = {};

    dailyData.forEach((dateString, godsMap) {
      final date = DateTime.tryParse(dateString.trim());
      if (date == null) return;
      bool include = false;

      if (range == 'daily') {
        include =
            DateFormat('yyyy-MM-dd').format(date) ==
            DateFormat('yyyy-MM-dd').format(now);
      } else if (range == 'monthly') {
        include = date.isAfter(now.subtract(const Duration(days: 30)));
      } else if (range == 'yearly') {
        include = date.isAfter(now.subtract(const Duration(days: 365)));
      }

      if (include && godsMap is Map) {
        (godsMap as Map).forEach((godId, count) {
          final int value =
              (count is int) ? count : int.tryParse(count.toString()) ?? 0;
          totals[godId] = (totals[godId] ?? 0) + value;
        });
      }
    });

    totals.removeWhere((_, c) => c == 0);
    return totals;
  }

  // --- UI Helper Widgets (Refactored) ---

  // Refactored to act as a header inside a card
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: _darkTextColor,
      ),
    );
  }

  // Refactored for a cleaner, modern look with a divider
  Widget _statsHeader(int total, double avg) {
    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: _statBox("Total Count", total.toString())),
          VerticalDivider(
            color: Colors.grey.shade300,
            thickness: 1,
            width: 20,
            indent: 8,
            endIndent: 8,
          ),
          Expanded(child: _statBox("Avg/Entry", avg.toStringAsFixed(0))),
        ],
      ),
    );
  }

  // Refactored with new theme colors and typography
  Widget _statBox(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: _primaryColor, // Use primary theme color
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: _lightTextColor)),
      ],
    );
  }

  // Refactored to use new theme gradient and better "no data" message
  Widget _barChart(Map<String, int> totals) {
    if (totals.isEmpty) {
      return Container(
        height: 260,
        alignment: Alignment.center,
        child: Text(
          'No data available for this period',
          style: TextStyle(color: _lightTextColor, fontSize: 16),
        ),
      );
    }

    final counts = totals.values.toList();
    final labels = totals.keys.map((k) => godNames[k] ?? k).toList();
    final maxY = counts.reduce(math.max).toDouble();
    // Add 20% headroom to the chart's Y-axis for better spacing
    final chartMaxY = (maxY * 1.2).ceilToDouble();

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          maxY: chartMaxY,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38, // Give labels a bit more space
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 6.0,
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 12, // Slightly larger for readability
                        color: _darkTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(counts.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: counts[i].toDouble(),
                  width: 22,
                  // Use a vertical-only border radius
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  // Use the new theme gradient
                  gradient: const LinearGradient(
                    colors: [_secondaryColor, _primaryColor],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // --- Main Content Widget (Refactored) ---
  // This now builds a "dashboard card" for a cleaner look
  Widget _buildTabContent(String range, String title) {
    final totals = _getFilteredCounts(range);
    final totalCount = totals.values.fold<int>(0, (a, b) => a + b);
    final avg = totals.isNotEmpty ? totalCount / totals.length : 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      // Add padding around the entire tab content
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // This container acts as a dashboard card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: _cardBgColor,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(title),
                const SizedBox(height: 20),
                _statsHeader(totalCount, avg.toDouble()),
                const SizedBox(height: 24),
                _barChart(totals),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Styled the button to match the new theme
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FullAnalysisPage()),
              );
            },
            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
            label: const Text("Full Analysis"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor, // Use theme color
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Build Method (Refactored) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor, // Use soft grey background
      appBar: AppBar(
        title: Text(
          "Naam Jap Stats",
          style: TextStyle(color: _darkTextColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: _cardBgColor, // Use white for AppBar
        elevation: 0.5, // Add a subtle shadow
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryColor, // Use theme color
          unselectedLabelColor: _lightTextColor,
          indicatorColor: _primaryColor, // Use theme color
          tabs: const [
            Tab(text: "Daily"),
            Tab(text: "Monthly"),
            Tab(text: "Yearly"),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: _primaryColor),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildTabContent('daily', "Today's Stats"),
                  _buildTabContent('monthly', "Last 30 Days"),
                  _buildTabContent('yearly', "This Year"),
                ],
              ),
    );
  }
}
