import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'home.dart';
import 'graph.dart';
import 'setpoint.dart';
import 'camera.dart';
import 'spectrum.dart';
import 'login.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Color.fromARGB(255, 255, 255, 255),
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    runApp(const SmartFarmApp());
  });
}

class SmartFarmApp extends StatelessWidget {
  const SmartFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartFarm',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: GoogleFonts.nunito().fontFamily,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  Timer? _sessionCheckTimer;
  bool _isCheckingSession = false;

  static const List<BottomNavigationBarItem> _bottomNavItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Graph'),
    BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Setpoint'),
    BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Camera'),
    BottomNavigationBarItem(icon: Icon(Icons.gradient), label: 'Spectrum'),
  ];

  final List<Widget> _pages = const [
    HomePage(),
    GraphPage(deviceId: 1),
    SetpointPage(),
    CameraPage(),
    SpectrumPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSessionMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Check session when app resumes from background
    if (state == AppLifecycleState.resumed) {
      _checkSessionValidity();
    }
  }

  /// Start periodic session monitoring
  void _startSessionMonitoring() {
    // Check session every 5 minutes
    _sessionCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkSessionValidity();
    });
    
    // Also check immediately
    _checkSessionValidity();
  }

  /// Check if current session is still valid
  Future<void> _checkSessionValidity() async {
    if (_isCheckingSession || !mounted) return;
    
    setState(() {
      _isCheckingSession = true;
    });

    try {
      final bool isSessionValid = await AuthService.isSessionValid();
      
      if (!isSessionValid && mounted) {
        // Session expired, logout user
        print('HomeScreen: Session expired, redirecting to login');
        
        // Cancel the timer
        _sessionCheckTimer?.cancel();
        
        // Clear remember me since session expired
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', false);
        
        // Show session expired message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired after 24 hours. Please login again.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        // Navigate to login page
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
          );
        }
      } else if (isSessionValid) {
        // Session is valid, optionally show remaining time in debug
        final remainingHours = await AuthService.getRemainingSessionHours();
        print('HomeScreen: Session valid, ${remainingHours.toStringAsFixed(1)} hours remaining');
      }
    } catch (e) {
      print('HomeScreen: Error checking session: $e');
      // On error, assume session is invalid for security
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingSession = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
          ),
          boxShadow: [
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