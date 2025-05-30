import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'settings.dart';
import 'notifications_loader.dart';
import 'services/setpoint_service.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Configuration
  static const String _baseUrl = 'https://demo.smartfarm.id'; // Replace with your actual base URL
  static const String _deviceId = '1'; // Replace with actual device ID
  
  // Loading states
  bool _isLoadingImages = true;
  bool _isTakingPhoto = false;
  
  // Image data
  Map<String, List<CameraImage>> _cameraImages = {
    'top': [],
    'bottom': [],
    'user': [],
  };
  
  // Error states
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllCameraImages();
  }

  /// Load all camera images from API endpoints
  Future<void> _loadAllCameraImages() async {
    setState(() {
      _isLoadingImages = true;
      _errorMessage = null;
    });

    try {
      // Get authentication token
      String? jwtToken = await _secureStorage.read(key: 'jwt_token');
      
      if (jwtToken == null) {
        throw Exception('Authentication required. Please login again.');
      }

      final headers = {
        'Authorization': 'Bearer $jwtToken',
        'Accept': 'application/json',
      };

      // Fetch images from all three endpoints concurrently
      final List<Future<List<CameraImage>>> futures = [
        _fetchCameraImages('top', headers),
        _fetchCameraImages('bottom', headers),
        _fetchCameraImages('user', headers),
      ];

      final List<List<CameraImage>> results = await Future.wait(futures);

      setState(() {
        _cameraImages['top'] = results[0];
        _cameraImages['bottom'] = results[1];
        _cameraImages['user'] = results[2];
        _isLoadingImages = false;
      });

      print('✅ Successfully loaded camera images');
    } catch (e) {
      print('❌ Error loading camera images: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoadingImages = false;
      });
    }
  }

  /// Fetch camera images for a specific position
  Future<List<CameraImage>> _fetchCameraImages(String position, Map<String, String> headers) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/file/list$position/$_deviceId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        
        // Debug: Print the actual API response
        print('🔍 API Response for $position:');
        print('Type: ${data.runtimeType}');
        print('Content: $data');
        
        // Handle different response formats
        List<dynamic> imageList;
        
        if (data is List) {
          // Response is already a list
          imageList = data;
          print('✅ Response is List with ${imageList.length} items');
        } else if (data is Map<String, dynamic>) {
          // Response is an object, check for common array properties
          print('📦 Response is Map with keys: ${data.keys.toList()}');
          
          if (data.containsKey('data') && data['data'] is List) {
            imageList = data['data'];
            print('✅ Found data array with ${imageList.length} items');
          } else if (data.containsKey('files') && data['files'] is List) {
            imageList = data['files'];
            print('✅ Found files array with ${imageList.length} items');
          } else if (data.containsKey('images') && data['images'] is List) {
            imageList = data['images'];
            print('✅ Found images array with ${imageList.length} items');
          } else if (data.containsKey('result') && data['result'] is List) {
            imageList = data['result'];
            print('✅ Found result array with ${imageList.length} items');
          } else {
            // If it's a single object, wrap it in a list
            imageList = [data];
            print('⚠️ Wrapping single object in list');
          }
        } else {
          throw Exception('Unexpected response format for $position camera images');
        }
        
        final List<CameraImage> cameraImages = imageList.map((item) => CameraImage.fromJson(item)).toList();
        
        // Debug: Print image paths
        print('🖼️ Images for $position:');
        for (int i = 0; i < cameraImages.length; i++) {
          print('  [$i] ${cameraImages[i].filename} -> ${cameraImages[i].imagePath}');
          print('      Full URL: $_baseUrl${cameraImages[i].imagePath}');
        }
        
        return cameraImages;
      } else {
        throw Exception('Failed to load $position camera images: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching $position camera images: $e');
      return [];
    }
  }

  /// Send camera capture command to gateway
  Future<void> _takeCameraPhotos() async {
    setState(() {
      _isTakingPhoto = true;
    });

    try {
      // Send camera command using SetpointService
      bool success = await SetpointService.sendCameraCommand(deviceId: _deviceId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📷 Camera capture command sent to gateway!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );

        // Optionally reload images after a delay to get new photos
        Timer(const Duration(seconds: 3), () {
          _loadAllCameraImages();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to send camera command. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error taking photos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isTakingPhoto = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // Gradient background
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
                  // Top bar with settings, logo, notifications
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HoverCircleIcon(iconData: Icons.settings),
                      Image.asset(
                        'assets/smartfarm_logo.png',
                        height: 58,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                      ),
                      HoverCircleIcon(iconData: Icons.notifications_none),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Title centered with refresh button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Camera',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: _isLoadingImages ? null : _loadAllCameraImages,
                        icon: _isLoadingImages
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                        tooltip: 'Refresh Images',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Content area
                  Expanded(
                    child: _buildContent(),
                  ),

                  // Take Photo Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _isTakingPhoto ? null : _takeCameraPhotos,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isTakingPhoto
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Taking Photos...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Take Photos',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_isLoadingImages) {
      return _buildLoadingState();
    }

    return _buildImageGrid();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading camera images...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading images',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAllCameraImages,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildImageSection(
            'Top Camera',
            _cameraImages['top']?.isNotEmpty == true
                ? _cameraImages['top']!.first
                : null,
          ),
          const SizedBox(height: 20),
          _buildImageSection(
            'Bottom Camera',
            _cameraImages['bottom']?.isNotEmpty == true
                ? _cameraImages['bottom']!.first
                : null,
          ),
          const SizedBox(height: 20),
          _buildImageSection(
            'User Camera',
            _cameraImages['user']?.isNotEmpty == true
                ? _cameraImages['user']!.first
                : null,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildImageSection(String title, CameraImage? image) {
    return Column(
      children: [
        // Section title with timestamp
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            if (image != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  image.uploadedAt,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        
        // Image container
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(31, 2, 0, 0),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image != null
                ? Image.network(
                    '$_baseUrl${image.imagePath}',
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
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ Image failed to load: $_baseUrl${image.imagePath}');
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No image available', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// Model for camera image data
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
      filename: json['filename'] ?? '',
      imagePath: json['image_path'] ?? json['file_url'] ?? '', // Handle both field names
      uploadedAt: json['uploaded_at'] ?? '',
      deviceId: json['device_id'] ?? 0,
    );
  }
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        } else if (widget.iconData == Icons.notifications_none) {
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
          color: _isPressed
              ? const Color.fromARGB(255, 109, 109, 109)
              : Colors.transparent,
        ),
        child: Icon(
          widget.iconData,
          size: 24,
          color: _isPressed
              ? const Color.fromARGB(255, 255, 255, 255)
              : const Color.fromARGB(221, 0, 0, 0),
        ),
      ),
    );
  }
}