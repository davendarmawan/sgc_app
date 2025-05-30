import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service class for handling setpoint-related API operations
/// When setpoint is sent to the endpoint, server automatically establishes SSE connection
class SetpointService {
  // Configuration - Replace with your actual API base URL
  static const String _baseUrl = 'https://demo.smartfarm.id';
  static const String _setpointEndpoint = '/condition/setpoint'; // Your actual endpoint: /condition/setpoint/:deviceId
  static const String _callbackEndpoint = '/condition/get-events-callback'; // Callback SSE endpoint: /condition/get-events-callback/:deviceId
  
  // Secure storage instance for JWT token
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // HTTP client for API requests
  static final http.Client _client = http.Client();
  
  // Stream controller for callback events
  static StreamController<Map<String, dynamic>>? _callbackController;
  static bool _isCallbackSSEActive = false;

  /// Get JWT token from secure storage
  static Future<String?> _getJwtToken() async {
    try {
      return await _secureStorage.read(key: 'jwt_token');
    } catch (e) {
      print('❌ Error reading JWT token: $e');
      return null;
    }
  }

  /// Get user ID from secure storage
  static Future<String?> _getUserId() async {
    try {
      return await _secureStorage.read(key: 'user_id');
    } catch (e) {
      print('❌ Error reading user ID: $e');
      return null;
    }
  }

  /// Get user level from secure storage
  static Future<String?> _getUserLevel() async {
    try {
      return await _secureStorage.read(key: 'user_level');
    } catch (e) {
      print('❌ Error reading user level: $e');
      return null;
    }
  }

