// File to store variables to the app data

/* Graph Menu Data*/

// X-axis labels (time)
List<String> xLabels = [
  "16:00",
  "16:30",
  "17:00",
  "17:30",
  "18:00",
  "18:30",
  "19:00",
  "19:30",
  "20:00",
  "20:30",
  "21:00",
  "21:30",
]; // Provide your own x-axis labels

// Temperature data (Y-axis values)
List<double> temperatureValues = [
  30,
  32,
  35,
  33,
  31,
  40,
  38,
  36,
  37,
  39,
  41,
  42,
];

// Humidity data (Y-axis values)
List<double> humidityValues = [50, 52, 48, 49, 50, 70, 60, 65, 68, 72, 75, 80];

// CO2 Level data (Y-axis values)
List<double> co2Values = [
  400,
  420,
  410,
  430,
  440,
  450,
  460,
  470,
  480,
  490,
  500,
  510,
];

// Average Light Intensity data (Y-axis values)
List<double> lightIntensityValues = [
  200,
  250,
  230,
  210,
  220,
  240,
  260,
  270,
  280,
  290,
];

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

// Light Mode (Day or Night)
String lightModeDay = 'Mode 1'; // Default light mode for Day
String lightModeNight = 'Mode 1'; // Default light mode for Night

// Light intensity setpoints (in Lux) for Day and Night
double dayLightIntensity = 200; // Default day light intensity
double nightLightIntensity = 200; // Default night light intensity

// Brightness settings for Manual mode (Day and Night) as percentages (0-100%)
double dayPARBrightness = 50; // Default brightness for Day PAR Light
double dayRedBrightness = 50; // Default brightness for Day Red Light
double dayBlueBrightness = 50; // Default brightness for Day Blue Light
double nightPARBrightness = 50; // Default brightness for Night PAR Light
double nightRedBrightness = 50; // Default brightness for Night Red Light
double nightBlueBrightness = 50; // Default brightness for Night Blue Light
