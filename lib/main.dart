import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'observers/my_provider_observer.dart';
import 'screens/AiDemo.dart';
import 'pages/home/home_page.dart';
import 'pages/analysis_page.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  AwesomeNotifications().initialize(
    null, // ✅ no custom small icon → uses default app icon
    [
      NotificationChannel(
        channelKey: 'default_channel',
        channelName: 'Default Notifications',
        channelDescription: 'Notification Channel for App',
        importance: NotificationImportance.High,
        playSound: true,
        soundSource: 'resource://raw/ram', // ✅ custom sound works
      ),
    ],
  );

  // ✅ Request Notification Permission
  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  runApp(
    ProviderScope(observers: [MyProviderObserver()], child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    return MaterialApp(
      title: 'Naam Jup Counter',
      theme: ThemeData(textTheme: GoogleFonts.poppinsTextTheme()),
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
    AiDemo(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 1
          ? null
          : AppBar(
              backgroundColor: Colors.yellow.shade700,
              title: const Text(
                'Naam Jaap Counter 🕉️',
                style: TextStyle(color: Colors.black, fontSize: 14),
              ),
              centerTitle: true,
              elevation: 5,
            ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        showUnselectedLabels: true,
        items: const [
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
            activeIcon: Icon(Icons.all_inclusive),
            label: 'AI',
          ),
        ],
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
        'Trust Build\nComing Soon...',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
