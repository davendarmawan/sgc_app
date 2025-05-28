import 'package:flutter/material.dart';
import 'variables.dart'; // Import the variables file
import 'package:dropdown_button2/dropdown_button2.dart';
import 'settings.dart';
import 'notifications_loader.dart';

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
  String selectedParameter = 'Temperature';

  final Map<String, IconData> parameterIcons = {
    'Temperature': Icons.thermostat,
    'Humidity': Icons.water_drop_outlined,
    'CO₂': Icons.cloud_outlined,
    'Light': Icons.light_mode_outlined,
  };

  // Controllers for input fields to capture new setpoints
  final TextEditingController _dayTempController = TextEditingController();
  final TextEditingController _nightTempController = TextEditingController();
  final TextEditingController _dayHumidityController = TextEditingController();
  final TextEditingController _nightHumidityController =
      TextEditingController();
  final TextEditingController _dayCO2Controller = TextEditingController();
  final TextEditingController _nightCO2Controller = TextEditingController();

  // Light settings controllers
  final TextEditingController _dayLightIntensityController =
      TextEditingController();
  final TextEditingController _nightLightIntensityController =
      TextEditingController();

  int lightModeDay = 1; // Default light mode
  int lightModeNight = 1; // Default light mode

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values from variables.dart
    _dayTempController.text = dayTemperature.toString();
    _nightTempController.text = nightTemperature.toString();
    _dayHumidityController.text = dayHumidity.toString();
    _nightHumidityController.text = nightHumidity.toString();
    _dayCO2Controller.text = dayCO2.toString();
    _nightCO2Controller.text = nightCO2.toString();
    _dayLightIntensityController.text = dayLightIntensity.toString();
    _nightLightIntensityController.text = nightLightIntensity.toString();
  }

  @override
  void dispose() {
    _dayTempController.dispose();
    _nightTempController.dispose();
    _dayHumidityController.dispose();
    _nightHumidityController.dispose();
    _dayCO2Controller.dispose();
    _nightCO2Controller.dispose();
    _dayLightIntensityController.dispose();
    _nightLightIntensityController.dispose();

    super.dispose();
  }

  // Helper to get the current mode description string based on lightMode integer
  String get currentDayModeDescription {
    if (lightModeDay >= 1 && lightModeDay <= 5) {
      return modeDescriptions[lightModeDay - 1];
    } else if (lightModeDay == 6) {
      return 'Manual';
    } else {
      return 'Unknown';
    }
  }

  // Helper to get the current mode description string based on lightMode integer
  String get currentNightModeDescription {
    if (lightModeNight >= 1 && lightModeNight <= 5) {
      return modeDescriptions[lightModeNight - 1];
    } else if (lightModeNight == 6) {
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
                    Align(
                      alignment: Alignment.center,
                      child: const Text(
                        'Setpoint',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children:
                          parameterIcons.keys.map((parameter) {
                            final bool isSelected =
                                selectedParameter == parameter;
                            return Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedParameter = parameter;
                                      // Reset controllers when switching tabs
                                      if (parameter == 'Temperature') {
                                        _dayTempController.text =
                                            dayTemperature.toString();
                                        _nightTempController.text =
                                            nightTemperature.toString();
                                      } else if (parameter == 'Humidity') {
                                        _dayHumidityController.text =
                                            dayHumidity.toString();
                                        _nightHumidityController.text =
                                            nightHumidity.toString();
                                      } else if (parameter == 'CO₂') {
                                        _dayCO2Controller.text =
                                            dayCO2.toString();
                                        _nightCO2Controller.text =
                                            nightCO2.toString();
                                      }
                                    });
                                  },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        parameterIcons[parameter],
                                        size: 32,
                                        color:
                                            isSelected
                                                ? Colors.blue
                                                : Colors.grey,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        parameter,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              isSelected
                                                  ? Colors.blue
                                                  : Colors.grey,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Show parameter setpoints with current values and input fields
                    if (selectedParameter == 'Temperature') ...[
                      Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildParameterCard(
                              Icons.sunny,
                              'Day Setpoint',
                              '${dayTemperature.toStringAsFixed(1)} °C',
                            ),
                            const SizedBox(width: 10),
                            _buildParameterCard(
                              Icons.dark_mode,
                              'Night Setpoint',
                              '${nightTemperature.toStringAsFixed(1)} °C',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(thickness: 1),
                      const SizedBox(height: 10),
                      const Text(
                        'Temperature Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSetpointInputField(
                        'Day Temperature (°C)',
                        _dayTempController,
                      ),
                      _buildSetpointInputField(
                        'Night Temperature (°C)',
                        _nightTempController,
                      ),
                    ],

                    // Humidity and CO₂ settings
                    if (selectedParameter == 'Humidity') ...[
                      _buildHumidityCO2Section(
                        'Humidity',
                        _dayHumidityController,
                        _nightHumidityController,
                      ),
                    ],

                    if (selectedParameter == 'CO₂') ...[
                      _buildHumidityCO2Section(
                        'CO₂',
                        _dayCO2Controller,
                        _nightCO2Controller,
                      ),
                    ],

                    if (selectedParameter == 'Light') ...[
                      Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLightCard(
                              Icons.sunny,
                              'Day Setpoint',
                              dayLightMode,
                              '${dayLightIntensity.toStringAsFixed(1)} LUX',
                            ),
                            const SizedBox(width: 10),
                            _buildLightCard(
                              Icons.dark_mode,
                              'Night Setpoint',
                              nightLightMode,
                              '${nightLightIntensity.toStringAsFixed(1)} LUX',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(thickness: 1),
                      const SizedBox(height: 10),
                      const Text(
                        'Day Light Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Dropdown for Light Mode selection
                      DropdownButtonHideUnderline(
                        child: DropdownButton2<String>(
                          buttonStyleData: ButtonStyleData(
                            width: screenWidth,
                            padding: const EdgeInsets.only(left: 20, right: 20),
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
                            iconSize: 30,
                            openMenuIcon: Icon(Icons.arrow_drop_up_rounded),
                            iconEnabledColor: Colors.blue,
                          ),
                          value: currentDayModeDescription,
                          onChanged: (String? newValue) {
                            if (newValue == null) return;

                            setState(() {
                              if (newValue.startsWith('Mode ')) {
                                final modeNumberString =
                                    newValue.split(':')[0].split(' ')[1];
                                lightModeDay =
                                    int.tryParse(modeNumberString) ??
                                    lightModeDay;
                              } else if (newValue == 'Manual') {
                                lightModeDay = 6;
                              }
                            });
                          },
                          items:
                              modeDescriptions.map<DropdownMenuItem<String>>((
                                String mode,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: mode,
                                  child: Text(mode),
                                );
                              }).toList(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Show light intensity for Mode 1-4 only
                      if (lightModeDay != 5 && lightModeDay != 6) ...[
                        _buildSetpointInputField(
                          'Day Light Intensity (LUX)',
                          _dayLightIntensityController,
                        ),
                      ],

                      // Show sliders for Manual Mode inside one white container
                      if (lightModeDay == 6) ...[
                        const SizedBox(height: 10),
                        _buildSlidersGroup([
                          _buildSlider(
                            'PAR Light',
                            parDayPWM,
                            (newValue) {
                              parDayPWM = newValue;
                            },
                            activeTrackColor: const Color(
                              0xFFFFA726,
                            ), // Soothing Orange
                            outlineColor: const Color(0xFFFFA726),
                          ),
                          _buildSlider(
                            'Red Light',
                            redDayPWM,
                            (newValue) {
                              redDayPWM = newValue;
                            },
                            activeTrackColor: const Color(
                              0xFFE53935,
                            ), // Soothing Red
                            outlineColor: const Color(0xFFE53935),
                          ),
                          _buildSlider(
                            'Blue Light',
                            blueDayPWM,
                            (newValue) {
                              blueDayPWM = newValue;
                            },
                            activeTrackColor: const Color(
                              0xFF42A5F5,
                            ), // Blue (keep)
                            outlineColor: const Color(0xFF42A5F5),
                          ),
                          _buildSlider(
                            'UV Light',
                            uvDayPWM,
                            (newValue) {
                              uvDayPWM = newValue;
                            },
                            activeTrackColor: const Color(
                              0xFF7E57C2,
                            ), // Soothing Violet
                            outlineColor: const Color(0xFF7E57C2),
                          ),
                          _buildSlider(
                            'IR Light',
                            irDayPWM,
                            (newValue) {
                              irDayPWM = newValue;
                            },
                            activeTrackColor: const Color(
                              0xFFFF8A80,
                            ), // Light Red
                            outlineColor: const Color(0xFFFF8A80),
                            showDivider: false,
                          ),
                        ]),
                      ],

                      const SizedBox(height: 10),

                      const Divider(thickness: 1),
                      const SizedBox(height: 10),
                      const Text(
                        'Night Light Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),

                      const SizedBox(height: 10),
                      // Dropdown for Light Mode selection
                      DropdownButtonHideUnderline(
                        child: DropdownButton2<String>(
                          buttonStyleData: ButtonStyleData(
                            width: screenWidth,
                            padding: const EdgeInsets.only(left: 20, right: 20),
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
                            iconSize: 30,
                            openMenuIcon: Icon(Icons.arrow_drop_up_rounded),
                            iconEnabledColor: Colors.blue,
                          ),
                          value: currentNightModeDescription,
                          onChanged: (String? newValue) {
                            if (newValue == null) return;

                            setState(() {
                              if (newValue.startsWith('Mode ')) {
                                final modeNumberString =
                                    newValue.split(':')[0].split(' ')[1];
                                lightModeNight =
                                    int.tryParse(modeNumberString) ??
                                    lightModeNight;
                              } else if (newValue == 'Manual') {
                                lightModeNight = 6;
                              }
                            });
                          },
                          items:
                              modeDescriptions.map<DropdownMenuItem<String>>((
                                String mode,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: mode,
                                  child: Text(mode),
                                );
                              }).toList(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Show light intensity for Mode 1-4 only
                      if (lightModeNight != 5 && lightModeNight != 6) ...[
                        _buildSetpointInputField(
                          'Night Light Intensity (LUX)',
                          _nightLightIntensityController,
                        ),
                      ],

                      // Show sliders for Manual Mode inside one white container
                      if (lightModeNight == 6) ...[
                        const SizedBox(height: 10),
                        _buildSlidersGroup([
                          _buildSlider(
                            'PAR Light',
                            parNightPWM,
                            (newValue) {
                              parNightPWM = newValue;
                            },
                            activeTrackColor: const Color(
                              0xFFFFA726,
                            ), // Soothing Orange
                            outlineColor: const Color(0xFFFFA726),
                          ),
                          _buildSlider(
                            'Red Light',
                            redNightPWM,
                            (newValue) {
                              redNightPWM = newValue;
                            },
                            activeTrackColor: const Color(
                              0xFFE53935,
                            ), // Soothing Red
                            outlineColor: const Color(0xFFE53935),
                          ),
                          _buildSlider(
                            'Blue Light',
                            blueNightPWM,
                            (newValue) {
                              blueNightPWM = newValue;
                            },
                            activeTrackColor: const Color(
                              0xFF42A5F5,
                            ), // Blue (keep)
                            outlineColor: const Color(0xFF42A5F5),
                          ),
                          _buildSlider(
                            'UV Light',
                            uvNightPWM,
                            (newValue) {
                              uvNightPWM = newValue;
                            },
                            activeTrackColor: const Color(
                              0xFF7E57C2,
                            ), // Soothing Violet
                            outlineColor: const Color(0xFF7E57C2),
                          ),
                          _buildSlider(
                            'IR Light',
                            irNightPWM,
                            (newValue) {
                              irNightPWM = newValue;
                            },
                            activeTrackColor: const Color(
                              0xFFFF8A80,
                            ), // Light Red
                            outlineColor: const Color(0xFFFF8A80),
                            showDivider: false,
                          ),
                        ]),
                      ],
                      const SizedBox(height: 15),
                    ],

                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (selectedParameter == 'Temperature') {
                            _saveTemperatureSetpoints();
                          } else if (selectedParameter == 'Humidity') {
                            _saveHumiditySetpoints();
                          } else if (selectedParameter == 'CO₂') {
                            _saveCO2Setpoints();
                          } else if (selectedParameter == 'Light') {
                            _saveLightSetpoints();
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.save_as, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Save Setpoints",
                              style: TextStyle(
                                fontSize: 15,
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

  Widget _buildSetpointInputField(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
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
    );
  }

  Widget _buildSlidersGroup(List<Widget> sliders) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth, // Use full available width
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white, // White background behind all sliders
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: sliders),
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: Colors.black)),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: activeTrackColor,
                inactiveTrackColor: activeTrackColor.withAlpha(
                  (0.3 * 255).toInt(),
                ),
                trackHeight: 15.0,
                thumbColor: Colors.white,
                overlayColor: activeTrackColor.withAlpha((0.2 * 255).toInt()),
                thumbShape: CustomThumbShape(
                  outlineColor: outlineColor,
                  outlineWidth: 2.0,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 24.0,
                ),
                valueIndicatorColor: activeTrackColor,
                valueIndicatorTextStyle: const TextStyle(color: Colors.white),
              ),
              child: SizedBox(
                width: constraints.maxWidth,
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
            ),
            if (showDivider)
              const Divider(thickness: 1, height: 20, color: Colors.grey),
          ],
        );
      },
    );
  }

  Widget _buildParameterCard(IconData icon, String label, String value) {
    Color iconColor;
    if (icon == Icons.sunny) {
      iconColor = const Color(0xFFFFA726); // Orange
    } else if (icon == Icons.dark_mode) {
      iconColor = const Color(0xFF90A4AE); // Moon color (soft blue-gray)
    } else {
      iconColor = Colors.blue;
    }

    return SizedBox(
      width: 160, // Same width for both cards
      height: 160, // Same height for both cards
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: iconColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLightCard(
    IconData icon,
    String label,
    String mode,
    String value,
  ) {
    Color iconColor;
    if (icon == Icons.sunny) {
      iconColor = const Color(0xFFFFA726); // Orange
    } else if (icon == Icons.dark_mode) {
      iconColor = const Color(0xFF90A4AE); // Moon color (soft blue-gray)
    } else {
      iconColor = Colors.blue;
    }

    return SizedBox(
      width: 160, // Same width for both cards
      height: 160, // Same height for both cards
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: iconColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Container for Mode
              Container(
                margin: const EdgeInsets.all(3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mode,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),

              // SizedBox for Setpoint
              const SizedBox(height: 4),
              Text(
                mode == "Mode 5"
                    ? 'Lights Off'
                    : mode == 'Manual'
                    ? 'Custom'
                    : value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveTemperatureSetpoints() {
    if (_dayTempController.text.isEmpty || _nightTempController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all temperature fields.')),
      );
      return;
    }

    final double? newDayTemp = double.tryParse(_dayTempController.text);
    final double? newNightTemp = double.tryParse(_nightTempController.text);

    if (newDayTemp == null || newNightTemp == null) {
      _showErrorDialog('Please enter valid numeric values for temperatures.');
      return;
    }

    setState(() {
      dayTemperature = newDayTemp;
      nightTemperature = newNightTemp;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Temperature setpoints updated successfully!'),
      ),
    );
  }

  void _saveHumiditySetpoints() {
    if (_dayHumidityController.text.isEmpty ||
        _nightHumidityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all humidity fields.')),
      );
      return;
    }

    final double? newDayHumidity = double.tryParse(_dayHumidityController.text);
    final double? newNightHumidity = double.tryParse(
      _nightHumidityController.text,
    );

    if (newDayHumidity == null || newNightHumidity == null) {
      _showErrorDialog('Please enter valid numeric values for humidity.');
      return;
    }

    setState(() {
      dayHumidity = newDayHumidity;
      nightHumidity = newNightHumidity;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Humidity setpoints updated successfully!')),
    );
  }

  void _saveCO2Setpoints() {
    if (_dayCO2Controller.text.isEmpty || _nightCO2Controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all CO₂ fields.')),
      );
      return;
    }

    final double? newDayCO2 = double.tryParse(_dayCO2Controller.text);
    final double? newNightCO2 = double.tryParse(_nightCO2Controller.text);

    if (newDayCO2 == null || newNightCO2 == null) {
      _showErrorDialog('Please enter valid numeric values for CO₂ levels.');
      return;
    }

    setState(() {
      dayCO2 = newDayCO2;
      nightCO2 = newNightCO2;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CO₂ setpoints updated successfully!')),
    );
  }

  void _saveLightSetpoints() {
    if ((lightModeDay != 5 &&
            lightModeDay != 6 &&
            _dayLightIntensityController.text.isEmpty) ||
        (lightModeNight != 5 &&
            lightModeNight != 6 &&
            _nightLightIntensityController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all light intensity fields.'),
        ),
      );
      return;
    }

    setState(() {
      if (lightModeDay == 6) {
        dayLightMode = 'Manual';
      } else {
        dayLightMode = 'Mode $lightModeDay'; // Store selected light mode
      }

      if (lightModeNight == 6) {
        nightLightMode = 'Manual';
      } else {
        nightLightMode = 'Mode $lightModeNight'; // Store selected light mode
      }

      // Update Day Light Intensity
      if (lightModeDay != 5 && lightModeDay != 6) {
        // Update Day Intensity for Modes 1-4
        dayLightIntensity = double.tryParse(_dayLightIntensityController.text)!;
      } else if (lightModeDay == 5) {
        // If Mode 5 is selected, all lights are off
        dayLightIntensity = 0;
      }

      // Update Night Light Intensity
      if (lightModeNight != 5 && lightModeNight != 6) {
        // Update Night Intensity for Modes 1-4
        nightLightIntensity =
            double.tryParse(_nightLightIntensityController.text)!;
      } else if (lightModeNight == 5) {
        // If Mode 5 is selected, all lights are off
        nightLightIntensity = 0;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Light setpoints updated successfully!')),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Invalid Input'),
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

  Widget _buildHumidityCO2Section(
    String label,
    TextEditingController dayController,
    TextEditingController nightController,
  ) {
    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildParameterCard(
                Icons.sunny,
                'Day Setpoint',
                '${dayController.text} ${label == 'CO₂' ? 'ppm' : '%'}',
              ),
              const SizedBox(width: 10),
              _buildParameterCard(
                Icons.dark_mode,
                'Night Setpoint',
                '${nightController.text} ${label == 'CO₂' ? 'ppm' : '%'}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Divider(thickness: 1),
        const SizedBox(height: 10),
        Text(
          '$label Settings',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 10),
        _buildSetpointInputField(
          'Day $label (${label == 'CO₂' ? 'ppm' : '%'})',
          dayController,
        ),
        _buildSetpointInputField(
          'Night $label (${label == 'CO₂' ? 'ppm' : '%'})',
          nightController,
        ),
      ],
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
          // Navigate to Settings page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        } else if (widget.iconData == Icons.notifications_none) {
          // Navigate to Notifications page
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
