import 'package:flutter/material.dart';
import 'dart:async'; // Add this import for StreamSubscription
import 'variables.dart'; // Import the variables file
import 'package:dropdown_button2/dropdown_button2.dart';
import 'settings.dart';
import 'notifications_loader.dart';
import 'services/setpoint_service.dart'; // Import the setpoint service

class SetpointPage extends StatefulWidget {
  const SetpointPage({super.key});

  @override
  SetpointPageState createState() => SetpointPageState();
}

// Custom thumb shape with blue outline
class CustomThumbShape extends RoundSliderThumbShape {
  final Color outlineColor;
  final double outlineWidth;

  const CustomThumbShape({
    this.outlineColor = Colors.blue,
    this.outlineWidth = 2.0,
  });

  @override
  double get enabledThumbRadius => 12.0;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Draw the white filled circle inside (full radius)
    final Paint fillPaint =
        Paint()
          ..color = sliderTheme.thumbColor ?? Colors.white
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, enabledThumbRadius, fillPaint);

    // Draw the blue outline circle (stroke centered on radius - half stroke width)
    final Paint outlinePaint =
        Paint()
          ..color = outlineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = outlineWidth;

    canvas.drawCircle(
      center,
      enabledThumbRadius - outlineWidth / 2,
      outlinePaint,
    );
  }
}

class SetpointPageState extends State<SetpointPage> {
  String selectedPeriod = 'day'; // day or night selection
  bool isSubmitting = false; // Track submission state
  String deviceId =
      '1'; // Replace with actual device ID - could be from user selection or storage
  StreamSubscription<Map<String, dynamic>>? _callbackSubscription;

  // Store pending setpoint values to apply after gateway confirmation
  Map<String, dynamic>? _pendingSetpoints;

  // Controllers for input fields to capture new setpoints
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _humidityController = TextEditingController();
  final TextEditingController _co2Controller = TextEditingController();
  final TextEditingController _lightIntensityController =
      TextEditingController();

  // Light mode for current selection
  int currentLightMode = 1; // Default light mode

  // PWM values for manual mode
  double currentParPWM = 0;
  double currentRedPWM = 0;
  double currentBluePWM = 0;
  double currentUvPWM = 0;
  double currentIrPWM = 0;

  @override
  void initState() {
    super.initState();
    _updateControllersForPeriod();
    _initializeCallbackListener();
  }

  @override
  void dispose() {
    _tempController.dispose();
    _humidityController.dispose();
    _co2Controller.dispose();
    _lightIntensityController.dispose();
    _callbackSubscription?.cancel();
    SetpointService.closeCallbackSSE();
    super.dispose();
  }

