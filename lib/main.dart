// ignore_for_file: duplicate_import

// Removed unused import
import 'package:flutter/material.dart';
import 'screens/crop_selection_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// ignore: unused_import

@pragma('vm:entry-point')
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyD9m9NVzK_IJOUpUT-libzDuj5uaGmLmHU",
        authDomain: "farm-advisory-system.firebaseapp.com",
        projectId: "farm-advisory-system",
        storageBucket: "farm-advisory-system.firebasestorage.app",
        messagingSenderId: "293396674022",
        appId: "1:293396674022:web:cade79b5dd568aa0ed5227",
        measurementId: "G-GMVYH102JB",
      ),
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Start the sensor data simulation
  final simulator = SensorDataSimulator();
  simulator.startSimulation("tomato"); // Simulate data for "tomato"

  runApp(const SoilAdvisorApp());
}

class SoilAdvisorApp extends StatelessWidget {
  const SoilAdvisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soil Advisor',
      theme: ThemeData.dark(),
      home: const CropSelectionScreen(),
    );
  }
}

class SensorDataSimulator {
  // Add your existing code here

  void startSimulation(String cropType) {
    // Simulate sensor data for the given crop type
    if (kDebugMode) {
      print('Simulating sensor data for $cropType...');
    }
  }
}
