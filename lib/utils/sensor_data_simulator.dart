import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SensorDataSimulator {
  final Random _random = Random();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate realistic sensor data
  Map<String, dynamic> generateSensorData(String crop) {
    // Define realistic ranges for each crop
    Map<String, Map<String, dynamic>> cropRanges = {
      "tomato": {
        "moisture": [30, 60], // Ideal soil moisture percentage
        "temperature": [18, 30], // Ideal temperature in °C
        "ph": [6.0, 6.8], // Ideal pH range
        "ec": [0.8, 2.0], // Electrical conductivity in dS/m
        "nitrogen": [20, 50], // Nitrogen in mg/kg
        "phosphorus": [15, 40], // Phosphorus in mg/kg
        "potassium": [150, 250], // Potassium in mg/kg
      },
      "onion": {
        "moisture": [25, 50],
        "temperature": [15, 25],
        "ph": [6.0, 7.0],
        "ec": [0.6, 1.5],
        "nitrogen": [10, 40],
        "phosphorus": [10, 30],
        "potassium": [120, 200],
      },
      "potato": {
        "moisture": [40, 70],
        "temperature": [15, 20],
        "ph": [5.5, 6.5],
        "ec": [0.5, 1.2],
        "nitrogen": [30, 60],
        "phosphorus": [20, 50],
        "potassium": [200, 300],
      },
    };

    // Get ranges for the selected crop
    final ranges = cropRanges[crop] ?? cropRanges["tomato"]!;

    // Generate random values within the specified ranges
    final sensorData = {
      "moisture": _randomInRange(ranges["moisture"][0], ranges["moisture"][1]),
      "temperature": _randomInRange(
        ranges["temperature"][0],
        ranges["temperature"][1],
      ),
      "ph": _randomInRange(ranges["ph"][0], ranges["ph"][1]),
      "ec": _randomInRange(ranges["ec"][0], ranges["ec"][1]),
      "nitrogen": _randomInRange(ranges["nitrogen"][0], ranges["nitrogen"][1]),
      "phosphorus": _randomInRange(
        ranges["phosphorus"][0],
        ranges["phosphorus"][1],
      ),
      "potassium": _randomInRange(
        ranges["potassium"][0],
        ranges["potassium"][1],
      ),
      "timestamp": FieldValue.serverTimestamp(), // Add a timestamp
    };

    // Round all values to 1 decimal place
    final roundedSensorData = sensorData.map((key, value) {
      if (value is double) {
        return MapEntry(key, double.parse(value.toStringAsFixed(1)));
      }
      return MapEntry(key, value);
    });

    // Debugging output
    if (kDebugMode) {
      print("Generated sensor data: $roundedSensorData");
    }

    return roundedSensorData;
  }

  // Helper function to generate random values within a range
  double _randomInRange(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  // Send simulated data to Firestore
  Future<void> sendToFirestore(String crop) async {
    final sensorData = generateSensorData(crop);
    try {
      // Use a unique ID based on the current timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore.collection('sensor_data').doc(timestamp).set({
        "crop": crop,
        "data": sensorData,
        "timestamp": FieldValue.serverTimestamp(),
      });
      // Always update the 'latest' document for dashboard
      await _firestore.collection('sensor_data').doc('latest').set({
        "crop": crop,
        "data": sensorData,
        "timestamp": FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print("Sensor data for $crop sent to Firestore: $sensorData");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to send sensor data: $e");
      }
    }
  }

  // Start simulation at regular intervals
  void startSimulation(String crop, {int intervalSeconds = 33}) {
    Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
      sendToFirestore(crop); // Use the current instance
    });
  }
}
