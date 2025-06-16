import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationItem {
  final DateTime dateTime;
  final String header;
  final String info;

  NotificationItem({
    required this.dateTime,
    required this.header,
    required this.info,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      dateTime: DateTime.parse(json['dateTime']),
      header: json['header'],
      info: json['info'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'header': header,
      'info': info,
    };
  }
}

class LiveConditionService {
  StreamController<Map<String, dynamic>>? _controller;
  StreamController<NotificationItem>? _notificationController;
  http.Client? _client;
  String? _deviceId;
  String? _baseUrl;
  String? _authToken;
  
  // Latest received data from gateway
  Map<String, dynamic> latestData = {};
  
  // Connection status
  bool _isConnected = false;
  DateTime? _lastDataReceived;

  // Notification management
  final List<NotificationItem> _notifications = [];
  final Set<String> _activeNotifications = {}; // To track active notifications and avoid duplicates

  LiveConditionService({
    required String deviceId,
    required String baseUrl,
    String? authToken,
  }) {
    _deviceId = deviceId;
    _baseUrl = baseUrl;
    _authToken = authToken;
  }

  // Start listening to live condition data from gateway
  Stream<Map<String, dynamic>> startListening() {
    _controller = StreamController<Map<String, dynamic>>.broadcast();
    _notificationController = StreamController<NotificationItem>.broadcast();
    _connectToSSE();
    return _controller!.stream;
  }

  // Get notification stream
  Stream<NotificationItem> get notificationStream => _notificationController!.stream;

  // Get all notifications
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  // Get notification count
  int get notificationCount => _notifications.length;

  void _connectToSSE() async {
    try {
      _client = http.Client();
      final request = http.Request('GET', Uri.parse('$_baseUrl/condition/events/$_deviceId'));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      
      // Add authentication if provided
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      print('Connecting to: $_baseUrl/condition/events/$_deviceId');
      final response = await _client!.send(request);
      
      if (response.statusCode == 200) {
        print('Connected to live condition data stream');
        _isConnected = true;
        
        response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              _handleSSEData,
              onError: (error) {
                print('Live Condition SSE Error: $error');
                _isConnected = false;
                _reconnect();
              },
              onDone: () {
                print('Live Condition SSE Connection closed');
                _isConnected = false;
                _reconnect();
              },
            );
      } else {
        print('Failed to connect: ${response.statusCode}');
        _isConnected = false;
        _reconnect();
      }
    } catch (e) {
      print('Failed to connect to Live Condition SSE: $e');
      _isConnected = false;
      _reconnect();
    }
  }

  void _handleSSEData(String data) {
    if (data.startsWith('data: ')) {
      try {
        final jsonData = data.substring(6); // Remove 'data: ' prefix
        if (jsonData.trim().isNotEmpty && jsonData != '{}') {
          final Map<String, dynamic> conditionData = json.decode(jsonData);
          
          // Update latest data
          latestData = conditionData;
          _lastDataReceived = DateTime.now();
          
          // Check for notifications
          _checkForNotifications(conditionData);
          
          // Emit to stream listeners
          _controller?.add(conditionData);
          
          print('Received condition data: ${conditionData.keys.join(', ')}');
        }
      } catch (e) {
        print('Error parsing condition SSE data: $e');
      }
    }
  }

  void _checkForNotifications(Map<String, dynamic> data) {
    final now = DateTime.now();
    
    // 1. Door Open Notification
    final doorCondition = data['DoorCondition'] ?? 0;
    if (doorCondition == 1) {
      _addNotificationIfNew('door_open', NotificationItem(
        dateTime: now,
        header: 'Door Alert',
        info: 'Door is currently open',
      ));
    } else {
      _removeActiveNotification('door_open');
    }

    // 2. Temperature notifications
    final tempHigh = data['tempHigh'] ?? 0;
    final tempLow = data['tempLow'] ?? 0;
    
    if (tempHigh == 1) {
      _addNotificationIfNew('temp_high', NotificationItem(
        dateTime: now,
        header: 'Temperature Alert',
        info: 'Temperature is above setpoint (${currentTemperature.toStringAsFixed(1)}°C)',
      ));
    } else {
      _removeActiveNotification('temp_high');
    }
    
    if (tempLow == 1) {
      _addNotificationIfNew('temp_low', NotificationItem(
        dateTime: now,
        header: 'Temperature Alert',
        info: 'Temperature is below setpoint (${currentTemperature.toStringAsFixed(1)}°C)',
      ));
    } else {
      _removeActiveNotification('temp_low');
    }

    // 3. Humidity notifications
    final humHigh = data['humHigh'] ?? 0;
    final humLow = data['humLow'] ?? 0;
    
    if (humHigh == 1) {
      _addNotificationIfNew('hum_high', NotificationItem(
        dateTime: now,
        header: 'Humidity Alert',
        info: 'Humidity is above setpoint (${currentHumidity.toStringAsFixed(1)}%)',
      ));
    } else {
      _removeActiveNotification('hum_high');
    }
    
    if (humLow == 1) {
      _addNotificationIfNew('hum_low', NotificationItem(
        dateTime: now,
        header: 'Humidity Alert',
        info: 'Humidity is below setpoint (${currentHumidity.toStringAsFixed(1)}%)',
      ));
    } else {
      _removeActiveNotification('hum_low');
    }

    // 4. CO2 notifications
    final co2High = data['co2High'] ?? 0;
    final co2Low = data['co2Low'] ?? 0;
    
    if (co2High == 1) {
      _addNotificationIfNew('co2_high', NotificationItem(
        dateTime: now,
        header: 'CO2 Alert',
        info: 'CO2 level is above setpoint (${currentCO2.toStringAsFixed(0)} ppm)',
      ));
    } else {
      _removeActiveNotification('co2_high');
    }
    
    if (co2Low == 1) {
      _addNotificationIfNew('co2_low', NotificationItem(
        dateTime: now,
        header: 'CO2 Alert',
        info: 'CO2 level is below setpoint (${currentCO2.toStringAsFixed(0)} ppm)',
      ));
    } else {
      _removeActiveNotification('co2_low');
    }

    // 5. CO2 System problems
    final co2ScrubberProblem = data['co2ScrubberProblem'] ?? 0;
    final co2TankProblem = data['co2TankProblem'] ?? 0;
    
    if (co2ScrubberProblem == 1) {
      _addNotificationIfNew('co2_scrubber', NotificationItem(
        dateTime: now,
        header: 'CO2 System Alert',
        info: 'CO2 is not decreasing - check scrubber system',
      ));
    } else {
      _removeActiveNotification('co2_scrubber');
    }
    
    if (co2TankProblem == 1) {
      _addNotificationIfNew('co2_tank', NotificationItem(
        dateTime: now,
        header: 'CO2 System Alert',
        info: 'CO2 is not increasing - check CO2 tank or injection system',
      ));
    } else {
      _removeActiveNotification('co2_tank');
    }
  }

  void _addNotificationIfNew(String notificationId, NotificationItem notification) {
    if (!_activeNotifications.contains(notificationId)) {
      _activeNotifications.add(notificationId);
      _notifications.insert(0, notification); // Add to beginning for newest first
      _notificationController?.add(notification);
      print('Added notification: ${notification.header}');
    }
  }

  void _removeActiveNotification(String notificationId) {
    _activeNotifications.remove(notificationId);
  }

  // Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    _activeNotifications.clear();
  }

  // Remove specific notification
  void removeNotification(NotificationItem notification) {
    _notifications.remove(notification);
  }

  void _reconnect() {
    Timer(const Duration(seconds: 5), () {
      if (_controller != null && !_controller!.isClosed) {
        print('Attempting to reconnect...');
        _connectToSSE();
      }
    });
  }

  // Getter methods for easy access to latest data
  
  // Current sensor readings
  double get currentTemperature => (latestData['temperature'] ?? 0).toDouble();
  double get currentHumidity => (latestData['humidity'] ?? 0).toDouble();
  double get currentCO2 => (latestData['co2level'] ?? 0).toDouble();
  double get currentLightIntensity => (latestData['intensity'] ?? 0).toDouble();
  double get currentCPUTemp => (latestData['cpu_temp'] ?? 0).toDouble();
  
  // Water and system status
  int get waterStatus => latestData['water_status'] ?? 1;
  int get co2TubeStatus => latestData['co2tube_status'] ?? 1;
  int get scrubberStatus => latestData['scrubber_status'] ?? 1;
  
  // Current setpoints from gateway
  double get setpointTemperature => (latestData['SPtemp'] ?? 0).toDouble();
  double get setpointHumidity => (latestData['SPhum'] ?? 0).toDouble();
  double get setpointCO2 => (latestData['SPco2'] ?? 0).toDouble();
  double get setpointLightIntensity => (latestData['SPlight_intensity'] ?? 0).toDouble();
  int get setpointLightMode => latestData['SPlight_mode'] ?? 0;
  
  // Connection status
  bool get isConnected => _isConnected;
  DateTime? get lastDataReceived => _lastDataReceived;
  
  // Check if data is recent (within last 30 seconds)
  bool get isDataFresh {
    if (_lastDataReceived == null) return false;
    return DateTime.now().difference(_lastDataReceived!).inSeconds < 30;
  }
  
  // Helper method to get formatted condition values
  String getFormattedCondition(String sensor) {
    switch (sensor.toLowerCase()) {
      case 'temperature':
        return '${currentTemperature.toStringAsFixed(1)} °C';
      case 'humidity':
        return '${currentHumidity.toStringAsFixed(1)} %';
      case 'co2':
        return '${currentCO2.toStringAsFixed(0)} ppm';
      case 'light':
        return '${currentLightIntensity.toStringAsFixed(0)} LUX';
      case 'cpu_temp':
        return '${currentCPUTemp.toStringAsFixed(1)} °C';
      default:
        return '0';
    }
  }
  
  // Helper method to get formatted setpoint values
  String getFormattedSetpoint(String sensor) {
    switch (sensor.toLowerCase()) {
      case 'temperature':
        return '${setpointTemperature.toStringAsFixed(1)} °C';
      case 'humidity':
        return '${setpointHumidity.toStringAsFixed(1)} %';
      case 'co2':
        return '${setpointCO2.toStringAsFixed(0)} ppm';
      case 'light':
        if (setpointLightMode == 0) {
          return 'Manual';
        } else {
          return '${setpointLightIntensity.toStringAsFixed(0)} LUX';
        }
      default:
        return '0';
    }
  }
  
  // Get status indicators
  String getSystemStatus() {
    List<String> issues = [];
    
    if (waterStatus != 1) issues.add('Water System');
    if (co2TubeStatus != 1) issues.add('CO2 Tube');
    if (scrubberStatus != 1) issues.add('Scrubber');
    if (!isDataFresh) issues.add('Connection');
    
    if (issues.isEmpty) {
      return 'All Systems Normal';
    } else {
      return 'Issues: ${issues.join(', ')}';
    }
  }
  
  // Get connection info
  Map<String, dynamic> getConnectionInfo() {
    return {
      'connected': _isConnected,
      'lastData': _lastDataReceived?.toIso8601String(),
      'dataFresh': isDataFresh,
      'deviceId': _deviceId,
    };
  }
  
  // Get all current data as a formatted map
  Map<String, dynamic> getAllFormattedData() {
    return {
      'conditions': {
        'temperature': getFormattedCondition('temperature'),
        'humidity': getFormattedCondition('humidity'),
        'co2': getFormattedCondition('co2'),
        'light': getFormattedCondition('light'),
        'cpu_temp': getFormattedCondition('cpu_temp'),
      },
      'setpoints': {
        'temperature': getFormattedSetpoint('temperature'),
        'humidity': getFormattedSetpoint('humidity'),
        'co2': getFormattedSetpoint('co2'),
        'light': getFormattedSetpoint('light'),
      },
      'status': {
        'system': getSystemStatus(),
        'water': waterStatus == 1 ? 'OK' : 'Issue',
        'co2tube': co2TubeStatus == 1 ? 'OK' : 'Issue',
        'scrubber': scrubberStatus == 1 ? 'OK' : 'Issue',
      },
      'connection': getConnectionInfo(),
      'notifications': {
        'count': notificationCount,
        'hasNew': notificationCount > 0,
      },
    };
  }

  void dispose() {
    _controller?.close();
    _notificationController?.close();
    _client?.close();
    _isConnected = false;
  }
}