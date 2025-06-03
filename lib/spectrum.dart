import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import the chart library for graphs
import 'dart:async'; // Import for Timer
import 'variables.dart'; // Import the variables file containing data arrays and labels
import 'settings.dart';
import 'notifications_loader.dart';

class SpectrumPage extends StatefulWidget {
  const SpectrumPage({super.key});

  @override
  State<SpectrumPage> createState() => _SpectrumPageState();
}

class _SpectrumPageState extends State<SpectrumPage> {
  bool _isTakingSpectrumReadings = false;
  late ScrollController _scrollController;
  bool _isScrolledToBottom = false;

  // To simulate taking readings
  Timer? _spectrumReadingTimer;

  static const double _bottomPaddingForButton =
      65; // button height + padding + extra space

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    // Call scroll listener once after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollListener();
      }
    });
  }

  void _scrollListener() {
    if (!mounted ||
        !_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) {
      if (_isScrolledToBottom) {
        setState(() {
          _isScrolledToBottom = false;
        });
      }
      return;
    }

    bool isScrollable = _scrollController.position.maxScrollExtent > 0.0;

    if (isScrollable) {
      final isAtBottom =
          _scrollController.position.pixels >=
          (_scrollController.position.maxScrollExtent - 0.5);
      if (isAtBottom != _isScrolledToBottom) {
        setState(() {
          _isScrolledToBottom = isAtBottom;
        });
      }
    } else {
      // If not scrollable, consider it as "scrolled to bottom" for button width
      if (!_isScrolledToBottom) {
        setState(() {
          _isScrolledToBottom = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _spectrumReadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _takeSpectrumReadings() async {
    if (!mounted) return;
    setState(() {
      _isTakingSpectrumReadings = true;
    });

    // Simulate an async operation
    _spectrumReadingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✔️ Successfully took new spectrum readings!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          _isTakingSpectrumReadings = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double horizontalPadding = screenWidth * 0.04;

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
            child: Stack(
              // Stack to overlay button on content
              children: [
                Padding(
                  // Main content padding
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
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
                        const Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Spectrometer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Color(0xFF1A202C),
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
                        const Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Spectrometer Image',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 18,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Display Spectrometer Image
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 0),
                          height: screenHeight * 0.3,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/spectrometer_image.png', // Ensure this asset exists
                              fit: BoxFit.cover,
                              width: screenWidth,
                              height: screenHeight * 0.3,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.broken_image_outlined,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Image unavailable',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
                        const SizedBox(
                          height: _bottomPaddingForButton,
                        ), // Padding for the floating button
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: _isScrolledToBottom ? horizontalPadding : null,
                  right: horizontalPadding,
                  child: Container(
                    width:
                        _isScrolledToBottom
                            ? screenWidth - (horizontalPadding * 2)
                            : null,
                    child: FilledButton.icon(
                      onPressed:
                          _isTakingSpectrumReadings
                              ? null
                              : _takeSpectrumReadings,
                      icon:
                          _isTakingSpectrumReadings
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(
                                Icons.gradient, // Icon for spectrum
                                color: Colors.white,
                                size: 18,
                              ),
                      label: Text(
                        _isTakingSpectrumReadings
                            ? 'Reading...'
                            : 'Take Spectrum',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                        disabledBackgroundColor: Colors.blue.withOpacity(0.7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 4.0,
                        minimumSize:
                            _isScrolledToBottom
                                ? const Size(
                                  double.infinity,
                                  0,
                                ) // Full width when scrolled to bottom
                                : null, // Default width otherwise
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGraphSection(
    String title,
    List<double> yValues,
    List<double> xLabels,
  ) {
    final double minY =
        yValues.isEmpty ? 0 : yValues.reduce((a, b) => a < b ? a : b) - 5;
    final double maxY =
        yValues.isEmpty ? 10 : yValues.reduce((a, b) => a > b ? a : b) + 5;

    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 18,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 220,
          padding: const EdgeInsets.all(4),
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
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: (xLabels.length + 1) * 45.0,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 25,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < xLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                xLabels[index].toStringAsFixed(
                                  0,
                                ), // Format wavelength
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0.0,
                  maxX: (xLabels.length - 1).toDouble(),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        yValues.length,
                        (index) => FlSpot(index.toDouble(), yValues[index]),
                      ),
                      isCurved: true,
                      color: Colors.blue,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color.fromRGBO(33, 150, 243, 0.3),
                            const Color.fromRGBO(33, 150, 243, 0.1),
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
        SizedBox(height: 20),
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
  // _isPressed state was unused, it's removed for cleanliness as InkWell handles visual feedback.
  // If custom press effects beyond InkWell are needed, it can be re-added.

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
      borderRadius: BorderRadius.circular(50), // For circular splash effect
      splashColor: const Color.fromRGBO(0, 123, 255, 0.2),
      highlightColor: const Color.fromRGBO(0, 123, 255, 0.1),
      child: Padding(
        // Use Padding instead of AnimatedContainer if no animation on _isPressed
        padding: const EdgeInsets.all(8),
        child: Icon(
          widget.iconData,
          size: 24,
          color: const Color.fromARGB(221, 0, 0, 0), // Default color
        ),
      ),
    );
  }
}
