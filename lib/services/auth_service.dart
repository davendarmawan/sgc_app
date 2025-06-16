import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _baseUrl = 'https://demo.smartfarm.id';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _loginEndpoint = '$_baseUrl/user/login';
  
  // 24-hour session timeout (in milliseconds)
  static const int _sessionTimeoutMs = 24 * 60 * 60 * 1000; // 24 hours

  /// Logs in the user with [email] and [password].
  /// 
  /// Returns true if login is successful, false otherwise.
  /// On success, stores the JWT token, user info, and login timestamp securely.
  static Future<bool> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(_loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'umail': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data.containsKey('token') && 
            data.containsKey('level') && 
            data.containsKey('jwt_token')) {
          
          final int userId = data['token'];
          final int userLevel = data['level'];
          final String jwtToken = data['jwt_token'];
          
          // Store current timestamp for session timeout
          final String loginTimestamp = DateTime.now().millisecondsSinceEpoch.toString();

          // Store JWT token, user info, and login timestamp securely
          await _secureStorage.write(key: 'jwt_token', value: jwtToken);
          await _secureStorage.write(key: 'user_id', value: userId.toString());
          await _secureStorage.write(key: 'user_level', value: userLevel.toString());
          await _secureStorage.write(key: 'login_timestamp', value: loginTimestamp);
          
          print('AuthService.loginUser: Login successful, session expires in 24 hours');
          return true;
        } else {
          print('AuthService.loginUser: Unexpected response format: $data');
          return false;
        }
      } else {
        final Map<String, dynamic>? errorData = response.body.isNotEmpty
            ? jsonDecode(response.body) as Map<String, dynamic>?
            : null;
        
        final String errorMessage = errorData != null && errorData.containsKey('message')
            ? errorData['message']
            : 'Login failed with status code ${response.statusCode}';
        
        print('AuthService.loginUser: $errorMessage');
        return false;
      }
    } catch (e) {
      print('AuthService.loginUser: Exception caught: $e');
      return false;
    }
  }

  /// Checks if the current session is still valid (within 24 hours)
  /// 
  /// Returns true if session is valid, false if expired or no session exists
  static Future<bool> isSessionValid() async {
    try {
      final String? loginTimestampStr = await _secureStorage.read(key: 'login_timestamp');
      final String? jwtToken = await _secureStorage.read(key: 'jwt_token');
      
      // No session data found
      if (loginTimestampStr == null || jwtToken == null) {
        print('AuthService.isSessionValid: No session data found');
        return false;
      }
      
      // Parse login timestamp
      final int loginTimestamp = int.tryParse(loginTimestampStr) ?? 0;
      if (loginTimestamp == 0) {
        print('AuthService.isSessionValid: Invalid login timestamp');
        await _clearStoredData(); // Clear corrupted data
        return false;
      }
      
      // Check if session has expired (24 hours)
      final int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final int sessionAge = currentTimestamp - loginTimestamp;
      
      if (sessionAge > _sessionTimeoutMs) {
        print('AuthService.isSessionValid: Session expired (${(sessionAge / (1000 * 60 * 60)).toStringAsFixed(1)} hours old)');
        await _clearStoredData(); // Auto-logout expired session
        return false;
      }
      
      // Session is still valid
      final double hoursRemaining = (_sessionTimeoutMs - sessionAge) / (1000 * 60 * 60);
      print('AuthService.isSessionValid: Session valid, ${hoursRemaining.toStringAsFixed(1)} hours remaining');
      return true;
      
    } catch (e) {
      print('AuthService.isSessionValid: Exception caught: $e');
      await _clearStoredData(); // Clear data on error
      return false;
    }
  }

  /// Checks if user is currently logged in with a valid session
  /// 
  /// This combines token existence check with session timeout validation
  static Future<bool> isLoggedIn() async {
    return await isSessionValid();
  }

  /// Gets remaining session time in hours (for debugging/UI purposes)
  static Future<double> getRemainingSessionHours() async {
    try {
      final String? loginTimestampStr = await _secureStorage.read(key: 'login_timestamp');
      
      if (loginTimestampStr == null) return 0.0;
      
      final int loginTimestamp = int.tryParse(loginTimestampStr) ?? 0;
      if (loginTimestamp == 0) return 0.0;
      
      final int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final int sessionAge = currentTimestamp - loginTimestamp;
      final int remainingMs = _sessionTimeoutMs - sessionAge;
      
      if (remainingMs <= 0) return 0.0;
      
      return remainingMs / (1000 * 60 * 60); // Convert to hours
    } catch (e) {
      return 0.0;
    }
  }

  /// Retrieves the stored JWT token if session is valid
  static Future<String?> getJwtToken() async {
    if (await isSessionValid()) {
      return await _secureStorage.read(key: 'jwt_token');
    }
    return null;
  }

  /// Retrieves the stored user ID if session is valid
  static Future<String?> getUserId() async {
    if (await isSessionValid()) {
      return await _secureStorage.read(key: 'user_id');
    }
    return null;
  }

  /// Retrieves the stored user level if session is valid
  static Future<String?> getUserLevel() async {
    if (await isSessionValid()) {
      return await _secureStorage.read(key: 'user_level');
    }
    return null;
  }

  /// 🚀 FAST LOGOUT: Immediately clears local data, notifies server in background
  static Future<void> fastLogout() async {
    try {
      final jwtToken = await _secureStorage.read(key: 'jwt_token');
      
      await _clearStoredData();
      print('AuthService.fastLogout: Local data cleared instantly');
      
      if (jwtToken != null && jwtToken.isNotEmpty) {
        _notifyServerLogoutInBackground(jwtToken);
      }
      
    } catch (e) {
      print('AuthService.fastLogout: Exception during local cleanup: $e');
      await _clearStoredData();
      rethrow;
    }
  }

  /// Background server logout notification (fire-and-forget)
  static void _notifyServerLogoutInBackground(String jwtToken) {
    Future.delayed(Duration.zero, () async {
      try {
        print('AuthService: Notifying server of logout in background...');
        
        final response = await http.post(
          Uri.parse('$_baseUrl/user/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        );
        
        if (response.statusCode == 200) {
          print('✅ AuthService: Server logout notification successful');
        } else {
          print('⚠️ AuthService: Server logout notification failed with status ${response.statusCode}');
        }
        
      } catch (e) {
        print('⚠️ AuthService: Server logout notification failed: $e');
      }
    });
  }

  /// Logs out the user by calling the backend API and clearing stored data.
  /// 
  /// ⚠️ SLOW METHOD - Use fastLogout() for UI logout buttons
  static Future<bool> logoutUser() async {
    try {
      final jwtToken = await _secureStorage.read(key: 'jwt_token');
      
      if (jwtToken != null && jwtToken.isNotEmpty) {
        final response = await http.post(
          Uri.parse('$_baseUrl/user/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        );
        
        await _clearStoredData();
        
        if (response.statusCode == 200) {
          print('AuthService.logoutUser: Logout successful');
          return true;
        } else {
          print('AuthService.logoutUser: API logout failed with status ${response.statusCode}');
          return true;
        }
      } else {
        await _clearStoredData();
        return true;
      }
    } catch (e) {
      print('AuthService.logoutUser: Exception caught: $e');
      await _clearStoredData();
      return true;
    }
  }

  /// Clears stored tokens, user info, and login timestamp (local cleanup)
  static Future<void> _clearStoredData() async {
    await _secureStorage.delete(key: 'jwt_token');
    await _secureStorage.delete(key: 'user_id');
    await _secureStorage.delete(key: 'user_level');
    await _secureStorage.delete(key: 'login_timestamp'); // Clear timestamp too
  }

  /// Legacy method for backward compatibility
  @deprecated
  static Future<void> logout() async {
    await _clearStoredData();
  }

  /// Force session expiry (for testing purposes)
  static Future<void> expireSession() async {
    await _secureStorage.write(
      key: 'login_timestamp', 
      value: (DateTime.now().millisecondsSinceEpoch - _sessionTimeoutMs - 1000).toString()
    );
  }
}