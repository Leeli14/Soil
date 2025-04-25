import 'package:flutter/material.dart';
import 'screens/crop_selection_screen.dart';
import 'package:firebase_core/firebase_core.dart';

@pragma('vm:entry-point')
void main() async {
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
