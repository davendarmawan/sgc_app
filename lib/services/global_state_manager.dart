import 'dart:async';

/// Global state manager for tracking live condition data across the app
class GlobalStateManager {
  static final GlobalStateManager _instance = GlobalStateManager._internal();
  factory GlobalStateManager() => _instance;
  GlobalStateManager._internal();

  // Stream controllers for reactive updates
  final StreamController<int> _lightModeController = StreamController<int>.broadcast();
  final StreamController<Map<String, dynamic>> _conditionDataController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Current state variables
  int _currentLightMode = 0;
  Map<String, dynamic> _latestConditionData = {};
  DateTime? _lastUpdate;
  String? _currentDeviceId;

  // Getters
  int get currentLightMode => _currentLightMode;
  Map<String, dynamic> get latestConditionData => Map.from(_latestConditionData);
  DateTime? get lastUpdate => _lastUpdate;
  String? get currentDeviceId => _currentDeviceId;

  // Streams for listening to changes
  Stream<int> get lightModeStream => _lightModeController.stream;
  Stream<Map<String, dynamic>> get conditionDataStream => _conditionDataController.stream;

  /// Update the current light mode
  void updateLightMode(int lightMode) {
    if (_currentLightMode != lightMode) {
      _currentLightMode = lightMode;
      _lastUpdate = DateTime.now();
      _lightModeController.add(lightMode);
      
      print('🔆 Global State: Light mode updated to $_currentLightMode');
    }
  }

  /// Update the current device ID
  void updateDeviceId(String deviceId) {
    _currentDeviceId = deviceId;
    print('📱 Global State: Device ID updated to $_currentDeviceId');
  }

  /// Update the complete condition data
  void updateConditionData(Map<String, dynamic> data) {
    _latestConditionData = Map.from(data);
    _lastUpdate = DateTime.now();
    
    // Extract and update light mode if available
    if (data.containsKey('SPlight_mode')) {
      final lightMode = data['SPlight_mode'] as int? ?? 0;
      updateLightMode(lightMode);
    }
    
    // Emit the complete data
    _conditionDataController.add(_latestConditionData);
    
    print('📊 Global State: Condition data updated with ${data.keys.length} fields');
  }

  /// Get the spectrum reference image URL based on current light mode
  String getSpectrumReferenceUrl() {
    final baseUrl = 'https://demo.smartfarm.id/spectrometer';
    return '$baseUrl/${_currentDeviceId ?? "1"}_spectrometer_reference_$_currentLightMode.png';
  }

  /// Get spectrum reference asset path (if using local assets as fallback)
  String getSpectrumReferenceAsset() {
    return 'assets/spectrometer_reference_$_currentLightMode.png';
  }

  /// Get formatted light mode description
  String getLightModeDescription() {
    switch (_currentLightMode) {
      case 0:
        return 'Auto Mode';
      case 1:
        return 'Growth Mode';
      case 2:
        return 'Bloom Mode';
      case 3:
        return 'Fruiting Mode';
      case 4:
        return 'Vegetative Mode';
      case 5:
        return 'Custom Mode';
      case 6:
        return 'Manual Mode';
      default:
        return 'Unknown Mode ($_currentLightMode)';
    }
  }

  /// Check if condition data is fresh (within last 30 seconds)
  bool get isDataFresh {
    if (_lastUpdate == null) return false;
    return DateTime.now().difference(_lastUpdate!).inSeconds < 30;
  }

  /// Get sensor value safely
  double getSensorValue(String sensorKey, {double defaultValue = 0.0}) {
    final value = _latestConditionData[sensorKey];
    if (value == null) return defaultValue;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    
    return defaultValue;
  }

  /// Get formatted sensor reading
  String getFormattedSensorReading(String sensor) {
    switch (sensor.toLowerCase()) {
      case 'temperature':
        return '${getSensorValue('temperature').toStringAsFixed(1)} °C';
      case 'humidity':
        return '${getSensorValue('humidity').toStringAsFixed(1)} %';
      case 'co2':
      case 'co2level':
        return '${getSensorValue('co2level').toStringAsFixed(0)} ppm';
      case 'light_intensity':
      case 'intensity':
        return '${getSensorValue('intensity').toStringAsFixed(0)} LUX';
      case 'cpu_temp':
        return '${getSensorValue('cpu_temp').toStringAsFixed(1)} °C';
      default:
        return 'N/A';
    }
  }

  /// Clear all data (useful for logout or device switch)
  void clearData() {
    _currentLightMode = 0;
    _latestConditionData.clear();
    _lastUpdate = null;
    _currentDeviceId = null;
    
    print('🧹 Global State: All data cleared');
  }

  /// Dispose of resources
  void dispose() {
    _lightModeController.close();
    _conditionDataController.close();
  }
}

/// Global instance for easy access
final globalState = GlobalStateManager();