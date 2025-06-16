import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // Import the intl package
// Assuming these files exist in your project structure and will be created by the user
import 'settings.dart';
import 'notifications.dart';
import 'services/setpoint_service.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Configuration
  static const String _baseUrl =
      'https://demo.smartfarm.id'; // Replace with your actual base URL
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

  // Timer for reloading images after taking a photo
  Timer? _photoReloadTimer;

  // Scroll controller to detect scroll position
  late ScrollController _scrollController;
  bool _isScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _loadAllCameraImages();
  }

  void _scrollListener() {
    if (!mounted ||
        !_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) {
      if (_isScrolledToBottom) {
        setState(() {
          _isScrolledToBottom = false;
        });
      }
      return;
    }

    bool isScrollable = _scrollController.position.maxScrollExtent > 0.0;

    if (isScrollable) {
      final isAtBottom =
          _scrollController.position.pixels >=
          (_scrollController.position.maxScrollExtent - 0.5);
      if (isAtBottom != _isScrolledToBottom) {
        setState(() {
          _isScrolledToBottom = isAtBottom;
        });
      }
    } else {
      if (_isScrolledToBottom) {
        setState(() {
          _isScrolledToBottom = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _photoReloadTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllCameraImages() async {
    if (!mounted) return;
    setState(() {
      _isLoadingImages = true;
      _errorMessage = null;
    });

    try {
      String? jwtToken = await _secureStorage.read(key: 'jwt_token');
      if (jwtToken == null) {
        throw Exception('Authentication required. Please login again.');
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

      if (!mounted) return;
      setState(() {
        _cameraImages['top'] = results[0];
        _cameraImages['bottom'] = results[1];
        _cameraImages['user'] = results[2];
        _isLoadingImages = false;
      });
      print('✅ Successfully loaded camera images');
    } catch (e) {
      print('❌ Error loading camera images: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoadingImages = false;
      });
    }
  }

  Future<List<CameraImage>> _fetchCameraImages(
    String position,
    Map<String, String> headers,
  ) async {
    print('🔄 Fetching $position camera images...');
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/file/list$position/$_deviceId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        print(
          '🔍 API Response for $position: Type: ${data.runtimeType}, Content: $data',
        );

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
          throw Exception(
            'Unexpected response format for $position camera images: ${data.runtimeType}',
          );
        }

        final List<CameraImage> cameraImages =
            imageList
                .map((item) {
                  if (item is Map<String, dynamic>) {
                    return CameraImage.fromJson(item);
                  }
                  return null;
                })
                .whereType<CameraImage>()
                .toList();
        return cameraImages;
      } else {
        throw Exception(
          'Failed to load $position camera images: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error fetching $position camera images: $e');
      return [];
    }
  }

  Future<void> _takeCameraPhotos() async {
    if (!mounted) return;
    setState(() {
      _isTakingPhoto = true;
    });

    try {
      bool success = await SetpointService.sendCameraCommand(
        deviceId: _deviceId,
      );
      if (!mounted) return;

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📷 Camera capture command sent to gateway!'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
        _photoReloadTimer?.cancel();
        _photoReloadTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            _loadAllCameraImages();
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Failed to send camera command. Please try again.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error taking photos: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPhoto = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = screenWidth * 0.04;

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
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    // This Column now only holds the Expanded RefreshIndicator
                    children: [
                      // The Header Row and its SizedBox were removed from here
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadAllCameraImages,
                          color: Colors.white,
                          backgroundColor: Colors.blue,
                          child: _buildScrollablePageContent(
                            horizontalPadding,
                          ), // Pass padding if needed by header internally, or rely on parent
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: _isScrolledToBottom ? horizontalPadding : null,
                  right: horizontalPadding,
                  child: Container(
                    width:
                        _isScrolledToBottom
                            ? screenWidth - (horizontalPadding * 2)
                            : null,
                    child: FilledButton.icon(
                      onPressed: _isTakingPhoto ? null : _takeCameraPhotos,
                      icon:
                          _isTakingPhoto
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                      label: Text(
                        _isTakingPhoto ? 'Taking...' : 'Take Photos',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                        disabledBackgroundColor: Colors.blue.withOpacity(0.7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 4.0,
                        minimumSize:
                            _isScrolledToBottom
                                ? const Size(double.infinity, 0)
                                : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Accept horizontalPadding if needed, though the parent Padding widget in build() might already handle it
  Widget _buildScrollablePageContent(double horizontalPadding) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollListener();
      }
    });
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Header Row is now the first item in the scrollable content
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
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported),
              ),
              HoverCircleIcon(
                iconData: Icons.notifications_none,
                onTap: () {
                  // For now, show a message that notifications need service integration
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications require service integration from HomePage'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10), // Spacing after the header
          // Original content of the scrollable page
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Camera',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color(0xFF1A202C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildDynamicContentForScroll(),
        ],
      ),
    );
  }

  Widget _buildDynamicContentForScroll() {
    if (_errorMessage != null) {
      return _buildErrorStateContent();
    }
    if (_isLoadingImages &&
        _cameraImages['top']!.isEmpty &&
        _cameraImages['bottom']!.isEmpty &&
        _cameraImages['user']!.isEmpty) {
      return _buildLoadingStateContent();
    }
    return _buildImageGridContent();
  }

  Widget _buildLoadingStateContent() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 50.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Loading camera images...',
            style: TextStyle(fontSize: 16, color: Color(0xFF4A5568)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStateContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0).copyWith(top: 30, bottom: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            'Error Loading Images',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? "An unknown error occurred.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.redAccent),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAllCameraImages,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGridContent() {
    const double bottomPaddingForButton = 21.0 + 60.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: bottomPaddingForButton),
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
        ],
      ),
    );
  }

  Widget _buildImageSection(String title, CameraImage? image) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF2D3748),
          ),
        ),
        if (image != null && image.uploadedAt.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatDateTime(image.uploadedAt),
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                image != null && image.imagePath.isNotEmpty
                    ? Image.network(
                      '$_baseUrl${image.imagePath}',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                            color: Colors.blue,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print(
                          '❌ Image failed to load: $_baseUrl${image.imagePath}, Error: $error',
                        );
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
                                'Image unavailable ($title)',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
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
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No image available ($title)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateTimeString) {
    if (dateTimeString.isEmpty) return '';
    try {
      final DateTime dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd MMMM yyyy HH:mm').format(dateTime);
    } catch (e) {
      print("Error parsing date: $dateTimeString, $e");
      try {
        final DateTime dateTime = DateFormat(
          "yyyy-MM-dd HH:mm:ss",
        ).parse(dateTimeString, true);
        return DateFormat('dd MMMM yy HH:mm').format(dateTime);
      } catch (e2) {
        print("Error parsing date (fallback): $dateTimeString, $e2");
        return dateTimeString;
      }
    }
  }
}

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
// Replace the HoverCircleIcon class in ALL your files with this version:

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
  bool _isPressed = false; // Remove 'final' and add state management

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap, // Use callback instead of hardcoded navigation
      onHighlightChanged: (pressed) {
        setState(() {
          _isPressed = pressed;
        });
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
        child: Stack(
          children: [
            Icon(
              widget.iconData,
              size: 24,
              color: _isPressed
                  ? const Color.fromARGB(255, 255, 255, 255)
                  : const Color.fromARGB(221, 0, 0, 0),
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