  /// Get headers with JWT token for API requests
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getJwtToken();
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Send setpoint data to gateway via HTTP POST
  /// Server automatically establishes SSE connection when setpoint is received
  /// 
  /// [deviceId] - Target device ID
  /// [period] - "Day" or "Night" 
  /// [temperature] - Temperature setpoint
  /// [humidity] - Humidity setpoint
  /// [co2] - CO2 level setpoint
  /// [lightMode] - Light mode (1-6)
  /// [intensity] - Light intensity (for modes 1-4)
  /// [lightPWM] - PWM values for manual mode (mode 6)
  /// 
  /// Returns true if successful, false otherwise
  static Future<bool> sendSetpoints({
    required String deviceId,
    required String period, // "Day" or "Night"
    required double temperature,
    required double humidity,
    required double co2,
    required int lightMode,
    double? intensity,
    Map<String, double>? lightPWM,
  }) async {
    try {
      // Prepare the payload to match website format exactly
      final Map<String, dynamic> payload = {
        'daynight_mode': period, // "Day" or "Night" (capitalized)
        'temperature': temperature.toInt(), // Convert to int to match website
        'humidity': humidity.toInt(), // Convert to int to match website
        'co2': co2.toInt(), // Use 'co2' not 'co2level', convert to int
        'intensity': (intensity ?? 0).toInt(), // Convert to int
        'light_mode': lightMode.toString(), // Convert to string like "1", "2", etc.
      };

      // Add PWM values - always include all PWM fields
      if (lightMode == 6 && lightPWM != null) {
        // Manual mode - use actual PWM values
        payload.addAll({
          'light_par': lightPWM['par']?.toInt() ?? 0,
          'light_red': lightPWM['red']?.toInt() ?? 0,
          'light_blue': lightPWM['blue']?.toInt() ?? 0,
          'light_uv': lightPWM['uv']?.toInt() ?? 0,
          'light_ir': lightPWM['ir']?.toInt() ?? 0,
        });
      } else {
        // Non-manual modes - set PWM values to 0
        payload.addAll({
          'light_par': 0,
          'light_red': 0,
          'light_blue': 0,
          'light_uv': 0,
          'light_ir': 0,
        });
      }

      print('🚀 Sending setpoints to gateway (Device $deviceId): ${json.encode(payload)}');
      print('📡 Server will automatically establish SSE connection upon receiving setpoint');
      
      final headers = await _getAuthHeaders();
      final response = await _client.post(
        Uri.parse('$_baseUrl$_setpointEndpoint/$deviceId'), // /condition/setpoint/:deviceId
        headers: headers,
        body: json.encode(payload),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Setpoints sent successfully: ${response.body}');
        print('📡 SSE connection should now be active on server side');
        return true;
      } else {
        print('❌ Failed to send setpoints: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending setpoints: $e');
      return false;
    }
  }

  /// Convenience method to send day setpoints
  static Future<bool> sendDaySetpoints({
    required String deviceId,
    required double temperature,
    required double humidity,
    required double co2,
    required int lightMode,
    double? intensity,
    Map<String, double>? lightPWM,
  }) async {
    return await sendSetpoints(
      deviceId: deviceId,
      period: 'Day', // Capitalized for website format
      temperature: temperature,
      humidity: humidity,
      co2: co2,
      lightMode: lightMode,
      intensity: intensity,
      lightPWM: lightPWM,
    );
  }

  /// Convenience method to send night setpoints
  static Future<bool> sendNightSetpoints({
    required String deviceId,
    required double temperature,
    required double humidity,
    required double co2,
    required int lightMode,
    double? intensity,
    Map<String, double>? lightPWM,
  }) async {
    return await sendSetpoints(
      deviceId: deviceId,
      period: 'Night', // Capitalized for website format
      temperature: temperature,
      humidity: humidity,
      co2: co2,
      lightMode: lightMode,
      intensity: intensity,
      lightPWM: lightPWM,
    );
  }

  /// Send day/night time schedule to gateway
  static Future<bool> sendSchedule({
    required String deviceId,
    required String dayStart, // Format: "HH.MM"
    required String nightStart, // Format: "HH.MM"
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'daystart': dayStart,
        'nightstart': nightStart,
      };

      print('🕐 Sending schedule to gateway (Device $deviceId): ${json.encode(payload)}');
      
      final headers = await _getAuthHeaders();
      final response = await _client.post(
        Uri.parse('$_baseUrl$_setpointEndpoint/$deviceId'),
        headers: headers,
        body: json.encode(payload),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Schedule sent successfully: ${response.body}');
        return true;
      } else {
        print('❌ Failed to send schedule: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending schedule: $e');
      return false;
    }
  }

  /// Send camera capture command to gateway
  static Future<bool> sendCameraCommand({
    required String deviceId,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'take_photos': true,
      };

      print('📷 Sending camera command to gateway (Device $deviceId)');
      
      final headers = await _getAuthHeaders();
      final response = await _client.post(
        Uri.parse('$_baseUrl$_setpointEndpoint/$deviceId'),
        headers: headers,
        body: json.encode(payload),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Camera command sent successfully: ${response.body}');
        return true;
      } else {
        print('❌ Failed to send camera command: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending camera command: $e');
      return false;
    }
  }

  /// Send spectrum capture command to gateway
  static Future<bool> sendSpectrumCommand({
    required String deviceId,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'take_spectrum': true,
      };

      print('🌈 Sending spectrum command to gateway (Device $deviceId)');
      
      final headers = await _getAuthHeaders();
      final response = await _client.post(
        Uri.parse('$_baseUrl$_setpointEndpoint/$deviceId'),
        headers: headers,
        body: json.encode(payload),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Spectrum command sent successfully: ${response.body}');
        return true;
      } else {
        print('❌ Failed to send spectrum command: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending spectrum command: $e');
      return false;
    }
  }

  /// Note: SSE connection is automatically established by the server 
  /// when setpoints are sent to /condition/setpoint/:deviceId
  /// No manual SSE connection needed from client side

  /// Initialize callback SSE connection to listen for gateway feedback
  /// This connects to /condition/get-events-callback/:deviceId
  static Stream<Map<String, dynamic>> initializeCallbackSSE({
    required String deviceId,
  }) {
    if (_callbackController != null && !_callbackController!.isClosed) {
      _callbackController!.close();
    }
    
    _callbackController = StreamController<Map<String, dynamic>>.broadcast();
    _isCallbackSSEActive = true;
    
    _connectCallbackSSE(deviceId: deviceId);
    
    return _callbackController!.stream;
  }

  /// Connect to callback SSE endpoint for gateway feedback
  static void _connectCallbackSSE({required String deviceId}) async {
    if (!_isCallbackSSEActive) return;
    
    try {
      final callbackUrl = '$_baseUrl$_callbackEndpoint/$deviceId';
      
      print('🔗 Connecting to Callback SSE: $callbackUrl');
      
      final request = http.Request('GET', Uri.parse(callbackUrl));
      final token = await _getJwtToken();
      request.headers.addAll({
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      
      final response = await _client.send(request);
      
      if (response.statusCode == 200) {
        print('✅ Callback SSE connection established');
        
        response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (String line) {
            if (line.startsWith('data: ')) {
              try {
                final data = json.decode(line.substring(6));
                print('📡 Callback received from gateway: $data');
                _callbackController?.add(data);
              } catch (e) {
                print('❌ Error parsing callback data: $e');
              }
            }
          },
          onError: (error) {
            print('❌ Callback SSE connection error: $error');
            if (_isCallbackSSEActive) {
              // Implement reconnection logic
              Timer(const Duration(seconds: 5), () => _connectCallbackSSE(deviceId: deviceId));
            }
          },
          onDone: () {
            print('🔌 Callback SSE connection closed');
            if (_isCallbackSSEActive) {
              // Implement reconnection logic
              Timer(const Duration(seconds: 5), () => _connectCallbackSSE(deviceId: deviceId));
            }
          },
        );
      } else {
        print('❌ Callback SSE connection failed: ${response.statusCode}');
        if (_isCallbackSSEActive) {
          Timer(const Duration(seconds: 5), () => _connectCallbackSSE(deviceId: deviceId));
        }
      }
    } catch (e) {
      print('❌ Error connecting to Callback SSE: $e');
      if (_isCallbackSSEActive) {
        Timer(const Duration(seconds: 5), () => _connectCallbackSSE(deviceId: deviceId));
      }
    }
  }

  /// Close callback SSE connection
  static void closeCallbackSSE() {
    print('🔌 Closing Callback SSE connection...');
    _isCallbackSSEActive = false;
    _callbackController?.close();
    _callbackController = null;
  }

  /// Check if user is authenticated (has valid JWT token)
  static Future<bool> isAuthenticated() async {
    final token = await _getJwtToken();
    return token != null && token.isNotEmpty;
  }

  /// Get current user information from secure storage
  static Future<Map<String, String?>> getCurrentUser() async {
    return {
      'userId': await _getUserId(),
      'userLevel': await _getUserLevel(),
      'hasToken': (await _getJwtToken()) != null ? 'true' : 'false',
    };
  }

  /// Clear authentication data (for logout)
  static Future<void> clearAuth() async {
    try {
      await _secureStorage.delete(key: 'jwt_token');
      await _secureStorage.delete(key: 'user_id');
      await _secureStorage.delete(key: 'user_level');
      print('✅ Authentication data cleared');
    } catch (e) {
      print('❌ Error clearing authentication data: $e');
    }
  }

  /// Validate setpoint values against limits (implement your own limits)
  static bool validateSetpoints({
    required double temperature,
    required double humidity,
    required double co2,
    required int lightMode,
    Map<String, double>? lightPWM,
  }) {
    // Define your limits here based on backend validation
    const double tempMin = 15.0, tempMax = 35.0;
    const double humMin = 30.0, humMax = 90.0;
    const double co2Min = 400.0, co2Max = 2000.0;
    const int lightModeMin = 1, lightModeMax = 6;
    const double lightMin = 0.0, lightMax = 100.0;

    if (temperature < tempMin || temperature > tempMax) {
      print('❌ Temperature out of range: $temperature (min: $tempMin, max: $tempMax)');
      return false;
    }
    
    if (humidity < humMin || humidity > humMax) {
      print('❌ Humidity out of range: $humidity (min: $humMin, max: $humMax)');
      return false;
    }
    
    if (co2 < co2Min || co2 > co2Max) {
      print('❌ CO2 out of range: $co2 (min: $co2Min, max: $co2Max)');
      return false;
    }
    
    if (lightMode < lightModeMin || lightMode > lightModeMax) {
      print('❌ Light mode out of range: $lightMode (min: $lightModeMin, max: $lightModeMax)');
      return false;
    }
    
    if (lightPWM != null) {
      for (String key in lightPWM.keys) {
        double value = lightPWM[key]!;
        if (value < lightMin || value > lightMax) {
          print('❌ Light PWM ($key) out of range: $value (min: $lightMin, max: $lightMax)');
          return false;
        }
      }
    }
    
    return true;
  }
}