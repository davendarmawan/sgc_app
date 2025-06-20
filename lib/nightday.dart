import 'package:flutter/material.dart';
import 'services/setpoint_service.dart'; // Import your setpoint service

class NightDaySettingsPage extends StatefulWidget {
  final String deviceId; // Add device ID parameter
  
  const NightDaySettingsPage({
    super.key,
    required this.deviceId, // Make device ID required
  });

  @override
  State<NightDaySettingsPage> createState() => _NightDaySettingsPageState();
}

class _NightDaySettingsPageState extends State<NightDaySettingsPage> {
  TimeOfDay _nightStartTime = const TimeOfDay(
    hour: 18,
    minute: 0,
  ); // Default 18:00
  TimeOfDay _dayStartTime = const TimeOfDay(hour: 6, minute: 0); // Default 6:00
  
  bool _isLoading = false; // Add loading state

  Future<void> _selectTime(BuildContext context, bool isNight) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isNight ? _nightStartTime : _dayStartTime,
    );
    if (picked != null) {
      setState(() {
        if (isNight) {
          _nightStartTime = picked;
        } else {
          _dayStartTime = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final localizations = MaterialLocalizations.of(context);
    final bool use24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;
    return localizations.formatTimeOfDay(
      time,
      alwaysUse24HourFormat: use24HourFormat,
    );
  }

  /// Convert TimeOfDay to "HH.MM" format expected by gateway
  String _timeOfDayToGatewayFormat(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}.${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveSettings() async {
    // Convert times to total minutes since midnight for validation
    int dayStartMinutes = _dayStartTime.hour * 60 + _dayStartTime.minute;
    int nightStartMinutes = _nightStartTime.hour * 60 + _nightStartTime.minute;

    // Check validity: Day Start Time must be strictly before Night Start Time
    if (dayStartMinutes >= nightStartMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid time settings. Day Start Time must be earlier than Night Start Time!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return; // Stop saving due to invalid input
    }

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Convert to gateway format (HH.MM)
      String dayStartGateway = _timeOfDayToGatewayFormat(_dayStartTime);
      String nightStartGateway = _timeOfDayToGatewayFormat(_nightStartTime);

      print('🕐 Sending schedule - Day: $dayStartGateway, Night: $nightStartGateway');

      // Send schedule to API
      bool success = await SetpointService.sendSchedule(
        deviceId: widget.deviceId,
        dayStart: dayStartGateway,
        nightStart: nightStartGateway,
      );

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Night-Day Hours saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save Night-Day Hours. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error saving schedule: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Hide loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFFF7FAFC),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Night-Day Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FAFC), Color(0xFFC4EAFE)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Avatar and Device Info
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue,
                child: CircleAvatar(
                  radius: 47,
                  backgroundImage: AssetImage(
                    'assets/profile.png',
                  ), // Use your avatar image here
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Selected Device:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.deviceId, // Show actual device ID
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Day Start Time Picker with Sun Icon
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Day Start Time',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isLoading ? null : () => _selectTime(context, false),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey[200] : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wb_sunny, 
                        color: _isLoading ? Colors.grey : Colors.orange,
                      ),
                      const SizedBox(width: 15),
                      Text(
                        _formatTimeOfDay(_dayStartTime),
                        style: TextStyle(
                          fontSize: 18,
                          color: _isLoading ? Colors.grey : Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Format: ${_timeOfDayToGatewayFormat(_dayStartTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Night Start Time Picker with Moon Icon
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Night Start Time',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isLoading ? null : () => _selectTime(context, true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey[200] : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.dark_mode, 
                        color: _isLoading ? Colors.grey : const Color(0xFF90A4AE),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        _formatTimeOfDay(_nightStartTime),
                        style: TextStyle(
                          fontSize: 18,
                          color: _isLoading ? Colors.grey : Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Format: ${_timeOfDayToGatewayFormat(_nightStartTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Filled Button (Save)
              SizedBox(
                width: double.infinity,
                height: 40,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  style: FilledButton.styleFrom(
                    backgroundColor: _isLoading ? Colors.grey : Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Saving...',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.save, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Save Night-Day Hour Settings',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 40),

              // SmartFarm Logo
              Image.asset(
                'assets/smartfarm_logo.png', // Replace with your actual logo asset path
                width: 150,
                height: 100,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}