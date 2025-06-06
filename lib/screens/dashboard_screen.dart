// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardScreen extends StatefulWidget {
  final String selectedCrop;
  const DashboardScreen({super.key, required this.selectedCrop});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? prediction;
  bool isLoading = false;

  final apiServices = ApiServices();

  void getPredictionFromBackend() async {
    setState(() => isLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('sensor_data')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception("No sensor data available");
      }

      final doc = querySnapshot.docs.first;
      final rawSensorData = doc.data();

      // Define required keys with default values
      final defaultValues = {
        "moisture": 0.0,
        "temperature": 0.0,
        "ph": 7.0,
        "ec": 0.0,
        "nitrogen": 0.0,
        "phosphorus": 0.0,
        "potassium": 0.0,
      };

      // Merge defaults with fetched data
      final cleanedSensorData = {
        for (var key in defaultValues.keys)
          key: rawSensorData.containsKey(key)
              ? rawSensorData[key] ?? defaultValues[key]
              : defaultValues[key],
      };

      // Optional debug log
      if (kDebugMode) {
        print("Cleaned sensor data sent to backend: $cleanedSensorData");
      }

      final result = await apiServices.getPrediction(widget.selectedCrop, cleanedSensorData);

      setState(() => prediction = result);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard - ${widget.selectedCrop.toUpperCase()}"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sensor_data')
            .orderBy('timestamp', descending: true)
            .limit(1)

            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            if (kDebugMode) {
              print("No data found in Firestore.");
            }
            return const Center(child: Text("No sensor data available"));
          }

          final sensorData = snapshot.data!.docs.first.data() as Map<String, dynamic>?;

          if (sensorData == null) {
            if (kDebugMode) {
              print("Sensor data is null.");
            }
            return const Center(child: Text("Sensor data is null"));
          }

          if (kDebugMode) {
            print("Fetched sensor data: $sensorData");
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Live Sensor Readings",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                sensorInfoTile("EC", sensorData['ec']),
                sensorInfoTile("Moisture", sensorData['moisture']),
                sensorInfoTile("Nitrogen", sensorData['nitrogen']),
                sensorInfoTile("pH", sensorData['ph']),
                sensorInfoTile("Phosphorus", sensorData['phosphorus']),
                sensorInfoTile("Potassium", sensorData['potassium']),
                sensorInfoTile("Temperature", sensorData['temperature']),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.analytics),
                  label: const Text("Get Prediction & Advice"),
                  onPressed: isLoading ? null : getPredictionFromBackend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                if (isLoading) const Center(child: CircularProgressIndicator()),
                if (prediction != null) buildPredictionCard(prediction!),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget sensorInfoTile(String title, dynamic value) {
    return ListTile(
      leading: const Icon(Icons.science),
      title: Text(title),
      trailing: Text(
        value != null ? value.toString() : 'N/A',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildPredictionCard(Map<String, dynamic> data) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Disease Prediction",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              "Disease: ${data['predicted_disease']}",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "Solution: ${data['solution']}",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "Irrigation Advice: ${data['irrigation']}",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "Fertilization Advice: ${data['fertilization']}",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class ApiServices {
  final String baseUrl =
      "https://zany-doodle-g46wvxjq59w9cv655-5000.app.github.dev";

  Future<Map<String, dynamic>> getPrediction(
    String crop,
    Map<String, dynamic> sensorData,
  ) async {
    final url = Uri.parse("$baseUrl/predict");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"crop": crop, "features": sensorData}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to fetch prediction: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}
