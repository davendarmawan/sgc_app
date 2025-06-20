import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'settings.dart'; // Assuming this exists
import 'notifications.dart'; // Assuming this exists
import 'services/ondate_service.dart'; // Import the API service
import 'dart:math';

class GraphPage extends StatefulWidget {
  final int? deviceId; // Make device ID optional
  
  const GraphPage({super.key, this.deviceId});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  late Map<String, TransformationController> _graphControllers;
  final bool _isPanEnabled = true;
  final bool _isScaleEnabled = true;

  // Device selection
  int? _selectedDeviceId;
  List<Device> _availableDevices = [];
  bool _isLoadingDevices = false;

  // Loading and error states
  bool _isLoading = false;
  String? _errorMessage;

  // Data from API
  List<String> _xLabels = [];
  List<double> _temperatureValues = [];
  List<double> _humidityValues = [];
  List<double> _co2Values = [];
  List<double> _lightIntensityValues = [];

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

  // This constant determines when dots appear on the line chart.
  // If the X-axis interval is this value or less, dots are shown.
  static const double _maxIntervalForDots = 3.0;

  @override
  void initState() {
    super.initState();
    _graphControllers = {
      for (var title in _graphTitles) title: TransformationController(),
    };

    // Initialize intervals and add listeners
    for (var title in _graphTitles) {
      _xAxisIntervals[title] = 1.0; // Default value
      _graphControllers[title]?.addListener(() {
        if (mounted) {
          setState(() {
            // This setState call is crucial to rebuild and re-evaluate
            // the button's enabled state based on controller.value
          });
        }
        _updateXAxisIntervalForGraph(title, _xLabels.length);
      });
    }

    // Set initial device ID if provided
    _selectedDeviceId = widget.deviceId;

    // Load devices and initial data
    _loadDevices();
  }

  // Load available devices
  Future<void> _loadDevices() async {
    setState(() {
      _isLoadingDevices = true;
    });

    try {
      // If deviceId was provided in constructor, use it and load data
      if (_selectedDeviceId != null) {
        await _loadData();
      } else {
        // TODO: Load available devices from API
        // For now, we'll create some sample devices
        // You should replace this with actual API call to get user's devices
        _availableDevices = [
          Device(id: 1, name: 'Device 1'),
          Device(id: 2, name: 'Device 2'),
          Device(id: 3, name: 'Device 3'),
        ];
        
        // Select first device by default if available
        if (_availableDevices.isNotEmpty) {
          _selectedDeviceId = _availableDevices.first.id;
          await _loadData();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load devices: $e';
      });
    } finally {
      setState(() {
        _isLoadingDevices = false;
      });
    }
  }

