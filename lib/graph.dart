import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'variables.dart'; // Import the variables.dart file containing data arrays and labels
import 'settings.dart';
import 'notifications_loader.dart';

class GraphPage extends StatelessWidget {
  const GraphPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // Gradient background
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
                    // Top bar with settings, logo, notifications
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
                    // Title
                    Align(
                      alignment: Alignment.center,
                      child: const Text(
                        'Sensor Graphs',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Graph sections for each sensor
                    _buildGraphSection(
                      'Temperature',
                      temperatureValues,
                      xLabels,
                    ),
                    _buildGraphSection('Humidity', humidityValues, xLabels),
                    _buildGraphSection('CO₂ Level', co2Values, xLabels),
                    _buildGraphSection(
                      'Average Light Intensity',
                      lightIntensityValues,
                      xLabels,
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

  Widget _buildGraphSection(
    String title,
    List<double> yValues,
    List<String> xLabels,
  ) {
    // Slice the data to show only the last 10 points
    final int dataLength = yValues.length;
    final int displayLength = dataLength >= 10 ? 10 : dataLength;

    // Get the last 10 data points
    final List<double> lastYValues = yValues.sublist(
      dataLength - displayLength,
    );
    final List<String> lastXLabels = xLabels.sublist(
      dataLength - displayLength,
    );

    // Calculate min and max Y with padding for better graph appearance
    final double minY = lastYValues.reduce((a, b) => a < b ? a : b) - 10;
    final double maxY = lastYValues.reduce((a, b) => a > b ? a : b) + 10;

    return Column(
      children: [
        // Section title
        Align(
          alignment: Alignment.center,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
        ),
        const SizedBox(height: 10),
        // Graph container with horizontal scrolling
        Container(
          height: 250,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(31, 2, 0, 0),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Enable horizontal scroll
            child: SizedBox(
              width:
                  (lastXLabels.length + 1) *
                  80.0, // Add extra space before the graph
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true), // Show grid lines
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          // Display the time labels only for the defined data points
                          if (index > 0 && index < lastXLabels.length - 1) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                // Time labels
                                lastXLabels[index],
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink(); // Empty widget for gaps
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false, // Hide y-axis labels as requested
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false), // Hide border
                  minX: 0, // Start from the first data point
                  maxX:
                      (lastXLabels.length - 1)
                          .toDouble(), // End at the last data point
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        lastYValues.length,
                        (index) => FlSpot(index.toDouble(), lastYValues[index]),
                      ),
                      isCurved: true,
                      color: Colors.blue, // Line color
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(33, 150, 243, 0.3),
                            Color.fromRGBO(33, 150, 243, 0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
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
  final bool _isPressed = false;

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
                  ? const Color.fromARGB(255, 255, 255, 255)
                  : const Color.fromARGB(221, 0, 0, 0),
        ),
      ),
    );
  }
}
