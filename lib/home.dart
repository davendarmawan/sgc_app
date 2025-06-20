import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'variables.dart'; // Assuming this file exists and contains necessary variables
import 'settings.dart'; // Assuming this file exists
import 'nightday.dart'; // Assuming this file exists
import 'notifications.dart'; // Import the real notifications page
import 'package:carousel_slider_plus/carousel_slider_plus.dart';
import 'services/liveCondition_service.dart'; // Assuming this file exists

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
  int _notificationCount = 0; // Track notification count for badge

  // Camera images data
  Map<String, List<CameraImage>> _cameraImages = {
    'top': [],
    'bottom': [],
    'user': [],
  };
  bool _isLoadingCameraImages = true;

  // Configuration
  static const String _baseUrl = 'https://demo.smartfarm.id';
  static const String _deviceId = '1';

  final List<String> cameraLabels = [
    'Top Camera',
    'Bottom Camera',
    'User Camera',
  ];

  final List<String> cameraTypes = ['top', 'bottom', 'user'];

  @override
  void initState() {
    super.initState();
    print('🚀 HomePage initState called');
    _initializeService();
    _loadCameraImages();
  }

  Future<void> _initializeService() async {
    print('🔄 Starting service initialization...');
    try {
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
        liveService = LiveConditionService(
          deviceId: '1',
          baseUrl: 'https://demo.smartfarm.id',
          authToken: jwtToken,
        );

        print('📡 Starting to listen for live data...');
        liveService!.startListening().listen(
          (data) {
            print('📊 LIVE DATA RECEIVED: $data');
            if (mounted) {
              setState(() {
                print('🔄 UI updated with new data');
              });
            }
          },
          onError: (error) {
            print('❌ Stream error: $error');
          },
        );

        // Listen for new notifications to update badge count
        liveService!.notificationStream.listen(
          (notification) {
            if (mounted) {
              setState(() {
                _notificationCount = liveService!.notificationCount;
              });
            }
          },
        );

        print('✅ Service initialized successfully');
      } else {
        print('⚠️ No JWT token found - user needs to login');
      }

      if (mounted) {
        setState(() {
          isLoading = false;
          _notificationCount = liveService?.notificationCount ?? 0;
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

  Future<void> _loadCameraImages() async {
    print('🔄 Loading camera images...');
    try {
      String? jwtToken = await secureStorage.read(key: 'jwt_token');
      if (jwtToken == null) {
        print('⚠️ No JWT token found for camera images');
        return;
      }

      final headers = {
        'Authorization': 'Bearer $jwtToken',
        'Accept': 'application/json',
      };

      final List<Future<List<CameraImage>>> futures = [
        _fetchCameraImages('top', headers),
        _fetchCameraImages('bottom', headers),
        _fetchCameraImages('user', headers),
      ];

      final List<List<CameraImage>> results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _cameraImages['top'] = results[0];
          _cameraImages['bottom'] = results[1];
          _cameraImages['user'] = results[2];
          _isLoadingCameraImages = false;
        });
        print('✅ Camera images loaded successfully');
      }
    } catch (e) {
      print('❌ Error loading camera images: $e');
      if (mounted) {
        setState(() {
          _isLoadingCameraImages = false;
        });
      }
    }
  }

  Future<List<CameraImage>> _fetchCameraImages(
    String position,
    Map<String, String> headers,
  ) async {
    print('🔍 Fetching $position camera images...');
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/file/list$position/$_deviceId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        
        List<dynamic> imageList;
        if (data is List) {
          imageList = data;
        } else if (data is Map<String, dynamic>) {
          if (data.containsKey('data') && data['data'] is List) {
            imageList = data['data'];
          } else if (data.containsKey('files') && data['files'] is List) {
            imageList = data['files'];
          } else if (data.containsKey('images') && data['images'] is List) {
            imageList = data['images'];
          } else if (data.containsKey('result') && data['result'] is List) {
            imageList = data['result'];
          } else {
            imageList = [];
          }
        } else {
          imageList = [];
        }

        final List<CameraImage> cameraImages = imageList
            .map((item) {
              if (item is Map<String, dynamic>) {
                return CameraImage.fromJson(item);
              }
              return null;
            })
            .whereType<CameraImage>()
            .toList();

        print('📷 Found ${cameraImages.length} images for $position camera');
        return cameraImages;
      } else {
        print('❌ Failed to load $position camera images: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching $position camera images: $e');
      return [];
    }
  }

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
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Column(
                  children: [
                    // Upper shield: Settings icon, Logo, Notifications
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HoverCircleIcon(
                          iconData: Icons.settings,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsPage()),
                            );
                          },
                        ),
                        Image.asset(
                          'assets/smartfarm_logo.png',
                          height: 58,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported),
                        ),
                        HoverCircleIcon(
                          iconData: Icons.notifications_none,
                          badgeCount: _notificationCount,
                          onTap: () {
                            if (liveService != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NotificationsPage(
                                    liveConditionService: liveService!,
                                  ),
                                ),
                              ).then((_) {
                                // Update notification count when returning from notifications page
                                if (mounted) {
                                  setState(() {
                                    _notificationCount = liveService!.notificationCount;
                                  });
                                }
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Service not initialized. Please wait...'),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Greetings and Connection Status Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    getIcon().iconData,
                                    size: 28,
                                    color: getIcon().iconColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Good ${getGreeting()}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28,
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
                        if (liveService != null)
                          Container(
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  liveService!.isConnected
                                      ? Icons.wifi
                                      : Icons.wifi_off,
                                  size: 18,
                                  color:
                                      liveService!.isConnected
                                          ? Colors.green
                                          : Colors.red,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  liveService!.isConnected
                                      ? 'Connected'
                                      : 'Disconnected',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        liveService!.isConnected
                                            ? Colors.green[800]
                                            : Colors.red[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (liveService != null) const SizedBox(width: 5.0),
                      ],
                    ),

                    // Camera Carousel Container - Now shows real images
                    Container(
                      margin: EdgeInsets.symmetric(
                        vertical: screenWidth * 0.04,
                      ),
                      height: 212,
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
                                  items: List.generate(3, (index) {
                                    final cameraType = cameraTypes[index];
                                    final cameraImages = _cameraImages[cameraType] ?? [];
                                    final latestImage = cameraImages.isNotEmpty ? cameraImages.first : null;
                                    
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3.0,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              color: Colors.grey[200],
                                              child: _isLoadingCameraImages
                                                  ? const Center(
                                                      child: CircularProgressIndicator(
                                                        color: Colors.blue,
                                                      ),
                                                    )
                                                  : latestImage != null && latestImage.imagePath.isNotEmpty
                                                      ? Image.network(
                                                          '$_baseUrl${latestImage.imagePath}',
                                                          fit: BoxFit.cover,
                                                          width: double.infinity,
                                                          loadingBuilder: (context, child, loadingProgress) {
                                                            if (loadingProgress == null) return child;
                                                            return Center(
                                                              child: CircularProgressIndicator(
                                                                value: loadingProgress.expectedTotalBytes != null
                                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                                        loadingProgress.expectedTotalBytes!
                                                                    : null,
                                                                color: Colors.blue,
                                                              ),
                                                            );
                                                          },
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Center(
                                                              child: Column(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  const Icon(
                                                                    Icons.broken_image_outlined,
                                                                    size: 48,
                                                                    color: Colors.grey,
                                                                  ),
                                                                  const SizedBox(height: 8),
                                                                  Text(
                                                                    'Image unavailable',
                                                                    style: TextStyle(color: Colors.grey[600]),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        )
                                                      : Center(
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Icon(
                                                                Icons.camera_alt_outlined,
                                                                size: 48,
                                                                color: Colors.grey[400],
                                                              ),
                                                              const SizedBox(height: 8),
                                                              Text(
                                                                'No image available',
                                                                style: TextStyle(color: Colors.grey[600]),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black45,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  cameraLabels[index],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Add refresh button in top-left corner
                                            Positioned(
                                              top: 8,
                                              left: 8,
                                              child: GestureDetector(
                                                onTap: _loadCameraImages,
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black45,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Icon(
                                                    Icons.refresh,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (index) {
                              return GestureDetector(
                                child: Container(
                                  width: 8.0,
                                  height: 8.0,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentCarouselIndex == index
                                        ? Colors.blueAccent
                                        : Colors.grey[300],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    // Sensor Cards GridView
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
                              liveService?.getFormattedSetpoint('humidity') ??
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
                              liveService?.getFormattedSetpoint('light') ??
                              getSetpoint('light'),
                          icon: Icons.wb_sunny,
                          iconColor: Colors.orangeAccent,
                          extraInfo: getMode('light'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Night/Day Settings Button
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const NightDaySettingsPage(deviceId: "1"),
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
                                color: Colors.white,
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

  String getSetpoint(String sensor) {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 18) {
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

  String getMode(String sensor) {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 18) {
      if (sensor == 'light') {
        return dayLightMode;
      }
    } else {
      if (sensor == 'light') {
        return nightLightMode;
      }
    }
    return '';
  }
}

// CameraImage class - add this to your HomePage file
class CameraImage {
  final String filename;
  final String imagePath;
  final String uploadedAt;
  final int deviceId;

  CameraImage({
    required this.filename,
    required this.imagePath,
    required this.uploadedAt,
    required this.deviceId,
  });

  factory CameraImage.fromJson(Map<String, dynamic> json) {
    return CameraImage(
      filename: json['filename'] as String? ?? '',
      imagePath:
          (json['image_path'] as String? ?? json['file_url'] as String?) ?? '',
      uploadedAt: json['uploaded_at'] as String? ?? '',
      deviceId:
          (json['device_id'] is int
              ? json['device_id']
              : (json['device_id'] is String
                  ? int.tryParse(json['device_id']) ?? 0
                  : 0)),
    );
  }
}

class IconDataAndColor {
  final IconData iconData;
  final Color iconColor;

  IconDataAndColor({required this.iconData, required this.iconColor});
}

class HoverCircleIcon extends StatefulWidget {
  final IconData iconData;
  final VoidCallback? onTap;
  final int badgeCount;

  const HoverCircleIcon({
    required this.iconData,
    this.onTap,
    this.badgeCount = 0,
    super.key,
  });

  @override
  State<HoverCircleIcon> createState() => _HoverCircleIconState();
}

class _HoverCircleIconState extends State<HoverCircleIcon> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onHighlightChanged: (pressed) {
        setState(() {
          _isPressed = pressed;
        });
      },
      borderRadius: BorderRadius.circular(50),
      splashColor: const Color.fromRGBO(0, 123, 255, 0.2),
      highlightColor: const Color.fromRGBO(0, 123, 255, 0.1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPressed
              ? const Color.fromARGB(255, 200, 200, 200)
              : Colors.transparent,
        ),
        child: Stack(
          children: [
            Icon(
              widget.iconData,
              size: 24,
              color: const Color.fromARGB(221, 0, 0, 0),
            ),
            // Notification badge
            if (widget.badgeCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    widget.badgeCount > 99 ? '99+' : widget.badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
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