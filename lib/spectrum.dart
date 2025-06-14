import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'variables.dart'; // Import the variables file containing data arrays and labels
import 'settings.dart';
import 'notifications_loader.dart';
import 'services/setpoint_service.dart'; // Import the setpoint service
import 'services/global_state_manager.dart'; // Import the global state manager

class SpectrumPage extends StatefulWidget {
  const SpectrumPage({super.key});

  @override
  State<SpectrumPage> createState() => _SpectrumPageState();
}

class _SpectrumPageState extends State<SpectrumPage> {
  bool _isTakingSpectrumReadings = false;
  late ScrollController _scrollController;
  bool _isScrolledToBottom = false;
  
  // API and SSE related
  String? _obtainedSpectrumImageUrl;
  bool _isLoadingObtainedSpectrum = false;
  String? _errorMessage;
  StreamSubscription? _callbackSubscription;
  StreamSubscription? _lightModeSubscription;
  
  // Light mode tracking
  int _currentLightMode = 0;
  String? _expectedSpectrumImageUrl;
  
  // Configuration
  static const String _baseUrl = 'https://demo.smartfarm.id';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // Device ID - You might want to get this from a global state or pass it as parameter
  String get deviceId => '1'; // Replace with actual device ID logic

  // To simulate taking readings
  Timer? _spectrumReadingTimer;

  static const double _bottomPaddingForButton = 65;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    
    // Initialize current light mode from global state
    _currentLightMode = globalState.currentLightMode;
    _updateExpectedSpectrumUrl();
    
    // Listen to light mode changes from global state
    _lightModeSubscription = globalState.lightModeStream.listen((lightMode) {
      if (mounted && lightMode != _currentLightMode) {
        setState(() {
          _currentLightMode = lightMode;
          _updateExpectedSpectrumUrl();
        });
        print('🔆 Spectrum page: Light mode changed to $lightMode');
      }
    });
    
    // Initialize SSE callback listening
    _initializeCallbackSSE();
    
    // Load obtained spectrum on page load
    _loadObtainedSpectrum();
    
