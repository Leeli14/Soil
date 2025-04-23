import 'package:flutter/material.dart';
import 'screens/crop_selection_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Initialize Firebase or any other services here if needed
  // You can also set up any other services like Firebase Analytics, etc.
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
