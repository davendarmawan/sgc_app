import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _baseUrl = 'https://demo.smartfarm.id';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _loginEndpoint = '$_baseUrl/user/login';

  /// Logs in the user with [email] and [password].
  /// 
  /// Returns true if login is successful, false otherwise.
  /// On success, stores the JWT token and user info securely.
  static Future<bool> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(_loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'umail': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Example expected response format:
        // {
        //   "token": 12345,
        //   "level": 1,
        //   "jwt_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
        // }
        
        if (data.containsKey('token') && 
            data.containsKey('level') && 
            data.containsKey('jwt_token')) {
          
          final int userId = data['token'];
          final int userLevel = data['level'];
          final String jwtToken = data['jwt_token'];

          // Store JWT token and user info securely
          await _secureStorage.write(key: 'jwt_token', value: jwtToken);
          await _secureStorage.write(key: 'user_id', value: userId.toString());
          await _secureStorage.write(key: 'user_level', value: userLevel.toString());
          
          return true;
        } else {
          // Unexpected response format
          print('AuthService.loginUser: Unexpected response format: $data');
          return false;
        }
      } else {
        // Handle error responses, e.g. wrong password
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

  /// Retrieves the stored JWT token.
  static Future<String?> getJwtToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  /// Retrieves the stored user ID.
  static Future<String?> getUserId() async {
    return await _secureStorage.read(key: 'user_id');
  }

  /// Retrieves the stored user level.
  static Future<String?> getUserLevel() async {
    return await _secureStorage.read(key: 'user_level');
  }

  /// Checks if user is currently logged in by verifying JWT token exists.
  static Future<bool> isLoggedIn() async {
    final token = await getJwtToken();
    return token != null && token.isNotEmpty;
  }

  /// Logs out the user by calling the backend API and clearing stored data.
  /// 
  /// Returns true if logout is successful, false otherwise.
  /// Clears stored tokens and user info regardless of API response.
  static Future<bool> logoutUser() async {
    try {
      final jwtToken = await getJwtToken();
      
      if (jwtToken != null && jwtToken.isNotEmpty) {
        // Call the logout API
        final response = await http.post(
          Uri.parse('$_baseUrl/user/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        );
        
        // Clear local storage regardless of API response
        await _clearStoredData();
        
        if (response.statusCode == 200) {
          print('AuthService.logoutUser: Logout successful');
          return true;
        } else {
          print('AuthService.logoutUser: API logout failed with status ${response.statusCode}');
          // Still return true since we cleared local data
          return true;
        }
      } else {
        // No token found, just clear any remaining data
        await _clearStoredData();
        return true;
      }
    } catch (e) {
      print('AuthService.logoutUser: Exception caught: $e');
      // Clear local storage even if API call fails
      await _clearStoredData();
      return true; // Return true since local cleanup succeeded
    }
  }

  /// Clears stored tokens and user info (local cleanup).
  static Future<void> _clearStoredData() async {
    await _secureStorage.delete(key: 'jwt_token');
    await _secureStorage.delete(key: 'user_id');
    await _secureStorage.delete(key: 'user_level');
  }

  /// Legacy method for backward compatibility - calls logoutUser()
  @deprecated
  static Future<void> logout() async {
    await logoutUser();
  }
}