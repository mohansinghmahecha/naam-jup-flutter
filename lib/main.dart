// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/screens/Ai.dart';
import 'pages/home_page.dart';
import 'pages/analysis_page.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

/// Simple app with BottomNavigationBar for Navigation Test
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naam Jup Counter',
      theme: ThemeData(
        // primarySwatch: Colors.indigo,
        // scaffoldBackgroundColor: Colors.yellow,
        textTheme: GoogleFonts.poppinsTextTheme(), // Global Poppins
      ),
      home: const RootScaffold(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    AnalysisPage(),
    TrustBuildPlaceholder(),
    Ai(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 1
          ? null // ✅ No default appBar in Analysis Page
          : AppBar(
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              title: const Text(
                'Naam Jup Counter 🕉️',
                style: TextStyle(color: Colors.black),
              ),
              centerTitle: true,
              elevation: 8,
            ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange, // 🔥 Active icon/text color
        unselectedItemColor: Colors.grey, // ⚪ Inactive icon/text color
        backgroundColor: Colors.white, // optional: bar ka background
        showUnselectedLabels: true, // optional: inactive labels bhi dikhें
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.heart_broken_outlined),
            activeIcon: Icon(Icons.heart_broken),
            label: 'Trust Build',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.all_inclusive_sharp),
            activeIcon: Icon(Icons.heart_broken),
            label: 'AI',
          ),
        ],
      ),
    );
  }
}

class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Home\n(Will list gods & counters)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}

class AnalysisPlaceholder extends StatelessWidget {
  const AnalysisPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Analysis\n(Will show Today / 7d / 30d graphs)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}

class TrustBuildPlaceholder extends StatelessWidget {
  const TrustBuildPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Trust Build\nComing Soon',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
