import 'dart:math';

// File to store variables to the app data

/* Home Menu Data */
String temperature = '35.0';
String humidity = '75.0';
String co2 = '150.0';
String lightIntensity = '1000.0';

/* Graph Menu Data*/

// Helper function to generate a list of random doubles within a range
List<double> generateRandomData(
  int count,
  double min,
  double max, {
  int decimalPlaces = 1,
}) {
  Random random = Random();
  List<double> data = [];
  for (int i = 0; i < count; i++) {
    double value = min + random.nextDouble() * (max - min);
    data.add(double.parse(value.toStringAsFixed(decimalPlaces)));
  }
  return data;
}

// Helper function to generate xLabels for 24 hours with a given minute interval
List<String> generateXLabels(int minuteInterval) {
  List<String> labels = [];
  for (int hour = 0; hour < 24; hour++) {
    for (int minute = 0; minute < 60; minute += minuteInterval) {
      labels.add(
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      );
    }
  }
  return labels;
}

const int _numberOfDataPointsForGraph = 24 * 60 ~/ 2; // 720 data points

// X-axis labels (time) - 24 hours, 2-minute intervals
List<String> xLabels = generateXLabels(2);

// Temperature data (Y-axis values) - Randomized for 720 data points
List<double> temperatureValues = generateRandomData(
  _numberOfDataPointsForGraph,
  20.0,
  45.0,
);

// Humidity data (Y-axis values) - Randomized for 720 data points
List<double> humidityValues = generateRandomData(
  _numberOfDataPointsForGraph,
  30.0,
  90.0,
);

// CO2 Level data (Y-axis values) - Randomized for 720 data points
List<double> co2Values = generateRandomData(
  _numberOfDataPointsForGraph,
  300.0,
  1000.0,
);

// Average Light Intensity data (Y-axis values) - Randomized for 720 data points
List<double> lightIntensityValues = generateRandomData(
  _numberOfDataPointsForGraph,
  100.0,
  1500.0,
);

/* Spectrometer Menu Data */

// Wavelength range for the spectra
List<double> wavelength = [
  400,
  410,
  420,
  430,
  440,
  450,
  460,
  470,
  480,
  490,
  500,
  510,
  520,
  530,
  540,
  550,
  560,
  570,
  580,
  590,
  600,
  610,
  620,
  630,
  640,
  650,
  660,
  670,
  680,
  690,
  700,
]; // Wavelength values in nanometers (nm)

// Expected Spectrum data (Y-axis values for Expected Spectrum)
List<double> expectedSpectrumValues = [
  0.1,
  0.2,
  0.3,
  0.4,
  0.5,
  0.7,
  0.8,
  1.0,
  1.1,
  1.2,
  1.3,
  1.4,
  1.5,
  1.4,
  1.3,
  1.2,
  1.1,
  1.0,
  0.9,
  0.8,
  0.7,
  0.5,
  0.4,
  0.3,
  0.2,
  0.1,
  0.0,
  0.1,
  0.2,
  0.3,
  0.4,
]; // Replace with actual expected spectrum data

// Obtained Spectrum data (Y-axis values for Obtained Spectrum)
List<double> obtainedSpectrumValues = [
  0.1,
  0.15,
  0.25,
  0.35,
  0.45,
  0.55,
  0.6,
  0.65,
  0.7,
  0.75,
  0.8,
  0.85,
  0.9,
  0.85,
  0.8,
  0.75,
  0.7,
  0.65,
  0.6,
  0.55,
  0.5,
  0.45,
  0.4,
  0.35,
  0.3,
  0.25,
  0.2,
  0.15,
  0.1,
  0.05,
  0.0,
]; // Replace with actual obtained spectrum data

/* Setpoint Data */

// Temperature data for day and night (°C)
double dayTemperature = 0; // Default for day
double nightTemperature = 0; // Default for night

// Humidity data for day and night (%)
double dayHumidity = 0; // Default for day
double nightHumidity = 0; // Default for night

// CO2 Level data for day and night (ppm)
double dayCO2 = 0; // Default for day
double nightCO2 = 0; // Default for night

// Light Intensity data for day and night (lux)
double dayLightIntensity = 0; // Default for day
double nightLightIntensity = 0; // Default for night

// Light Modes for Day and Night
String dayLightMode = 'Mode 1'; // Default for day
String nightLightMode = 'Mode 1'; // Default for night

// Light PWM for Manual Mode (Day)
double parDayPWM = 0.0;
double redDayPWM = 0.0;
double blueDayPWM = 0.0;
double uvDayPWM = 0.0;
double irDayPWM = 0.0;

// Light PWM for Manual Mode (Night)
double parNightPWM = 0.0;
double redNightPWM = 0.0;
double blueNightPWM = 0.0;
double uvNightPWM = 0.0;
double irNightPWM = 0.0;

// Light Mode Options (used for dropdown)
List<String> modeDescriptions = [
  'Mode 1: PAR Light Only',
  'Mode 2: PAR Light + Red Light',
  'Mode 3: PAR Light + Blue Light',
  'Mode 4: PAR + Red + Blue + UV + IR',
  'Mode 5: All lights off',
  'Manual',
];
