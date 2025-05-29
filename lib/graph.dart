import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'variables.dart'; // Assuming xLabels is accessible here for initial calculation
import 'settings.dart'; // Assuming this exists
import 'notifications_loader.dart'; // Assuming this exists
import 'dart:math';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  late Map<String, TransformationController> _graphControllers;
  final bool _isPanEnabled = true;
  final bool _isScaleEnabled = true;

  final List<String> _graphTitles = [
    'Temperature',
    'Humidity',
    'CO₂ Level',
    'Average Light Intensity',
  ];

  // State to hold dynamic intervals for each graph's X-axis
  final Map<String, double> _xAxisIntervals = {};

  // Animation controller for smooth graph reset
  AnimationController? _graphResetAnimationController;
  Animation<Matrix4>? _graphResetMatrixAnimation;
  TransformationController? _controllerBeingReset;

  // Configuration for dynamic interval calculation
  // MODIFIED: Further reduced _maxLabelsToShowWhenZoomedOut for more space
  static const int _maxLabelsToShowWhenZoomedOut =
      6; // Target labels when fully zoomed out (was 10, then 7)
  static const double _minScaleForDenseLabels =
      1.0; // Scale at which zoomedOutInterval ideally applies
  // MODIFIED: Further increased _maxScaleForIntervalOne to delay showing all labels
  static const double _maxScaleForIntervalOne =
      5.0; // Scale at or beyond which interval becomes 1.0 (was 2.5, then 4.0)

  @override
  void initState() {
    super.initState();
    _graphControllers = {
      for (var title in _graphTitles) title: TransformationController(),
    };

    // Initialize intervals and add listeners
    for (var title in _graphTitles) {
      _xAxisIntervals[title] = _calculateXAxisInterval(
        currentDataLength:
            xLabels
                .length, // Assuming xLabels is globally accessible and populated
        currentScale: 1.0,
      );
      _graphControllers[title]?.addListener(() {
        if (mounted) {
          setState(() {
            // This setState call is crucial to rebuild and re-evaluate
            // the button's enabled state based on controller.value
          });
        }
        // Assuming xLabels content/length doesn't change after initState for this listener.
        // If xLabels can change dynamically for a specific graph, this might need adjustment.
        _updateXAxisIntervalForGraph(title, xLabels.length);
      });
    }
  }

  double _calculateXAxisInterval({
    required int currentDataLength,
    required double currentScale,
  }) {
    if (currentDataLength == 0) return 1.0;

    // Calculate the interval needed to show around `_maxLabelsToShowWhenZoomedOut` labels
    // when the graph is fully zoomed out (scale = 1.0).
    final double
    zoomedOutInterval =
        (currentDataLength <= _maxLabelsToShowWhenZoomedOut)
            ? 1.0 // If fewer data points than target labels, show all.
            // Otherwise, divide data length by target labels and ceil to get an integer interval.
            : (currentDataLength.toDouble() / _maxLabelsToShowWhenZoomedOut)
                .ceilToDouble();

    double newInterpolatedInterval;

    // Determine interval based on current zoom scale
    if (currentScale <= _minScaleForDenseLabels) {
      // If scale is at minimum (or less), use the calculated zoomedOutInterval.
      newInterpolatedInterval = zoomedOutInterval;
    } else if (currentScale >= _maxScaleForIntervalOne) {
      // If scale is at maximum for dense labels (or more), set interval to 1 (show all labels).
      newInterpolatedInterval = 1.0;
    } else {
      // Interpolate the interval for scales between _minScaleForDenseLabels and _maxScaleForIntervalOne.
      // This creates a smoother transition from sparse to dense labels as the user zooms in.
      final double factor =
          (currentScale - _minScaleForDenseLabels) /
          (_maxScaleForIntervalOne - _minScaleForDenseLabels);
      newInterpolatedInterval =
          zoomedOutInterval - factor * (zoomedOutInterval - 1.0);
    }

    double finalInterval;
    // This condition helps to snap to an interval of 1.0 more decisively
    // once the interpolated interval becomes very small (e.g., <= 1.5),
    // provided that the graph isn't already showing all labels when zoomed out.
    if (newInterpolatedInterval <= 1.5 && zoomedOutInterval > 1.0) {
      finalInterval = 1.0;
    } else {
      // Otherwise, round the interpolated interval to the nearest whole number.
      finalInterval = newInterpolatedInterval.roundToDouble();
    }

    // Ensure the final interval is at least 1.0 (can't be less than showing every point)
    // and not greater than the interval calculated for the fully zoomed-out state.
    return finalInterval.clamp(1.0, zoomedOutInterval);
  }

  void _updateXAxisIntervalForGraph(String graphTitle, int numLabels) {
    if (!mounted || _graphControllers[graphTitle] == null) return;

    final controller = _graphControllers[graphTitle]!;
    // Get the current maximum scale factor from the controller.
    // This represents how much the graph is zoomed in horizontally.
    final scale = controller.value.getMaxScaleOnAxis();

    final double newInterval = _calculateXAxisInterval(
      currentDataLength: numLabels,
      currentScale: scale,
    );

    if (_xAxisIntervals[graphTitle] != newInterval) {
      if (mounted) {
        setState(() {
          _xAxisIntervals[graphTitle] = newInterval;
        });
      }
    }
  }

  @override
  void dispose() {
    _graphResetAnimationController?.dispose();
    for (var title in _graphTitles) {
      // Listeners added with anonymous functions are generally handled by the controller's dispose.
      _graphControllers[title]?.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Reset zoom/pan for all graphs when date changes
        for (var title in _graphTitles) {
          _instantTransformationReset(_graphControllers[title]!);
        }
      });
    }
  }

  void _instantTransformationReset(TransformationController controller) {
    if (!mounted) return;
    setState(() {
      controller.value = Matrix4.identity(); // Reset to no zoom/pan
    });
  }

  void _animateTransformationControllerToIdentity(
    TransformationController controllerToAnimate,
  ) {
    if (!mounted) return;

    _graphResetAnimationController?.stop(); // Stop any ongoing animation
    _graphResetAnimationController?.dispose(); // Dispose old controller

    _controllerBeingReset = controllerToAnimate;
    _graphResetAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500), // Animation duration
      vsync: this, // Required for TickerProviderStateMixin
    );

    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: _graphResetAnimationController!,
      curve: Curves.easeInOutCubic, // Smooth animation curve
    );

    // Animate the matrix from its current state back to identity (no transformation)
    _graphResetMatrixAnimation = Matrix4Tween(
      begin: _controllerBeingReset!.value,
      end: Matrix4.identity(),
    ).animate(curvedAnimation);

    // Listener to update the controller's value during animation
    _graphResetMatrixAnimation!.addListener(() {
      if (mounted && _controllerBeingReset != null) {
        setState(() {
          _controllerBeingReset!.value = _graphResetMatrixAnimation!.value;
        });
      }
    });

    // Listener for animation status (e.g., completion)
    _graphResetAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted && _controllerBeingReset != null) {
          setState(() {
            // Ensure it ends exactly at identity
            _controllerBeingReset!.value = Matrix4.identity();
          });
        }
        // Clean up animation resources
        _graphResetAnimationController?.dispose();
        _graphResetAnimationController = null;
        _graphResetMatrixAnimation = null;
        _controllerBeingReset = null;
      } else if (status == AnimationStatus.dismissed) {
        // Also clean up if dismissed (e.g., stopped early)
        _graphResetAnimationController?.dispose();
        _graphResetAnimationController = null;
        _graphResetMatrixAnimation = null;
        _controllerBeingReset = null;
      }
    });

    _graphResetAnimationController!.forward(from: 0.0); // Start the animation
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final String formattedDate = DateFormat(
      'dd MMM yyyy',
    ).format(_selectedDate);

    return Stack(
      children: [
        // Background gradient
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
          backgroundColor:
              Colors.transparent, // Make scaffold transparent to see gradient
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header row with icons and logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HoverCircleIcon(iconData: Icons.settings),
                        Image.asset(
                          'assets/smartfarm_logo.png',
                          height: 58,
                          errorBuilder: // Fallback for image loading error
                              (context, error, stackTrace) => const Icon(
                                Icons.image_not_supported,
                                size: 58,
                              ),
                        ),
                        HoverCircleIcon(iconData: Icons.notifications_none),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Page Title
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Sensor Graphs',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Date Selector Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(158, 158, 158, 0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2), // Shadow position
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Row(
                            children: [
                              SizedBox(width: 5),
                              Icon(
                                Icons.calendar_today,
                                color: Colors.black87,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Select Date',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () => _selectDate(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF2196F3,
                              ), // Button color
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2, // Button shadow
                            ),
                            child: Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Build graph sections for each metric
                    _buildGraphSection(
                      _graphTitles[0], // Temperature
                      temperatureValues, // Assuming this is globally accessible List<double>
                      xLabels, // Assuming this is globally accessible List<String>
                      _graphControllers[_graphTitles[0]]!,
                      _xAxisIntervals[_graphTitles[0]] ??
                          _calculateXAxisInterval(
                            // Fallback interval calculation
                            currentDataLength: xLabels.length,
                            currentScale: 1.0,
                          ),
                    ),
                    _buildGraphSection(
                      _graphTitles[1], // Humidity
                      humidityValues,
                      xLabels,
                      _graphControllers[_graphTitles[1]]!,
                      _xAxisIntervals[_graphTitles[1]] ??
                          _calculateXAxisInterval(
                            currentDataLength: xLabels.length,
                            currentScale: 1.0,
                          ),
                    ),
                    _buildGraphSection(
                      _graphTitles[2], // CO2 Level
                      co2Values,
                      xLabels,
                      _graphControllers[_graphTitles[2]]!,
                      _xAxisIntervals[_graphTitles[2]] ??
                          _calculateXAxisInterval(
                            currentDataLength: xLabels.length,
                            currentScale: 1.0,
                          ),
                    ),
                    _buildGraphSection(
                      _graphTitles[3], // Average Light Intensity
                      lightIntensityValues,
                      xLabels,
                      _graphControllers[_graphTitles[3]]!,
                      _xAxisIntervals[_graphTitles[3]] ??
                          _calculateXAxisInterval(
                            currentDataLength: xLabels.length,
                            currentScale: 1.0,
                          ),
                    ),
                    const SizedBox(height: 20), // Bottom padding
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
    List<String> currentXLabels, // Passed directly, assuming it's up-to-date
    TransformationController controller,
    double currentXAxisInterval,
  ) {
    // Guard against empty or mismatched data
    if (yValues.isEmpty ||
        currentXLabels.isEmpty ||
        yValues.length != currentXLabels.length) {
      return Container(
        height: 250, // Consistent height for no-data message
        alignment: Alignment.center,
        margin: const EdgeInsets.only(bottom: 20),
        child: Text(
          'No data available for $title or data mismatch.',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Calculate Y-axis range with padding
    double dataMinY = yValues.reduce(min);
    double dataMaxY = yValues.reduce(max);
    double yRange = dataMaxY - dataMinY;
    // Add padding to avoid data points touching the border.
    // If range is 0 (all points same value), add a default padding.
    double yPaddingValue = (yRange == 0) ? 10 : yRange * 0.1;

    double finalMinY = dataMinY - yPaddingValue;
    // Add slightly more padding at the top for better visual separation.
    double finalMaxY = dataMaxY + (yPaddingValue * 1.5) + (yRange == 0 ? 5 : 0);

    // Ensure minY and maxY are not the same, which can cause issues with FlChart.
    if (finalMinY == finalMaxY) {
      finalMinY -= 5; // Arbitrary small difference
      finalMaxY += 5;
    }

    // Determine if the graph is in its default (identity) transformation state
    final bool isNormalView = controller.value == Matrix4.identity();

    return Column(
      children: [
        // Graph title
        Align(
          alignment: Alignment.center,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
        ),
        // Graph container
        Container(
          height: 250, // Fixed height for the chart area
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.only(
            left: 18, // Padding for Y-axis labels if shown on left
            right:
                18, // Padding for Y-axis labels if shown on right / chart edge
            top: 8,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white, // Card background
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                // Subtle shadow for depth
                color: Color.fromARGB(31, 2, 0, 0),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: LineChart(
            // Configuration for pan and zoom
            transformationConfig: FlTransformationConfig(
              scaleAxis:
                  FlScaleAxis.horizontal, // Allow horizontal scaling (zoom)
              minScale: 1, // Minimum zoom level (1x = no zoom)
              maxScale: 20.0, // Maximum zoom level
              panEnabled: _isPanEnabled, // Enable panning
              scaleEnabled: _isScaleEnabled, // Enable scaling
              transformationController:
                  controller, // Controller for managing state
            ),
            LineChartData(
              gridData: FlGridData(show: true), // Show grid lines
              titlesData: FlTitlesData(
                // Bottom (X-axis) titles
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, // Show the X-axis labels
                    reservedSize: 30, // Space reserved for labels
                    interval:
                        currentXAxisInterval, // Calculated interval between labels
                    getTitlesWidget: (value, meta) {
                      // This function provides the widget for each X-axis label.
                      // It's called for values determined by the 'interval'.

                      // Ensure we only try to get labels for integer indices.
                      // `value` can be a double due to FlSpot.x.
                      if (value != value.floor().toDouble()) {
                        return const SizedBox.shrink(); // Don't show for non-integer x values
                      }
                      final int index = value.toInt();
                      if (index >= 0 && index < currentXLabels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                          ), // Padding above label text
                          child: Text(
                            currentXLabels[index], // Get label string from the list
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10, // Label font size
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink(); // Return empty for out-of-bounds indices
                    },
                  ),
                ),
                // Hide titles on other sides
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
              borderData: FlBorderData(
                // Chart border
                show: true,
                border: Border.all(color: const Color(0xffe7e7e7), width: 1),
              ),
              // X-axis range (from index 0 to last index)
              minX: 0,
              maxX: (currentXLabels.length - 1).toDouble().clamp(
                0,
                double.infinity,
              ),
              // Y-axis range (calculated with padding)
              minY: finalMinY,
              maxY: finalMaxY,
              // Data for the line
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    // Generate FlSpot from yValues
                    yValues.length,
                    (index) => FlSpot(index.toDouble(), yValues[index]),
                  ),
                  isCurved: true, // Smooth curve for the line
                  color: Colors.blueAccent, // Line color
                  barWidth: 2, // Line thickness
                  dotData: FlDotData(show: true), // Show dots on data points
                  belowBarData: BarAreaData(
                    // Area below the line
                    show: true,
                    gradient: LinearGradient(
                      // Gradient fill for the area
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
              // Tooltip configuration
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true, // Use default touch handling
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: // Tooltip background color
                      (LineBarSpot spot) =>
                          const Color.fromRGBO(96, 125, 139, 0.8),
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    // Customize tooltip content
                    return touchedBarSpots
                        .map((barSpot) {
                          final flSpot = barSpot;
                          // Ensure index is valid
                          if (flSpot.x.toInt() < 0 ||
                              flSpot.x.toInt() >= currentXLabels.length) {
                            return null; // Should not happen if data is consistent
                          }

                          String timeLabel = currentXLabels[flSpot.x.toInt()];
                          String unit =
                              ''; // Determine unit based on graph title
                          switch (title) {
                            case 'Temperature':
                              unit = '°C';
                              break;
                            case 'Humidity':
                              unit = '%';
                              break;
                            case 'CO₂ Level':
                              unit = 'ppm';
                              break;
                            case 'Average Light Intensity':
                              unit = 'LUX';
                              break;
                          }

                          const baseStyle = TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          );

                          return LineTooltipItem(
                            '', // Empty main text, using children for formatted content
                            baseStyle,
                            children: [
                              TextSpan(
                                text: '$timeLabel\n', // Time label
                                style: baseStyle.copyWith(
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              TextSpan(
                                // Value with unit
                                text: '${flSpot.y.toStringAsFixed(1)} $unit',
                                style: baseStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            textAlign: TextAlign.center,
                          );
                        })
                        .where(
                          (item) => item != null,
                        ) // Filter out any null tooltips
                        .toList();
                  },
                  fitInsideHorizontally: true, // Ensure tooltip fits on screen
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Reset View Button
        SizedBox(
          width: double.infinity, // Make button take full width
          height: 40,
          child: FilledButton(
            // Disable button if graph is already in normal (unzoomed/unpanned) view
            onPressed:
                isNormalView
                    ? null
                    : () =>
                        _animateTransformationControllerToIdentity(controller),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              disabledBackgroundColor: const Color.fromRGBO(
                33,
                150,
                243,
                0.5,
              ), // Appearance when disabled
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              // Icon and text for button
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.refresh, size: 20, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Reset View',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20), // Spacing after button
      ],
    );
  }
}

// Widget for circular hover effect on icons (Settings, Notifications)
class HoverCircleIcon extends StatefulWidget {
  final IconData iconData;
  const HoverCircleIcon({required this.iconData, super.key});
  @override
  State<HoverCircleIcon> createState() => _HoverCircleIconState();
}

class _HoverCircleIconState extends State<HoverCircleIcon> {
  bool _isHovering = false; // State to track hover
  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Makes the area tappable and provides hover effects
      onTap: () {
        // Navigation logic based on icon
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
      onHover: (hovering) {
        // Update hover state
        setState(() {
          _isHovering = hovering;
        });
      },
      borderRadius: BorderRadius.circular(
        50,
      ), // Circular shape for hover effect
      splashColor: const Color.fromRGBO(
        0,
        123,
        255,
        0.2,
      ), // Splash color on tap
      highlightColor: const Color.fromRGBO(
        0,
        123,
        255,
        0.1,
      ), // Highlight color on press
      child: AnimatedContainer(
        // Animate background color change on hover
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              _isHovering // Change color based on hover state
                  ? const Color.fromRGBO(
                    158,
                    158,
                    158,
                    0.1,
                  ) // Light grey when hovering
                  : Colors.transparent, // Transparent when not hovering
        ),
        child: Icon(
          widget.iconData,
          size: 24,
          color: const Color.fromARGB(221, 0, 0, 0), // Icon color
        ),
      ),
    );
  }
}
