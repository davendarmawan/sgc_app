import 'package:flutter/material.dart';
import 'variables.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // Gradient background (blue gradient for all pages)
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
              child: Column(
                children: [
                  // Upper shield: Settings icon, Logo, Notifications
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
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(
                          getIcon().iconData,
                          size: 30,
                          color: getIcon().iconColor,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Good ${getGreeting()}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 0),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Welcome Home!',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(
                              vertical: screenWidth * 0.04,
                            ),
                            height: screenHeight * 0.25,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                              image: const DecorationImage(
                                image: AssetImage('assets/plant_preview.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Camera Preview',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: screenWidth * 0.03,
                            mainAxisSpacing: screenHeight * 0.02,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: screenWidth * 3 / screenHeight,
                            children: [
                              SensorCard(
                                title: 'Temperature',
                                value: temperature,
                                unit: '°C',
                                setpoint: getSetpoint('temperature'),
                                icon: Icons.thermostat,
                                iconColor: Colors.redAccent,
                              ),
                              SensorCard(
                                title: 'Humidity',
                                value: humidity,
                                unit: '%',
                                setpoint: getSetpoint('humidity'),
                                icon: Icons.water_drop,
                                iconColor: Colors.blueAccent,
                              ),
                              SensorCard(
                                title: 'CO₂',
                                value: co2,
                                unit: 'ppm',
                                setpoint: getSetpoint('co2'),
                                icon: Icons.cloud,
                                iconColor: Colors.green,
                              ),
                              SensorCard(
                                title: 'Light',
                                value: lightIntensity,
                                unit: 'LUX',
                                setpoint: getSetpoint('light'),
                                icon: Icons.wb_sunny,
                                iconColor: Colors.orangeAccent,
                                extraInfo: getMode('light'),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.01),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String getGreeting() {
    final int hour = DateTime.now().hour;
    return hour >= 5 && hour < 12
        ? "Morning,"
        : hour >= 12 && hour < 18
        ? "Afternoon,"
        : "Night,";
  }

  // Updated getIcon method with color changes
  IconDataAndColor getIcon() {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 18) {
      return IconDataAndColor(
        iconData: Icons.wb_sunny,
        iconColor: const Color.fromARGB(255, 255, 162, 0),
      );
    } else {
      return IconDataAndColor(
        iconData: Icons.nights_stay,
        iconColor: const Color.fromARGB(255, 83, 83, 83),
      );
    }
  }

  // Method to get the correct setpoint based on the time of day
  String getSetpoint(String sensor) {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 18) {
      // Daytime values
      switch (sensor) {
        case 'temperature':
          return '${dayTemperature.toString()} °C';
        case 'humidity':
          return '${dayHumidity.toString()} %';
        case 'co2':
          return '${dayCO2.toString()} ppm';
        case 'light':
          if (dayLightMode == 'Manual') {
            return 'Custom';
          } else {
            return '${dayLightIntensity.toString()} LUX';
          }
        default:
          return '0';
      }
    } else {
      // Nighttime values
      switch (sensor) {
        case 'temperature':
          return '${dayTemperature.toString()} °C';
        case 'humidity':
          return '${dayHumidity.toString()} %';
        case 'co2':
          return '${dayCO2.toString()} ppm';
        case 'light':
          if (nightLightMode == 'Manual') {
            return 'Custom';
          } else {
            return '${nightLightIntensity.toString()} LUX';
          }
        default:
          return '0';
      }
    }
  }

  // Method to get the correct mode based on the time of day
  String getMode(String sensor) {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 18) {
      // Daytime mode
      if (sensor == 'light') {
        return dayLightMode; // Return the day mode
      }
    } else {
      // Nighttime mode
      if (sensor == 'light') {
        return nightLightMode; // Return the night mode
      }
    }
    return '';
  }
}

// Public class to hold icon and its color
class IconDataAndColor {
  final IconData iconData;
  final Color iconColor;

  IconDataAndColor({required this.iconData, required this.iconColor});
}

class HoverCircleIcon extends StatefulWidget {
  final IconData iconData;

  const HoverCircleIcon({required this.iconData, super.key});

  @override
  State<HoverCircleIcon> createState() => _HoverCircleIconState();
}

class _HoverCircleIconState extends State<HoverCircleIcon> {
  final bool _isPressed = false;

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
                  ? const Color.fromARGB(255, 255, 255, 255)
                  : const Color.fromARGB(221, 0, 0, 0),
        ),
      ),
    );
  }
}

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String setpoint;
  final IconData icon;
  final Color iconColor;
  final String? extraInfo;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.setpoint,
    required this.icon,
    required this.iconColor,
    this.extraInfo,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double valueFontSize = screenWidth > 400 ? 36 : 32;
    final double unitFontSize = screenWidth > 400 ? 18 : 16;
    final double setpointFontSize = screenWidth > 400 ? 14 : 12;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 25),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (extraInfo != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    extraInfo!,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: unitFontSize,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Setpoint: $setpoint',
            style: TextStyle(fontSize: setpointFontSize, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
