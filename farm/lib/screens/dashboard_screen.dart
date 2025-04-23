import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final String selectedCrop;
  const DashboardScreen({super.key, required this.selectedCrop});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? prediction;
  bool isLoading = false;

  void getPredictionFromBackend(Map<String, dynamic> sensorData) async {
    setState(() => isLoading = true);
    try {
      final result = await ApiService.getPrediction(
        widget.selectedCrop,
        sensorData,
      );
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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sensorData = snapshot.data!.data() as Map<String, dynamic>;

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
                sensorInfoTile("Moisture", sensorData['moisture']),
                sensorInfoTile("pH", sensorData['ph']),
                sensorInfoTile("Temperature", sensorData['temperature']),
                sensorInfoTile("EC", sensorData['ec']),
                sensorInfoTile("Nitrogen", sensorData['nitrogen']),
                sensorInfoTile("Phosphorus", sensorData['phosphorus']),
                sensorInfoTile("Potassium", sensorData['potassium']),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.analytics),
                  label: const Text("Get Prediction & Advice"),
                  onPressed:
                      isLoading
                          ? null
                          : () => getPredictionFromBackend(sensorData),
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
 QQ