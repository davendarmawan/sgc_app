import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import the chart library for graphs
import 'variables.dart'; // Import the variables file containing data arrays and labels
import 'settings.dart';
import 'notifications_loader.dart';

class SpectrumPage extends StatelessWidget {
  const SpectrumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

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
                    // Title centered
                    Align(
                      alignment: Alignment.center,
                      child: const Text(
                        'Spectrometer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Display Expected Spectrum (Graph)
                    _buildGraphSection(
                      'Expected Spectrum',
                      expectedSpectrumValues,
                      wavelength, // Use wavelength for the x-axis labels
                    ),
                    const SizedBox(height: 0),
                    // Display "Spectrometer Image" Title
                    Align(
                      alignment: Alignment.center,
                      child: const Text(
                        'Spectrometer Image',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Display Spectrometer Image with crop focus and rounded corners
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 0),
                      height: screenHeight * 0.3,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Rounded rectangle shape
                        child: Image.asset(
                          'assets/spectrometer_image.png',
                          fit: BoxFit.cover,
                          width:
                              screenWidth, // Make sure the image fills the container
                          height: screenHeight * 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Display Obtained Spectrum (Graph)
                    _buildGraphSection(
                      'Obtained Spectrum',
                      obtainedSpectrumValues,
                      wavelength, // Same wavelength for consistency
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

  // Function to build graphs for Expected and Obtained Spectra
  Widget _buildGraphSection(
    String title,
    List<double> yValues,
    List<double> xLabels,
  ) {
    // Calculate min and max Y with padding for better graph appearance
    final double minY = yValues.reduce((a, b) => a < b ? a : b) - 5;
    final double maxY = yValues.reduce((a, b) => a > b ? a : b) + 5;

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
        const SizedBox(height: 5),
        // Graph container with horizontal scrolling
        Container(
          height: 220, // Adjusted for compact appearance
          padding: const EdgeInsets.all(4), // Reduced padding
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
                  (xLabels.length + 1) *
                  45.0, // Reduced width for tighter spacing
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true), // Show grid lines
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 25,
                        interval:
                            1, // Reduced interval for more frequent X labels
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          // Display the time labels only for the defined data points
                          if (index >= 0 && index < xLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                // Time labels
                                xLabels[index].toString(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize:
                                      10, // Smaller font size for tighter spacing
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
                  minX: 0.0, // Start from the first data point
                  maxX:
                      (xLabels.length - 1)
                          .toDouble(), // End at the last data point
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        yValues.length,
                        (index) => FlSpot(index.toDouble(), yValues[index]),
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
        const SizedBox(height: 15), // Reduced spacing between sections
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
