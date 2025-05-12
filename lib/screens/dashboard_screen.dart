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

  final apiServices = ApiServices(); // Assuming you have an ApiServices class
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void getPredictionFromBackend() async {
    setState(() => isLoading = true);
    try {
      // Query the most recent document
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('sensor_data')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception("No sensor data available");
      }

      final doc = querySnapshot.docs.first;
      final sensorData = doc.data()['data'];
      final crop = doc.data()['crop'];

      // Send the data to the backend for predictions
      final result = await apiServices.getPrediction(crop, sensorData);

      // Update Firestore with the latest prediction
      await _firestore.collection('sensor_data').doc('latest').set({
        "crop": crop,
        "data": sensorData,
        "timestamp": FieldValue.serverTimestamp(),
      });

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
    final sensorDoc = FirebaseFirestore.instance
        .collection('sensor_data')
        .doc('latest');

    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard - ${widget.selectedCrop.toUpperCase()}"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: sensorDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            if (kDebugMode) {
              print("No data found in Firestore.");
            }
            return const Center(child: Text("No sensor data available"));
          }

          final sensorData = snapshot.data!.data() as Map<String, dynamic>?;

          if (sensorData == null) {
            if (kDebugMode) {
              print("Sensor data is null.");
            }
            return const Center(child: Text("Sensor data is null"));
          }

          if (kDebugMode) {
            print("Fetched sensor data: $sensorData");
          }

          final data = sensorData['data'] as Map<String, dynamic>?;

          if (data == null) {
            if (kDebugMode) {
              print("Sensor data['data'] is null.");
            }
            return const Center(child: Text("No sensor readings available"));
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
                sensorInfoTile("Moisture", data['moisture']),
                sensorInfoTile("pH", data['ph']),
                sensorInfoTile("Temperature", data['temperature']),
                sensorInfoTile("EC", data['ec']),
                sensorInfoTile("Nitrogen", data['nitrogen']),
                sensorInfoTile("Phosphorus", data['phosphorus']),
                sensorInfoTile("Potassium", data['potassium']),
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
        value.toString(),
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
