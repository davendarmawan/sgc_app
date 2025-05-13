import 'package:flutter/material.dart';
import 'variables.dart'; // Import the variables file

class SetpointPage extends StatefulWidget {
  const SetpointPage({super.key});

  @override
  SetpointPageState createState() => SetpointPageState();
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

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values from variables.dart
    _dayTempController.text = dayTemperature.toString();
    _nightTempController.text = nightTemperature.toString();
    _dayHumidityController.text =
        dayHumidity.toString(); // Using day humidity for the controller
    _nightHumidityController.text =
        nightHumidity.toString(); // Using night humidity for the controller
    _dayCO2Controller.text =
        dayCO2.toString(); // Using day CO2 for the controller
    _nightCO2Controller.text =
        nightCO2.toString(); // Using night CO2 for the controller
  }

  @override
  void dispose() {
    _dayTempController.dispose();
    _nightTempController.dispose();
    _dayHumidityController.dispose();
    _nightHumidityController.dispose();
    _dayCO2Controller.dispose();
    _nightCO2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

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
                          height: screenHeight * 0.07,
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
                              Icons.nightlight,
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
                    if (selectedParameter == 'Humidity') ...[
                      Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildParameterCard(
                              Icons.sunny,
                              'Day Setpoint',
                              '${dayHumidity.toStringAsFixed(1)} %',
                            ),
                            const SizedBox(width: 10),
                            _buildParameterCard(
                              Icons.nightlight,
                              'Night Setpoint',
                              '${nightHumidity.toStringAsFixed(1)} %',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(thickness: 1),
                      const SizedBox(height: 10),
                      const Text(
                        'Humidity Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSetpointInputField(
                        'Day Humidity (%)',
                        _dayHumidityController,
                      ),
                      _buildSetpointInputField(
                        'Night Humidity (%)',
                        _nightHumidityController,
                      ),
                    ],
                    if (selectedParameter == 'CO₂') ...[
                      Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildParameterCard(
                              Icons.sunny,
                              'Day Setpoint',
                              '${dayCO2.toStringAsFixed(1)} ppm',
                            ),
                            const SizedBox(width: 10),
                            _buildParameterCard(
                              Icons.nightlight,
                              'Night Setpoint',
                              '${nightCO2.toStringAsFixed(1)} ppm',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(thickness: 1),
                      const SizedBox(height: 10),
                      const Text(
                        'CO₂ Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSetpointInputField(
                        'Day CO₂ (ppm)',
                        _dayCO2Controller,
                      ),
                      _buildSetpointInputField(
                        'Night CO₂ (ppm)',
                        _nightCO2Controller,
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedParameter == 'Temperature') {
                          _saveTemperatureSetpoints();
                        } else if (selectedParameter == 'Humidity') {
                          _saveHumiditySetpoints();
                        } else if (selectedParameter == 'CO₂') {
                          _saveCO2Setpoints();
                        }
                      },
                      child: const Text("Save Setpoints"),
                    ),
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
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildParameterCard(IconData icon, String label, String value) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      width: screenWidth * 0.4, // Same width for both cards
      height: screenHeight * 0.15, // Same height for both cards
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
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
                  fontSize: 20,
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
    final double? newDayCO2 = double.tryParse(_dayCO2Controller.text);
    final double? newNightCO2 = double.tryParse(_nightCO2Controller.text);

    if (newDayCO2 == null || newNightCO2 == null) {
      _showErrorDialog('Please enter valid numeric values for CO2 levels.');
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
      onTap: () {},
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