    // Call scroll listener once after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollListener();
      }
    });
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
      if (!_isScrolledToBottom) {
        setState(() {
          _isScrolledToBottom = true;
        });
      }
    }
  }

  /// Update expected spectrum image URL based on current light mode
  void _updateExpectedSpectrumUrl() {
    _expectedSpectrumImageUrl = globalState.getSpectrumReferenceUrl();
    print('🔆 Expected spectrum URL updated: $_expectedSpectrumImageUrl');
  }

  /// Initialize SSE callback connection
  void _initializeCallbackSSE() {
    try {
      final callbackStream = SetpointService.initializeCallbackSSE(deviceId: deviceId);
      _callbackSubscription = callbackStream.listen(
        (data) {
          print('📡 Received callback: $data');
          
          // Check if the callback is related to spectrum
          if (data.containsKey('spectrum_status') || 
              data.containsKey('take_spectrum') ||
              data.containsKey('spectrometer_plot_ready')) {
            
            // Reload obtained spectrum when new data is available
            _loadObtainedSpectrum();
            
            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✔️ New spectrum data received!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        },
        onError: (error) {
          print('❌ SSE Callback error: $error');
        },
      );
    } catch (e) {
      print('❌ Error initializing SSE callback: $e');
    }
  }

  /// Get JWT token from secure storage
  Future<String?> _getJwtToken() async {
    try {
      return await _secureStorage.read(key: 'jwt_token');
    } catch (e) {
      print('❌ Error reading JWT token: $e');
      return null;
    }
  }

  /// Get headers with JWT token for API requests
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getJwtToken();
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Load obtained spectrum image from API
  /// Load obtained spectrum image from API
  Future<void> _loadObtainedSpectrum() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingObtainedSpectrum = true;
      _errorMessage = null;
    });

    try {
      final headers = await _getAuthHeaders();
      // ✅ USING: The endpoint that worked in your debug output
      final apiUrl = '$_baseUrl/file/listspectrometer/plot/$deviceId';
      
      // 🐛 DEBUG PRINTS
      print('🌐 API URL: $apiUrl');
      print('📱 Device ID: $deviceId');
      print('🔑 Headers: ${headers.keys.join(', ')}');
      print('🔐 Has Authorization: ${headers.containsKey('Authorization')}');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: headers,
      );

      // 🐛 DEBUG RESPONSE
      print('📡 Response Status: ${response.statusCode}');
      print('📋 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // 🐛 DEBUG PARSED DATA
        print('✅ Parsed Response: $responseData');
        print('🎯 Status: ${responseData['status']}');  // Changed from 'success' to 'status'
        print('📊 Data length: ${responseData['data']?.length ?? 0}');
        
        // ✅ FIXED: Check for 'status' instead of 'success'
        if (responseData['status'] == 'success' && 
            responseData['data'] != null && 
            responseData['data'].isNotEmpty) {
          
          // 🐛 DEBUG DATA ARRAY
          print('📋 Full data array: ${responseData['data']}');
          print('📊 Data array length: ${responseData['data'].length}');
          
          // Get the latest spectrum image
          final latestSpectrum = responseData['data'][0];
          
          // 🐛 DEBUG LATEST SPECTRUM OBJECT
          print('🎯 Latest spectrum object: $latestSpectrum');
          print('🎯 Latest spectrum type: ${latestSpectrum.runtimeType}');
          print('🎯 Latest spectrum keys: ${latestSpectrum is Map ? latestSpectrum.keys.toList() : 'Not a Map'}');
          
          // ✅ IMPROVED: Use file_url if available, fallback to filename
          final fileUrl = latestSpectrum['file_url'];
          final filename = latestSpectrum['filename'];
          
          // 🐛 DEBUG FILENAME EXTRACTION
          print('📁 Raw file_url: $fileUrl');
          print('📁 Raw filename: $filename');
          print('📁 file_url type: ${fileUrl.runtimeType}');
          print('📁 filename type: ${filename.runtimeType}');
          
          // Use file_url if available, otherwise construct from filename
          String? imagePath;
          if (fileUrl != null && fileUrl.toString().isNotEmpty) {
            imagePath = fileUrl.toString();
          } else if (filename != null && filename.toString().isNotEmpty) {
            imagePath = '/spectrometer/$filename';
          }
          
          if (imagePath != null) {
            final fullImageUrl = '$_baseUrl$imagePath';
            
            // 🐛 DEBUG IMAGE URL
            print('🖼️ Image path: $imagePath');
            print('🖼️ Base URL: $_baseUrl');
            print('🖼️ Full Image URL: $fullImageUrl');
            
            if (mounted) {
              setState(() {
                _obtainedSpectrumImageUrl = fullImageUrl;
                _isLoadingObtainedSpectrum = false;
              });
            }
          } else {
            print('❌ No valid file path found');
            if (mounted) {
              setState(() {
                _obtainedSpectrumImageUrl = null;
                _isLoadingObtainedSpectrum = false;
                _errorMessage = 'No valid file path in response';
              });
            }
          }
        } else {
          print('❌ Invalid response status or no data');
          print('❌ Status: ${responseData['status']}');
          print('❌ Data: ${responseData['data']}');
          if (mounted) {
            setState(() {
              _obtainedSpectrumImageUrl = null;
              _isLoadingObtainedSpectrum = false;
              _errorMessage = 'No spectrum data available';
            });
          }
        }
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        if (mounted) {
          setState(() {
            _isLoadingObtainedSpectrum = false;
            _errorMessage = 'Failed to load spectrum data: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      print('❌ Exception loading obtained spectrum: $e');
      if (mounted) {
        setState(() {
          _isLoadingObtainedSpectrum = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  /// Take spectrum readings using the setpoint service
  Future<void> _takeSpectrumReadings() async {
    if (!mounted) return;
    
    setState(() {
      _isTakingSpectrumReadings = true;
    });

    try {
      // Send spectrum command through setpoint service
      final success = await SetpointService.sendSpectrumCommand(
        deviceId: deviceId,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✔️ Spectrum command sent successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // The SSE callback will handle updating the UI when new data arrives
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to send spectrum command'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error taking spectrum readings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingSpectrumReadings = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _spectrumReadingTimer?.cancel();
    _callbackSubscription?.cancel();
    _lightModeSubscription?.cancel();
    SetpointService.closeCallbackSSE();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double horizontalPadding = screenWidth * 0.04;

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
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
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
                        
                        // Title centered with light mode info
                        Column(
                          children: [
                            const Text(
                              'Spectrometer',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: Color(0xFF1A202C),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Current Light Mode: ${globalState.getLightModeDescription()}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4A5568),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        // Expected Spectrum Image
                        _buildImageSection(
                          'Expected Spectrum (Mode $_currentLightMode)',
                          _expectedSpectrumImageUrl,
                          isNetworkImage: true,
                        ),
                        const SizedBox(height: 20),
                        
                        // Obtained Spectrum Image
                        _buildImageSection(
                          'Obtained Spectrum',
                          _obtainedSpectrumImageUrl,
                          isNetworkImage: true,
                          isLoading: _isLoadingObtainedSpectrum,
                          errorMessage: _errorMessage,
                        ),
                        const SizedBox(height: _bottomPaddingForButton),
                      ],
                    ),
                  ),
                ),
                
                // Floating Take Spectrum Button
                Positioned(
                  bottom: 20,
                  left: _isScrolledToBottom ? horizontalPadding : null,
                  right: horizontalPadding,
                  child: Container(
                    width: _isScrolledToBottom
                        ? screenWidth - (horizontalPadding * 2)
                        : null,
                    child: FilledButton.icon(
                      onPressed: _isTakingSpectrumReadings ? null : _takeSpectrumReadings,
                      icon: _isTakingSpectrumReadings
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.gradient,
                              color: Colors.white,
                              size: 18,
                            ),
                      label: Text(
                        _isTakingSpectrumReadings ? 'Taking Reading...' : 'Take Spectrum',
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
                        minimumSize: _isScrolledToBottom
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

  /// Build image section for spectrum display
  Widget _buildImageSection(
    String title,
    String? imageUrl, {
    bool isNetworkImage = false,
    bool isLoading = false,
    String? errorMessage,
  }) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        // Title
        Align(
          alignment: Alignment.center,
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 18,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        // Image Container
        Container(
          height: screenHeight * 0.25,
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
            child: _buildImageContent(
              imageUrl,
              isNetworkImage: isNetworkImage,
              isLoading: isLoading,
              errorMessage: errorMessage,
            ),
          ),
        ),
      ],
    );
  }

  /// Build image content with loading and error states
  Widget _buildImageContent(
    String? imageUrl, {
    bool isNetworkImage = false,
    bool isLoading = false,
    String? errorMessage,
  }) {
    // 🐛 DEBUG IMAGE LOADING
    if (imageUrl != null) {
      print('🖼️ Attempting to load image: $imageUrl');
    }

    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Loading spectrum...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            // 🐛 DEBUG ERROR INFO
            const SizedBox(height: 4),
            Text(
              'URL: ${imageUrl ?? 'null'}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (isNetworkImage)
              ElevatedButton(
                onPressed: _loadObtainedSpectrum,
                child: const Text('Retry'),
              ),
          ],
        ),
      );
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkImage ? Icons.analytics_outlined : Icons.image_not_supported,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              isNetworkImage 
                  ? 'No spectrum data available' 
                  : 'Expected spectrum image not available',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (isNetworkImage) ...[
              const SizedBox(height: 8),
              const Text(
                'Take a spectrum reading to see data',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    // Display the actual image
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          print('✅ Image loaded successfully: $imageUrl');
          return child;
        }
        print('⏳ Loading image progress: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
              const SizedBox(height: 8),
              const Text('Loading image...'),
            ],
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Image load error for URL: $imageUrl');
        print('❌ Error details: $error');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 8),
              Text(
                isNetworkImage 
                    ? 'Failed to load spectrum image'
                    : 'Expected spectrum image not found',
                style: const TextStyle(color: Colors.red),
              ),
              // 🐛 DEBUG URL INFO
              const SizedBox(height: 4),
              Text(
                'URL: $imageUrl',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (isNetworkImage)
                ElevatedButton(
                  onPressed: _loadObtainedSpectrum,
                  child: const Text('Retry'),
                ),
            ],
          ),
        );
      },
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
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          widget.iconData,
          size: 24,
          color: const Color.fromARGB(221, 0, 0, 0),
        ),
      ),
    );
  }
}