  // Load data from API
  Future<void> _loadData() async {
    if (_selectedDeviceId == null) {
      setState(() {
        _errorMessage = 'No device selected';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final ConditionData conditionData = await ApiService.getConditionData(
        _selectedDeviceId!,
        date: dateString,
      );

      setState(() {
        _xLabels = conditionData.xLabels;
        _temperatureValues = conditionData.temperatureValues;
        _humidityValues = conditionData.humidityValues;
        _co2Values = conditionData.co2Values;
        _lightIntensityValues = conditionData.lightIntensityValues;
        _isLoading = false;

        // Recalculate intervals for all graphs
        for (var title in _graphTitles) {
          _instantTransformationReset(_graphControllers[title]!);
          _xAxisIntervals[title] = _calculateXAxisInterval(
            currentDataLength: _xLabels.length,
            currentScale: 1.0,
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  double _calculateXAxisInterval({
    required int currentDataLength,
    required double currentScale,
  }) {
    const double targetLabelsInView = 7.0;
    const double segmentsInView = targetLabelsInView - 1.0;

    if (currentDataLength <= targetLabelsInView) {
      return 1.0;
    }

    double estimatedVisiblePoints = max(1.0, currentDataLength / currentScale);
    double idealInterval = (estimatedVisiblePoints / segmentsInView);
    double calculatedInterval = idealInterval.roundToDouble();

    double maxSensibleIntervalOverall = (currentDataLength / segmentsInView)
        .roundToDouble()
        .clamp(1.0, double.infinity);
    calculatedInterval = calculatedInterval.clamp(
      1.0,
      maxSensibleIntervalOverall,
    );

    return calculatedInterval;
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
      });
      // Reload data for the new date
      await _loadData();
    }
  }

  void _instantTransformationReset(TransformationController controller) {
    if (!mounted) return;
    setState(() {
      controller.value = Matrix4.identity();
      String? graphTitleToUpdate;
      _graphControllers.forEach((title, c) {
        if (c == controller) {
          graphTitleToUpdate = title;
        }
      });
      if (graphTitleToUpdate != null) {
        _xAxisIntervals[graphTitleToUpdate!] = _calculateXAxisInterval(
          currentDataLength: _xLabels.length,
          currentScale: 1.0,
        );
      }
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
    ).animate(curvedAnimation)..addListener(() {
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
            String? graphTitleToUpdate;
            _graphControllers.forEach((title, c) {
              if (c == _controllerBeingReset) {
                graphTitleToUpdate = title;
              }
            });
            if (graphTitleToUpdate != null) {
              _xAxisIntervals[graphTitleToUpdate!] = _calculateXAxisInterval(
                currentDataLength: _xLabels.length,
                currentScale: 1.0,
              );
            }
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

  // Calculate appropriate Y-axis interval
  double _calculateYAxisInterval(double minY, double maxY) {
    double range = maxY - minY;
    if (range <= 0) return 1.0;
    
    // Target around 5-7 labels on Y-axis
    double rawInterval = range / 6;
    
    // Round to nice numbers
    if (rawInterval < 1) {
      return 0.5;
    } else if (rawInterval < 2) {
      return 1.0;
    } else if (rawInterval < 5) {
      return 2.0;
    } else if (rawInterval < 10) {
      return 5.0;
    } else if (rawInterval < 20) {
      return 10.0;
    } else if (rawInterval < 50) {
      return 20.0;
    } else if (rawInterval < 100) {
      return 50.0;
    } else {
      return (rawInterval / 10).ceil() * 10;
    }
  }

  // Format Y-axis labels based on the graph type
  String _formatYAxisLabel(double value, String graphTitle) {
    switch (graphTitle) {
      case 'Temperature':
        return '${value.toInt()}°C';
      case 'Humidity':
        return '${value.toInt()}%';
      case 'CO₂ Level':
        return '${value.toInt()}ppm';
      case 'Average Light Intensity':
        return '${value.toInt()}';
      default:
        return value.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final String formattedDate = DateFormat('dd MMM yyyy').format(_selectedDate);

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
                        HoverCircleIcon(
                          iconData: Icons.settings,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsPage(),
                              ),
                            );
                          },
                        ),
                        Image.asset(
                          'assets/smartfarm_logo.png',
                          height: 58,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.image_not_supported,
                            size: 58,
                          ),
                        ),
                        HoverCircleIcon(
                          iconData: Icons.notifications_none,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notifications require service integration from HomePage'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
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
                    
                    // Device Selection
                    if (_availableDevices.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                Icon(Icons.devices, color: Colors.black87, size: 20),
                                SizedBox(width: 12),
                                Text(
                                  'Select Device',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            DropdownButton<int>(
                              value: _selectedDeviceId,
                              items: _availableDevices.map((device) {
                                return DropdownMenuItem<int>(
                                  value: device.id,
                                  child: Text(device.name),
                                );
                              }).toList(),
                              onChanged: _isLoadingDevices || _isLoading 
                                  ? null 
                                  : (int? newDeviceId) async {
                                      if (newDeviceId != null && newDeviceId != _selectedDeviceId) {
                                        setState(() {
                                          _selectedDeviceId = newDeviceId;
                                        });
                                        await _loadData();
                                      }
                                    },
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              underline: Container(),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 15),
                    
                    // Date Selection
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              Icon(Icons.calendar_today, color: Colors.black87, size: 20),
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
                            onPressed: _isLoading ? null : () => _selectDate(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    
                    // Show loading indicator
                    if (_isLoading || _isLoadingDevices)
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading sensor data...'),
                          ],
                        ),
                      )
                    
                    // Show error message
                    else if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load data',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    
                    // Show graphs when data is loaded
                    else ...[
                      _buildGraphSection(
                        _graphTitles[0],
                        _temperatureValues,
                        _xLabels,
                        _graphControllers[_graphTitles[0]]!,
                        _xAxisIntervals[_graphTitles[0]] ?? 1.0,
                      ),
                      _buildGraphSection(
                        _graphTitles[1],
                        _humidityValues,
                        _xLabels,
                        _graphControllers[_graphTitles[1]]!,
                        _xAxisIntervals[_graphTitles[1]] ?? 1.0,
                      ),
                      _buildGraphSection(
                        _graphTitles[2],
                        _co2Values,
                        _xLabels,
                        _graphControllers[_graphTitles[2]]!,
                        _xAxisIntervals[_graphTitles[2]] ?? 1.0,
                      ),
                      _buildGraphSection(
                        _graphTitles[3],
                        _lightIntensityValues,
                        _xLabels,
                        _graphControllers[_graphTitles[3]]!,
                        _xAxisIntervals[_graphTitles[3]] ?? 1.0,
                      ),
                    ],
                    
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
        padding: const EdgeInsets.all(16),
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
        child: Text(
          'No data available for $title for the selected date.',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
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

    final bool isNormalView = controller.value == Matrix4.identity();
    final bool showDots = currentXAxisInterval <= _maxIntervalForDots;

    final double dynamicMaxScale;
    if (currentXLabels.isNotEmpty) {
      dynamicMaxScale = max(5.0, currentXLabels.length / 6.0);
    } else {
      dynamicMaxScale = 5.0;
    }

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
          padding: const EdgeInsets.only(left: 18, right: 18, top: 12, bottom: 3),
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
            duration: Duration.zero,
            transformationConfig: FlTransformationConfig(
              scaleAxis: FlScaleAxis.horizontal,
              minScale: 1,
              maxScale: dynamicMaxScale,
              panEnabled: _isPanEnabled,
              scaleEnabled: _isScaleEnabled,
              transformationController: controller,
            ),
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                verticalInterval: currentXAxisInterval,
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: const Color.fromRGBO(158, 158, 158, 0.35),
                    strokeWidth: 0.8,
                    dashArray: [4, 4],
                  );
                },
                drawHorizontalLine: true,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: const Color.fromRGBO(158, 158, 158, 0.35),
                    strokeWidth: 0.8,
                    dashArray: [4, 4],
                  );
                },
              ),
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
                            style: const TextStyle(color: Colors.black, fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    interval: _calculateYAxisInterval(finalMinY, finalMaxY),
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          _formatYAxisLabel(value, title),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xffe7e7e7), width: 1),
              ),
              minX: 0,
              maxX: (currentXLabels.length - 1).toDouble().clamp(0.0, double.infinity),
              minY: finalMinY,
              maxY: finalMaxY,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    yValues.length,
                    (index) => FlSpot(index.toDouble(), yValues[index]),
                  ),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: FlDotData(show: showDots),
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
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (LineBarSpot spot) =>
                      const Color.fromRGBO(96, 125, 139, 0.9),
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots
                        .map((barSpot) {
                          final flSpot = barSpot;
                          if (flSpot.x.toInt() < 0 || flSpot.x.toInt() >= currentXLabels.length) {
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

                          const baseStyle = TextStyle(color: Colors.white, fontSize: 12);
                          return LineTooltipItem(
                            '',
                            baseStyle,
                            children: [
                              TextSpan(
                                text: '$timeLabel\n',
                                style: baseStyle.copyWith(fontWeight: FontWeight.normal),
                              ),
                              TextSpan(
                                text: '${flSpot.y.toStringAsFixed(1)} $unit',
                                style: baseStyle.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                            textAlign: TextAlign.center,
                          );
                        })
                        .whereType<LineTooltipItem>()
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
            onPressed: isNormalView ? null : () => _animateTransformationControllerToIdentity(controller),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              disabledBackgroundColor: const Color.fromRGBO(33, 150, 243, 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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

// Device class for device selection
class Device {
  final int id;
  final String name;

  Device({required this.id, required this.name});
}
// Replace the HoverCircleIcon class in ALL your files with this version:

class HoverCircleIcon extends StatefulWidget {
  final IconData iconData;
  final VoidCallback? onTap;
  final int badgeCount;

  const HoverCircleIcon({
    required this.iconData,
    this.onTap,
    this.badgeCount = 0,
    super.key,
  });

  @override
  State<HoverCircleIcon> createState() => _HoverCircleIconState();
}

class _HoverCircleIconState extends State<HoverCircleIcon> {
  bool _isPressed = false; // Remove 'final' and add state management

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap, // Use callback instead of hardcoded navigation
      onHighlightChanged: (pressed) {
        setState(() {
          _isPressed = pressed;
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
          color: _isPressed
              ? const Color.fromARGB(255, 109, 109, 109)
              : Colors.transparent,
        ),
        child: Stack(
          children: [
            Icon(
              widget.iconData,
              size: 24,
              color: _isPressed
                  ? const Color.fromARGB(255, 255, 255, 255)
                  : const Color.fromARGB(221, 0, 0, 0),
            ),
            // Notification badge
            if (widget.badgeCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    widget.badgeCount > 99 ? '99+' : widget.badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}