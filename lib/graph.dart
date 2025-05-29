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
  static const int _maxLabelsToShowWhenZoomedOut =
      10; // Target labels when fully zoomed out
  static const double _minScaleForDenseLabels =
      1.0; // Scale at which zoomedOutInterval ideally applies
  static const double _maxScaleForIntervalOne =
      2.5; // Scale at or beyond which interval becomes 1.0

  @override
  void initState() {
    super.initState();
    _graphControllers = {
      for (var title in _graphTitles) title: TransformationController(),
    };

    // Initialize intervals and add listeners
    for (var title in _graphTitles) {
      _xAxisIntervals[title] = _calculateXAxisInterval(
        currentDataLength: xLabels.length,
        currentScale: 1.0,
      );
      // Add a listener to each controller to rebuild the UI when its value changes,
      // which will help in updating the enabled/disabled state of the reset button.
      _graphControllers[title]?.addListener(() {
        if (mounted) {
          setState(() {
            // This setState call is crucial to rebuild and re-evaluate
            // the button's enabled state based on controller.value
          });
        }
        _updateXAxisIntervalForGraph(title, xLabels.length);
      });
    }
  }

  double _calculateXAxisInterval({
    required int currentDataLength,
    required double currentScale,
  }) {
    if (currentDataLength == 0) return 1.0;

    final double zoomedOutInterval =
        (currentDataLength <= _maxLabelsToShowWhenZoomedOut)
            ? 1.0
            : (currentDataLength.toDouble() / _maxLabelsToShowWhenZoomedOut)
                .ceilToDouble();

    double newInterpolatedInterval;

    if (currentScale <= _minScaleForDenseLabels) {
      newInterpolatedInterval = zoomedOutInterval;
    } else if (currentScale >= _maxScaleForIntervalOne) {
      newInterpolatedInterval = 1.0;
    } else {
      final double factor =
          (currentScale - _minScaleForDenseLabels) /
          (_maxScaleForIntervalOne - _minScaleForDenseLabels);
      newInterpolatedInterval =
          zoomedOutInterval - factor * (zoomedOutInterval - 1.0);
    }

    double finalInterval;
    if (newInterpolatedInterval <= 1.5 && zoomedOutInterval > 1.0) {
      finalInterval = 1.0;
    } else {
      finalInterval = newInterpolatedInterval.roundToDouble();
    }

    return finalInterval.clamp(1.0, zoomedOutInterval);
  }

  void _updateXAxisIntervalForGraph(String graphTitle, int numLabels) {
    if (!mounted || _graphControllers[graphTitle] == null) return;

    final controller = _graphControllers[graphTitle]!;
    final scale = controller.value.getMaxScaleOnAxis();

    final double newInterval = _calculateXAxisInterval(
      currentDataLength: numLabels,
      currentScale: scale,
    );

    if (_xAxisIntervals[graphTitle] != newInterval) {
      if (mounted) {
        // Ensure widget is still mounted before calling setState
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
      // It's good practice to remove listeners if they were added with a specific function reference.
      // However, the anonymous function used in initState for addListener doesn't have a direct reference
      // to remove here. TransformationController itself handles its listeners' lifecycle when it's disposed.
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
        for (var title in _graphTitles) {
          _instantTransformationReset(_graphControllers[title]!);
        }
      });
    }
  }

  void _instantTransformationReset(TransformationController controller) {
    if (!mounted) return;
    setState(() {
      controller.value = Matrix4.identity();
    });
  }

  void _animateTransformationControllerToIdentity(
    TransformationController controllerToAnimate,
  ) {
    if (!mounted) return;

    _graphResetAnimationController?.stop();
    _graphResetAnimationController?.dispose();

    _controllerBeingReset = controllerToAnimate;
    _graphResetAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: _graphResetAnimationController!,
      curve: Curves.easeInOutCubic,
    );

    _graphResetMatrixAnimation = Matrix4Tween(
      begin: _controllerBeingReset!.value,
      end: Matrix4.identity(),
    ).animate(curvedAnimation);

    _graphResetMatrixAnimation!.addListener(() {
      if (mounted && _controllerBeingReset != null) {
        setState(() {
          _controllerBeingReset!.value = _graphResetMatrixAnimation!.value;
        });
      }
    });

    _graphResetAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted && _controllerBeingReset != null) {
          setState(() {
            _controllerBeingReset!.value = Matrix4.identity();
          });
        }
        _graphResetAnimationController?.dispose();
        _graphResetAnimationController = null;
        _graphResetMatrixAnimation = null;
        _controllerBeingReset = null;
      } else if (status == AnimationStatus.dismissed) {
        _graphResetAnimationController?.dispose();
        _graphResetAnimationController = null;
        _graphResetMatrixAnimation = null;
        _controllerBeingReset = null;
      }
    });

    _graphResetAnimationController!.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final String formattedDate = DateFormat(
      'dd MMM yyyy',
    ).format(_selectedDate);

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
                              (context, error, stackTrace) => const Icon(
                                Icons.image_not_supported,
                                size: 58,
                              ),
                        ),
                        HoverCircleIcon(iconData: Icons.notifications_none),
                      ],
                    ),
                    const SizedBox(height: 10),
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
                            offset: const Offset(0, 2),
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
                              backgroundColor: const Color(0xFF2196F3),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
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
                    _buildGraphSection(
                      _graphTitles[0],
                      temperatureValues,
                      xLabels,
                      _graphControllers[_graphTitles[0]]!,
                      _xAxisIntervals[_graphTitles[0]] ??
                          _calculateXAxisInterval(
                            currentDataLength: xLabels.length,
                            currentScale: 1.0,
                          ),
                    ),
                    _buildGraphSection(
                      _graphTitles[1],
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
                      _graphTitles[2],
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
                      _graphTitles[3],
                      lightIntensityValues,
                      xLabels,
                      _graphControllers[_graphTitles[3]]!,
                      _xAxisIntervals[_graphTitles[3]] ??
                          _calculateXAxisInterval(
                            currentDataLength: xLabels.length,
                            currentScale: 1.0,
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

  Widget _buildGraphSection(
    String title,
    List<double> yValues,
    List<String> currentXLabels,
    TransformationController controller,
    double currentXAxisInterval,
  ) {
    if (yValues.isEmpty ||
        currentXLabels.isEmpty ||
        yValues.length != currentXLabels.length) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        margin: const EdgeInsets.only(bottom: 20),
        child: Text(
          'No data available for $title or data mismatch.',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    double dataMinY = yValues.reduce(min);
    double dataMaxY = yValues.reduce(max);
    double yRange = dataMaxY - dataMinY;
    double yPaddingValue = (yRange == 0) ? 10 : yRange * 0.1;

    double finalMinY = dataMinY - yPaddingValue;
    double finalMaxY = dataMaxY + (yPaddingValue * 1.5) + (yRange == 0 ? 5 : 0);

    if (finalMinY == finalMaxY) {
      finalMinY -= 5;
      finalMaxY += 5;
    }

    // Determine if the graph is in its identity (normal) state
    final bool isNormalView = controller.value == Matrix4.identity();

    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
        ),
        Container(
          height: 250,
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.only(
            left: 18,
            right: 18,
            top: 8,
            bottom: 8,
          ),
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
          child: LineChart(
            transformationConfig: FlTransformationConfig(
              scaleAxis: FlScaleAxis.horizontal,
              minScale: 1,
              maxScale: 20.0,
              panEnabled: _isPanEnabled,
              scaleEnabled: _isScaleEnabled,
              transformationController: controller,
            ),
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: currentXAxisInterval,
                    getTitlesWidget: (value, meta) {
                      if (value != value.floor().toDouble()) {
                        return const SizedBox.shrink();
                      }
                      final int index = value.toInt();
                      if (index >= 0 && index < currentXLabels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            currentXLabels[index],
                            style: const TextStyle(
                              color: Colors.black,
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
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xffe7e7e7), width: 1),
              ),
              minX: 0,
              maxX: (currentXLabels.length - 1).toDouble().clamp(
                0,
                double.infinity,
              ),
              minY: finalMinY,
              maxY: finalMaxY,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    yValues.length,
                    (index) => FlSpot(index.toDouble(), yValues[index]),
                  ),
                  isCurved: true,
                  color: Colors.blueAccent,
                  barWidth: 2,
                  dotData: FlDotData(show: true),
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
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor:
                      (LineBarSpot spot) =>
                          const Color.fromRGBO(96, 125, 139, 0.8),
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots
                        .map((barSpot) {
                          final flSpot = barSpot;
                          if (flSpot.x.toInt() < 0 ||
                              flSpot.x.toInt() >= currentXLabels.length) {
                            return null;
                          }

                          String timeLabel = currentXLabels[flSpot.x.toInt()];
                          String unit = '';
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
                            '',
                            baseStyle,
                            children: [
                              TextSpan(
                                text: '$timeLabel\n',
                                style: baseStyle.copyWith(
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              TextSpan(
                                text: '${flSpot.y.toStringAsFixed(1)} $unit',
                                style: baseStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            textAlign: TextAlign.center,
                          );
                        })
                        .where((item) => item != null)
                        .toList();
                  },
                  fitInsideHorizontally: true,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: FilledButton(
            // Disable button if isNormalView is true, otherwise allow animation
            onPressed:
                isNormalView
                    ? null
                    : () =>
                        _animateTransformationControllerToIdentity(controller),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              // Optionally change button appearance when disabled
              disabledBackgroundColor: const Color.fromRGBO(33, 150, 243, 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
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
  bool _isHovering = false;
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
      onHover: (hovering) {
        setState(() {
          _isHovering = hovering;
        });
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
              _isHovering
                  ? const Color.fromRGBO(158, 158, 158, 0.1)
                  : Colors.transparent,
        ),
        child: Icon(
          widget.iconData,
          size: 24,
          color: const Color.fromARGB(221, 0, 0, 0),
        ),
      ),
    );
  }
}
