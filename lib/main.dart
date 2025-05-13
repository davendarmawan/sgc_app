import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home.dart'; // Import HomePage
import 'graph.dart'; // Import GraphPage
import 'setpoint.dart'; // Import SetpointPage
import 'camera.dart'; // Import CameraPage
import 'spectrum.dart'; // Import SpectrumPage

void main() {
  // Set status bar color to transparent
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: const Color.fromARGB(255, 222, 222, 222),
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SmartFarmApp());
}

class SmartFarmApp extends StatelessWidget {
  const SmartFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartFarm',
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: GoogleFonts.nunito().fontFamily,
      ),
      home: const HomeScreen(), // Set HomeScreen as default screen
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Set the default selected index to Home

  static const List<BottomNavigationBarItem> _bottomNavItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Graph'),
    BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Setpoint'),
    BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Camera'),
    BottomNavigationBarItem(icon: Icon(Icons.gradient), label: 'Spectrum'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = const [
    HomePage(), // Home Page
    GraphPage(), // Graph Page
    SetpointPage(), // Setpoint Page
    CameraPage(), // Camera Page
    SpectrumPage(), // Spectrum Page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Show the corresponding page
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
          child: BottomNavigationBar(
            items: _bottomNavItems,
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF0D47A1),
            unselectedItemColor: Colors.black54,
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            onTap: _onItemTapped,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
