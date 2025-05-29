import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'variables.dart';
import 'settings.dart';
import 'nightday.dart';
import 'notifications_loader.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart';
import 'services/liveCondition_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  LiveConditionService? liveService;
  bool isLoading = true;
  int _currentCarouselIndex = 0;

  final List<String> cameraPreviewImages = [
    'assets/image1.png',
    'assets/image2.png',
    'assets/image3.png',
  ];

  final List<String> cameraLabels = [
    'Top Camera',
    'Bottom Camera',
    'User Camera',
  ];

  // ADD THIS: Initialize the service when widget starts
  @override
  void initState() {
    super.initState();
    print('🚀 HomePage initState called');
    _initializeService();
  }

  Future<void> _initializeService() async {
    print('🔄 Starting service initialization...');
    try {
      // Get the token first
      String? jwtToken = await secureStorage.read(key: 'jwt_token');
      String? userId = await secureStorage.read(key: 'user_id');
      String? userLevel = await secureStorage.read(key: 'user_level');

      print('Auth data check:');
      print(
        '   JWT Token: ${jwtToken != null ? 'Found (${jwtToken.length} chars)' : 'Not found'}',
      );
      print('   User ID: $userId');
      print('   User Level: $userLevel');

      if (jwtToken != null) {
        print('✅ Token found, initializing LiveConditionService...');
        // Now initialize the service
        liveService = LiveConditionService(
          deviceId: '1',
          baseUrl: 'https://demo.smartfarm.id',
          authToken: jwtToken,
        );

        print('📡 Starting to listen for live data...');
        // Start listening
        liveService!.startListening().listen(
          (data) {
            print('📊 LIVE DATA RECEIVED: $data');
            if (mounted) {
              // Check if widget is still mounted
              setState(() {
                // Update UI - this will trigger a rebuild
                print('🔄 UI updated with new data');
              });
            }
          },
          onError: (error) {
            print('❌ Stream error: $error');
          },
        );

        print('✅ Service initialized successfully');
      } else {
        print('⚠️ No JWT token found - user needs to login');
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error initializing service: $e');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ADD THIS: Clean up when widget is disposed
  @override
  void dispose() {
    print('🧹 Disposing HomePage and LiveConditionService');
    liveService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // Gradient background (blue gradient for all pages)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7FAFC), Color(0xFFC4EAFE)],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Column(
                children: [
                  // Upper shield: Settings icon, Logo, Notifications
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HoverCircleIcon(iconData: Icons.settings),
                      Image.asset(
                        'assets/smartfarm_logo.png',
                        height: 58,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported),
                      ),
                      HoverCircleIcon(iconData: Icons.notifications_none),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .center, // UPDATED for vertical centering
                    children: [
                      // Left side: Greetings
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  getIcon().iconData,
                                  size: 30,
                                  color: getIcon().iconColor,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Good ${getGreeting()}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 30,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 0),
                            const Text(
                              'Welcome Home!',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right side: Connection Status Indicator
                      if (liveService != null)
                        Container(
                          // margin: const EdgeInsets.only(top: 4), // REMOVED manual margin
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                liveService!.isConnected
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            // UPDATED from Row to Column
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                liveService!.isConnected
                                    ? Icons.wifi
                                    : Icons.wifi_off,
                                size: 18, // Slightly larger icon
                                color:
                                    liveService!.isConnected
                                        ? Colors.green
                                        : Colors.red,
                              ),
                              const SizedBox(
                                height: 2,
                              ), // Small gap between icon and text
                              Text(
                                liveService!.isConnected
                                    ? 'Connected'
                                    : 'Disconnected',
                                style: TextStyle(
                                  fontSize:
                                      10, // Smaller font for text below icon
                                  color:
                                      liveService!.isConnected
                                          ? Colors.green[800]
                                          : Colors.red[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      // ADD THIS SizedBox to push the indicator a bit to the left
                      if (liveService != null) const SizedBox(width: 5.0),
                    ],
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(
                              vertical: screenWidth * 0.04,
                            ),
                            height: 212, // increased height to accommodate dots
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      CarouselSlider(
                                        options: CarouselOptions(
                                          height: 190,
                                          viewportFraction: 1.0,
                                          autoPlay: false,
                                          autoPlayInterval: const Duration(
                                            seconds: 3,
                                          ),
                                          enlargeCenterPage: false,
                                          enableInfiniteScroll: true,
                                          onPageChanged: (index, reason) {
                                            setState(() {
                                              _currentCarouselIndex = index;
                                            });
                                          },
                                        ),
                                        items:
                                            cameraPreviewImages.asMap().entries.map((
                                              entry,
                                            ) {
                                              int index = entry.key;
                                              String imagePath = entry.value;
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 3.0,
                                                    ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Stack(
                                                    children: [
                                                      Image.asset(
                                                        imagePath,
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                      ),
                                                      Positioned(
                                                        top: 8,
                                                        right: 8,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors.black45,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            cameraLabels[index],
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children:
                                      cameraPreviewImages.asMap().entries.map((
                                        entry,
                                      ) {
                                        return GestureDetector(
                                          child: Container(
                                            width: 8.0,
                                            height: 8.0,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4.0,
                                            ),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  _currentCarouselIndex ==
                                                          entry.key
                                                      ? Colors.blueAccent
                                                      : Colors.grey[300],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ],
                            ),
                          ),
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.25,
                            children: [
                              SensorCard(
                                title: 'Temperature',
                                // UPDATED: Use live data if available, otherwise use variables.dart
                                value:
                                    liveService
                                        ?.getFormattedCondition('temperature')
                                        .split(' ')[0] ??
                                    temperature,
                                unit: '°C',
                                setpoint:
                                    liveService?.getFormattedSetpoint(
                                      'temperature',
                                    ) ??
                                    getSetpoint('temperature'),
                                icon: Icons.thermostat,
                                iconColor: Colors.redAccent,
                              ),
                              SensorCard(
                                title: 'Humidity',
                                value:
                                    liveService
                                        ?.getFormattedCondition('humidity')
                                        .split(' ')[0] ??
                                    humidity,
                                unit: '%',
                                setpoint:
                                    liveService?.getFormattedSetpoint(
                                      'humidity',
                                    ) ??
                                    getSetpoint('humidity'),
                                icon: Icons.water_drop,
                                iconColor: Colors.blueAccent,
                              ),
                              SensorCard(
                                title: 'CO₂',
                                value:
                                    liveService
                                        ?.getFormattedCondition('co2')
                                        .split(' ')[0] ??
                                    co2,
                                unit: 'ppm',
                                setpoint:
                                    liveService?.getFormattedSetpoint('co2') ??
                                    getSetpoint('co2'),
                                icon: Icons.cloud,
                                iconColor: Colors.green,
                              ),
                              SensorCard(
                                title: 'Light',
                                value:
                                    liveService
                                        ?.getFormattedCondition('light')
                                        .split(' ')[0] ??
                                    lightIntensity,
                                unit: 'LUX',
                                setpoint:
                                    liveService?.getFormattedSetpoint(
                                      'light',
                                    ) ??
                                    getSetpoint('light'),
                                icon: Icons.wb_sunny,
                                iconColor: Colors.orangeAccent,
                                extraInfo: getMode('light'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: FilledButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const NightDaySettingsPage(),
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Night / Day Hour Settings',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String getGreeting() {
    final int hour = DateTime.now().hour;
    return hour >= 5 && hour < 12
        ? "Morning,"
        : hour >= 12 && hour < 18
        ? "Afternoon,"
        : "Night,";
  }

  // Updated getIcon method with color changes
  IconDataAndColor getIcon() {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 18) {
      return IconDataAndColor(
        iconData: Icons.wb_sunny,
        iconColor: const Color.fromARGB(255, 255, 162, 0),
      );
    } else {
      return IconDataAndColor(
        iconData: Icons.dark_mode,
        iconColor: const Color.fromARGB(255, 83, 83, 83),
      );
    }
  }

  // Method to get the correct setpoint based on the time of day
  String getSetpoint(String sensor) {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 18) {
      // Daytime values
      switch (sensor) {
        case 'temperature':
          return '${dayTemperature.toString()} °C';
        case 'humidity':
          return '${dayHumidity.toString()} %';
        case 'co2':
          return '${dayCO2.toString()} ppm';
        case 'light':
          if (dayLightMode == 'Manual') {
            return 'Custom';
          } else {
            return '${dayLightIntensity.toString()} LUX';
          }
        default:
          return '0';
      }
    } else {
      // Nighttime values
      switch (sensor) {
        case 'temperature':
          return '${nightTemperature.toString()} °C';
        case 'humidity':
          return '${nightHumidity.toString()} %';
        case 'co2':
          return '${nightCO2.toString()} ppm';
        case 'light':
          if (nightLightMode == 'Manual') {
            return 'Custom';
          } else {
            return '${nightLightIntensity.toString()} LUX';
          }
        default:
          return '0';
      }
    }
  }

  // Method to get the correct mode based on the time of day
  String getMode(String sensor) {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 18) {
      // Daytime mode
      if (sensor == 'light') {
        return dayLightMode; // Return the day mode
      }
    } else {
      // Nighttime mode
      if (sensor == 'light') {
        return nightLightMode; // Return the night mode
      }
    }
    return '';
  }
}

// Rest of your classes remain the same...
class IconDataAndColor {
  final IconData iconData;
  final Color iconColor;

  IconDataAndColor({required this.iconData, required this.iconColor});
}

class HoverCircleIcon extends StatefulWidget {
  final IconData iconData;

  const HoverCircleIcon({required this.iconData, super.key});

  @override
  State<HoverCircleIcon> createState() => _HoverCircleIconState();
}

class _HoverCircleIconState extends State<HoverCircleIcon> {
  final bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (widget.iconData == Icons.settings) {
          // Navigate to Settings page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        } else if (widget.iconData == Icons.notifications_none) {
          // Navigate to Notifications page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsLoaderPage(),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(50),
      splashColor: const Color.fromRGBO(0, 123, 255, 0.2),
      highlightColor: const Color.fromRGBO(0, 123, 255, 0.1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              _isPressed
                  ? const Color.fromARGB(255, 109, 109, 109)
                  : Colors.transparent,
        ),
        child: Icon(
          widget.iconData,
          size: 24,
          color:
              _isPressed
                  ? const Color.fromARGB(255, 255, 255, 255)
                  : const Color.fromARGB(221, 0, 0, 0),
        ),
      ),
    );
  }
}

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String setpoint;
  final IconData icon;
  final Color iconColor;
  final String? extraInfo;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.setpoint,
    required this.icon,
    required this.iconColor,
    this.extraInfo,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double valueFontSize = screenWidth > 400 ? 36 : 32;
    final double unitFontSize = screenWidth > 400 ? 18 : 16;
    final double setpointFontSize = screenWidth > 400 ? 14 : 12;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 25),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (extraInfo != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    extraInfo!,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: unitFontSize,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const Divider(thickness: 1),
          Text(
            'Setpoint: $setpoint',
            style: TextStyle(fontSize: setpointFontSize, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
