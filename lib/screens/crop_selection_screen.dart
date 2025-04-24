import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class CropSelectionScreen extends StatelessWidget {
  const CropSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final crops = ["Tomato", "Potato", "Onion"];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Your Crop"),
      ),
      body: ListView(
        children: crops.map((crop) {
          return ListTile(
            title: Text(crop),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DashboardScreen(selectedCrop: crop.toLowerCase()),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}