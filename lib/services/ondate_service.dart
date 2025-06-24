import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'https://demo.smartfarm.id/condition'; // Replace with your actual API URL
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // Get headers with authorization
  static Future<Map<String, String>> get _headers async {
    final String? token = await _secureStorage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Fetch condition data for a specific device and date
  static Future<ConditionData> getConditionData(int deviceId, {String? date}) async {
    try {
      String url = '$baseUrl/info/$deviceId';
      if (date != null) {
        url += '?date=$date';
      }
      
      final headers = await _headers;
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('API URL: $url'); // Debug print
      print('Response status: ${response.statusCode}'); // Debug print
      print('Response body: ${response.body}'); // Debug print
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Parsed JSON: $jsonResponse'); // Debug print
        
        // Pass the entire response or just the data part based on structure
        if (jsonResponse.containsKey('data')) {
          return ConditionData.fromJson(jsonResponse);
        } else {
          // If the response is directly the data array
          return ConditionData.fromJson({'data': jsonResponse});
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. You don\'t have permission to view this device.');
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'No error message';
        throw Exception('Failed to load condition data: ${response.statusCode}\nError: $errorBody');
      }
    } catch (e) {
      print('API Error: $e'); // Debug print
      if (e.toString().contains('Authentication failed') || 
          e.toString().contains('Access denied')) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  // Helper method to get user ID from secure storage
  static Future<String?> getUserId() async {
    return await _secureStorage.read(key: 'user_id');
  }

  // Helper method to get user level from secure storage
  static Future<String?> getUserLevel() async {
    return await _secureStorage.read(key: 'user_level');
  }

  // Helper method to check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    return token != null && token.isNotEmpty;
  }

  // Helper method to clear all stored data (for logout)
  static Future<void> clearStorage() async {
    await _secureStorage.delete(key: 'jwt_token');
    await _secureStorage.delete(key: 'user_id');
    await _secureStorage.delete(key: 'user_level');
  }
}

// Data models
class ConditionData {
  final List<ConditionRecord> data;
  final List<String> xLabels;
  final List<double> temperatureValues;
  final List<double> humidityValues;
  final List<double> co2Values;
  final List<double> lightIntensityValues;

  ConditionData({
    required this.data,
    required this.xLabels,
    required this.temperatureValues,
    required this.humidityValues,
    required this.co2Values,
    required this.lightIntensityValues,
  });

  factory ConditionData.fromJson(Map<String, dynamic> json) {
    // Handle both possible response structures
    List<dynamic> dataList;
    
    if (json['data'] is List) {
      // If 'data' is directly a list
      dataList = json['data'] as List<dynamic>;
    } else if (json['data'] is Map && (json['data'] as Map)['data'] is List) {
      // If 'data' contains another 'data' key with the list
      dataList = (json['data'] as Map)['data'] as List<dynamic>;
    } else {
      // Fallback: treat the entire json as the data list if it's a list
      dataList = json is List ? json as List<dynamic> : <dynamic>[];
    }

    final List<ConditionRecord> records = dataList
        .where((item) => item is Map<String, dynamic>) // Filter valid items
        .map((item) => ConditionRecord.fromJson(item as Map<String, dynamic>))
        .toList();

    // Extract values for graphs
    final List<String> xLabels = records
        .map((record) => record.time) // Assuming time format like "14:30"
        .toList();
    
    final List<double> temperatureValues = records
        .map((record) => record.temperature)
        .toList();
    
    final List<double> humidityValues = records
        .map((record) => record.humidity)
        .toList();
    
    final List<double> co2Values = records
        .map((record) => record.co2)
        .toList();
    
    final List<double> lightIntensityValues = records
        .map((record) => record.lightIntensity)
        .toList();

    return ConditionData(
      data: records,
      xLabels: xLabels,
      temperatureValues: temperatureValues,
      humidityValues: humidityValues,
      co2Values: co2Values,
      lightIntensityValues: lightIntensityValues,
    );
  }
}

class ConditionRecord {
  final int id;
  final int deviceId;
  final double temperature;
  final double humidity;
  final double co2;
  final double lightIntensity;
  final String createdAt;
  final String date;
  final String time;

  ConditionRecord({
    required this.id,
    required this.deviceId,
    required this.temperature,
    required this.humidity,
    required this.co2,
    required this.lightIntensity,
    required this.createdAt,
    required this.date,
    required this.time,
  });

  factory ConditionRecord.fromJson(Map<String, dynamic> json) {
    return ConditionRecord(
      id: json['id']?.toInt() ?? 0,
      deviceId: json['device_id']?.toInt() ?? 0,
      temperature: _parseDouble(json['temperature']),
      humidity: _parseDouble(json['humidity']),
      co2: _parseDouble(json['co2level']),
      lightIntensity: _parseDouble(json['intensity']),
      createdAt: json['created_at']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
    );
  }
}

// Helper method to safely parse double values
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      return 0.0;
    }
  }
  return 0.0;
}