  /// Initialize callback SSE listener for gateway feedback
  void _initializeCallbackListener() {
    _callbackSubscription = SetpointService.initializeCallbackSSE(
      deviceId: deviceId,
    ).listen(
      (callbackData) {
        print('📡 Gateway callback received: $callbackData');

        // Handle different types of callbacks
        if (callbackData['message'] != null) {
          final message = callbackData['message'] as String;

          // Handle specific callback types
          if (message.contains('Setpoint settings received')) {
            print('✅ Gateway confirmed setpoint reception');

            // Now update local variables since gateway confirmed
            if (_pendingSetpoints != null) {
              _applyPendingSetpoints();
            }

            // Show success notification
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ ${_pendingSetpoints?['period']} setpoints applied successfully!',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (message.contains('Camera command received')) {
            print('✅ Gateway confirmed camera command reception');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('📷 Camera command received by gateway'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (message.contains('Day Night time settings received')) {
            print('✅ Gateway confirmed schedule reception');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('🕐 Schedule settings received by gateway'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (message.contains('Spectrum command received')) {
            print('✅ Gateway confirmed spectrum command reception');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('🌈 Spectrum command received by gateway'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      onError: (error) {
        print('❌ Callback stream error: $error');
      },
    );
  }

  /// Apply pending setpoints to local variables after gateway confirmation
  void _applyPendingSetpoints() {
    if (_pendingSetpoints == null) return;

    setState(() {
      final period = _pendingSetpoints!['period'];
      final newTemp = _pendingSetpoints!['temperature'];
      final newHumidity = _pendingSetpoints!['humidity'];
      final newCO2 = _pendingSetpoints!['co2'];
      final lightMode = _pendingSetpoints!['lightMode'];
      final newLightIntensity = _pendingSetpoints!['lightIntensity'];
      final pwmValues = _pendingSetpoints!['pwmValues'];

      if (period == 'day') {
        dayTemperature = newTemp;
        dayHumidity = newHumidity;
        dayCO2 = newCO2;

        // Update day light settings
        if (lightMode == 6) {
          dayLightMode = 'Manual';
          if (pwmValues != null) {
            parDayPWM = pwmValues['par'];
            redDayPWM = pwmValues['red'];
            blueDayPWM = pwmValues['blue'];
            uvDayPWM = pwmValues['uv'];
            irDayPWM = pwmValues['ir'];
          }
        } else {
          dayLightMode = 'Mode $lightMode';
          if (lightMode != 5) {
            dayLightIntensity = newLightIntensity;
          } else {
            dayLightIntensity = 0;
          }
        }
      } else {
        nightTemperature = newTemp;
        nightHumidity = newHumidity;
        nightCO2 = newCO2;

        // Update night light settings
        if (lightMode == 6) {
          nightLightMode = 'Manual';
          if (pwmValues != null) {
            parNightPWM = pwmValues['par'];
            redNightPWM = pwmValues['red'];
            blueNightPWM = pwmValues['blue'];
            uvNightPWM = pwmValues['uv'];
            irNightPWM = pwmValues['ir'];
          }
        } else {
          nightLightMode = 'Mode $lightMode';
          if (lightMode != 5) {
            nightLightIntensity = newLightIntensity;
          } else {
            nightLightIntensity = 0;
          }
        }
      }

      // Clear pending setpoints
      _pendingSetpoints = null;
    });
  }

  // Update controllers based on selected period (day/night)
  void _updateControllersForPeriod() {
    if (selectedPeriod == 'day') {
      _tempController.text = dayTemperature.toString();
      _humidityController.text = dayHumidity.toString();
      _co2Controller.text = dayCO2.toString();
      _lightIntensityController.text = dayLightIntensity.toString();

      // Update light mode
      if (dayLightMode == 'Manual') {
        currentLightMode = 6;
      } else {
        currentLightMode =
            int.tryParse(dayLightMode.replaceAll('Mode ', '')) ?? 1;
      }

      // Update PWM values for manual mode
      currentParPWM = parDayPWM;
      currentRedPWM = redDayPWM;
      currentBluePWM = blueDayPWM;
      currentUvPWM = uvDayPWM;
      currentIrPWM = irDayPWM;
    } else {
      _tempController.text = nightTemperature.toString();
      _humidityController.text = nightHumidity.toString();
      _co2Controller.text = nightCO2.toString();
      _lightIntensityController.text = nightLightIntensity.toString();

      // Update light mode
      if (nightLightMode == 'Manual') {
        currentLightMode = 6;
      } else {
        currentLightMode =
            int.tryParse(nightLightMode.replaceAll('Mode ', '')) ?? 1;
      }

      // Update PWM values for manual mode
      currentParPWM = parNightPWM;
      currentRedPWM = redNightPWM;
      currentBluePWM = blueNightPWM;
      currentUvPWM = uvNightPWM;
      currentIrPWM = irNightPWM;
    }
  }

  // Helper to get the current mode description
  String get currentModeDescription {
    if (currentLightMode >= 1 && currentLightMode <= 5) {
      return modeDescriptions[currentLightMode - 1];
    } else if (currentLightMode == 6) {
      return 'Manual';
    } else {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header with navigation icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HoverCircleIcon(iconData: Icons.settings),
                        Image.asset(
                          'assets/smartfarm_logo.png',
                          height: 58,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported),
                        ),
                        HoverCircleIcon(iconData: Icons.notifications_none),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Page Title
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Setpoint',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Day/Night Selection
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedPeriod = 'day';
                                  _updateControllersForPeriod();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      selectedPeriod == 'day'
                                          ? Colors.blue
                                          : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.sunny,
                                      color:
                                          selectedPeriod == 'day'
                                              ? Colors.white
                                              : const Color(0xFFFFA726),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Day',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            selectedPeriod == 'day'
                                                ? Colors.white
                                                : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedPeriod = 'night';
                                  _updateControllersForPeriod();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      selectedPeriod == 'night'
                                          ? Colors.blue
                                          : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.dark_mode,
                                      color:
                                          selectedPeriod == 'night'
                                              ? Colors.white
                                              : const Color(0xFF90A4AE),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Night',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            selectedPeriod == 'night'
                                                ? Colors.white
                                                : Colors.grey[700],
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
                    const SizedBox(height: 30),

                    // Temperature Section
                    _buildParameterSection(
                      icon: Icons.thermostat,
                      title: 'Temperature',
                      unit: '°C',
                      controller: _tempController,
                      iconColor: Colors.red,
                    ),

                    // Humidity Section
                    _buildParameterSection(
                      icon: Icons.water_drop_outlined,
                      title: 'Humidity',
                      unit: '%',
                      controller: _humidityController,
                      iconColor: Colors.blue,
                    ),

                    // CO₂ Section
                    _buildParameterSection(
                      icon: Icons.cloud_outlined,
                      title: 'CO₂',
                      unit: 'ppm',
                      controller: _co2Controller,
                      iconColor: Colors.green,
                    ),

                    // Light Section
                    _buildLightSection(),

                    // Submit Button
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: isSubmitting ? null : _submitSetpoints,
                        child:
                            isSubmitting
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.send, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      "Submit Setpoints",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParameterSection({
    required IconData icon,
    required String title,
    required String unit,
    required TextEditingController controller,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '$title ($unit)',
              labelStyle: const TextStyle(color: Colors.black54),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightSection() {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.light_mode_outlined, color: Colors.amber, size: 24),
              SizedBox(width: 12),
              Text(
                'Light',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Light Mode Dropdown
          DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              isExpanded: true,
              // alignment: AlignmentDirectional.centerStart, // This was tried
              buttonStyleData: ButtonStyleData(
                padding: const EdgeInsets.only(
                  left: 0,
                  right: 8,
                ), // This padding is still active
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.transparent,
                  border: Border.all(color: Colors.blue, width: 2),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              iconStyleData: const IconStyleData(
                icon: Icon(Icons.arrow_drop_down_rounded),
                iconSize: 25,
                openMenuIcon: Icon(Icons.arrow_drop_up_rounded),
                iconEnabledColor: Colors.blue,
              ),
              value: currentModeDescription,
              // Add selectedItemBuilder here
              selectedItemBuilder: (BuildContext context) {
                // Assuming 'modeDescriptions' is the List<String> that backs your dropdown items
                return modeDescriptions.map((String item) {
                  return Align(
                    alignment:
                        AlignmentDirectional
                            .centerStart, // Aligns the Text widget to the start
                    child: Text(
                      item,
                      overflow:
                          TextOverflow.ellipsis, // Handles long text gracefully
                      // You can also specify a TextStyle if needed:
                      // style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  );
                }).toList();
              },
              onChanged: (String? newValue) {
                if (newValue == null) return;

                setState(() {
                  if (newValue.startsWith('Mode ')) {
                    final modeNumberString =
                        newValue.split(':')[0].split(' ')[1];
                    currentLightMode =
                        int.tryParse(modeNumberString) ?? currentLightMode;
                  } else if (newValue == 'Manual') {
                    currentLightMode = 6;
                  }
                });
              },
              items:
                  modeDescriptions.map<DropdownMenuItem<String>>((String mode) {
                    return DropdownMenuItem<String>(
                      value: mode,
                      // This child is for the items in the dropdown menu itself
                      child: Text(mode),
                    );
                  }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Light Intensity for Mode 1-4
          if (currentLightMode != 5 && currentLightMode != 6) ...[
            TextField(
              controller: _lightIntensityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Light Intensity (LUX)',
                labelStyle: const TextStyle(color: Colors.black54),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
          ],

          // Manual PWM Sliders for Mode 6
          if (currentLightMode == 6) ...[
            const SizedBox(height: 5),
            const Center(
              child: Text(
                'Manual Light Control',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            _buildSlider(
              'PAR Light',
              currentParPWM,
              (newValue) => currentParPWM = newValue,
              activeTrackColor: const Color(0xFFFFA726),
              outlineColor: const Color(0xFFFFA726),
            ),
            _buildSlider(
              'Red Light',
              currentRedPWM,
              (newValue) => currentRedPWM = newValue,
              activeTrackColor: const Color(0xFFE53935),
              outlineColor: const Color(0xFFE53935),
            ),
            _buildSlider(
              'Blue Light',
              currentBluePWM,
              (newValue) => currentBluePWM = newValue,
              activeTrackColor: const Color(0xFF42A5F5),
              outlineColor: const Color(0xFF42A5F5),
            ),
            _buildSlider(
              'UV Light',
              currentUvPWM,
              (newValue) => currentUvPWM = newValue,
              activeTrackColor: const Color(0xFF7E57C2),
              outlineColor: const Color(0xFF7E57C2),
            ),
            _buildSlider(
              'IR Light',
              currentIrPWM,
              (newValue) => currentIrPWM = newValue,
              activeTrackColor: const Color(0xFFFF8A80),
              outlineColor: const Color(0xFFFF8A80),
              showDivider: false,
            ),
          ],

          // Mode 5 indicator
          if (currentLightMode == 5) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Text(
                'Lights Off',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    ValueChanged<double> onChanged, {
    bool showDivider = true,
    Color activeTrackColor = Colors.blue,
    Color outlineColor = Colors.blue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: activeTrackColor,
            inactiveTrackColor: activeTrackColor.withAlpha((0.3 * 255).toInt()),
            trackHeight: 15.0,
            thumbColor: Colors.white,
            overlayColor: activeTrackColor.withAlpha((0.2 * 255).toInt()),
            thumbShape: CustomThumbShape(
              outlineColor: outlineColor,
              outlineWidth: 2.0,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
            valueIndicatorColor: activeTrackColor,
            valueIndicatorTextStyle: const TextStyle(color: Colors.white),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 100,
            label: '${value.toStringAsFixed(0)}%',
            onChanged: (double newValue) {
              setState(() {
                onChanged(newValue);
              });
            },
          ),
        ),
        if (showDivider) const SizedBox(height: 8),
      ],
    );
  }

  void _submitSetpoints() async {
    // Check authentication first
    if (!await SetpointService.isAuthenticated()) {
      _showErrorDialog('Authentication required. Please login again.');
      return;
    }

    // Validate input fields
    if (_tempController.text.isEmpty ||
        _humidityController.text.isEmpty ||
        _co2Controller.text.isEmpty ||
        (currentLightMode != 5 &&
            currentLightMode != 6 &&
            _lightIntensityController.text.isEmpty)) {
      _showErrorDialog('Please fill in all required fields.');
      return;
    }

    // Parse values
    final double? newTemp = double.tryParse(_tempController.text);
    final double? newHumidity = double.tryParse(_humidityController.text);
    final double? newCO2 = double.tryParse(_co2Controller.text);
    final double? newLightIntensity =
        currentLightMode != 5 && currentLightMode != 6
            ? double.tryParse(_lightIntensityController.text)
            : (currentLightMode == 5 ? 0 : null);

    if (newTemp == null ||
        newHumidity == null ||
        newCO2 == null ||
        (currentLightMode != 6 && newLightIntensity == null)) {
      _showErrorDialog('Please enter valid numeric values.');
      return;
    }

    // Validate setpoints against limits
    Map<String, double>? pwmValues;
    if (currentLightMode == 6) {
      pwmValues = {
        'par': currentParPWM,
        'red': currentRedPWM,
        'blue': currentBluePWM,
        'uv': currentUvPWM,
        'ir': currentIrPWM,
      };
    }

    if (!SetpointService.validateSetpoints(
      temperature: newTemp,
      humidity: newHumidity,
      co2: newCO2,
      lightMode: currentLightMode,
      lightPWM: pwmValues,
    )) {
      _showErrorDialog('Setpoint values are outside acceptable limits.');
      return;
    }

    // Start submission process
    setState(() {
      isSubmitting = true;
    });

    try {
      bool success = false;

      if (selectedPeriod == 'day') {
        success = await SetpointService.sendDaySetpoints(
          deviceId: deviceId,
          temperature: newTemp,
          humidity: newHumidity,
          co2: newCO2,
          lightMode: currentLightMode,
          intensity: newLightIntensity,
          lightPWM: pwmValues,
        );
      } else {
        success = await SetpointService.sendNightSetpoints(
          deviceId: deviceId,
          temperature: newTemp,
          humidity: newHumidity,
          co2: newCO2,
          lightMode: currentLightMode,
          intensity: newLightIntensity,
          lightPWM: pwmValues,
        );
      }

      if (success) {
        // Store pending setpoints to apply after gateway confirmation
        _pendingSetpoints = {
          'period': selectedPeriod,
          'temperature': newTemp,
          'humidity': newHumidity,
          'co2': newCO2,
          'lightMode': currentLightMode,
          'lightIntensity': newLightIntensity ?? 0,
          'pwmValues': pwmValues,
        };

        // Just show that the API call was successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '⏳ Setpoints sent to server, waiting for gateway confirmation...',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        _showErrorDialog(
          'Failed to send setpoints to gateway. Please try again.',
        );
      }
    } catch (e) {
      _showErrorDialog('Network error: ${e.toString()}');
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
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
  final _isPressed = false;

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
          color:
              _isPressed
                  ? const Color.fromARGB(255, 109, 109, 109)
                  : Colors.transparent,
        ),
        child: Icon(
          widget.iconData,
          size: 24,
          color:
              _isPressed
                  ? const Color.fromRGBO(255, 255, 255, 1)
                  : const Color.fromARGB(221, 0, 0, 0),
        ),
      ),
    );
  }
}
