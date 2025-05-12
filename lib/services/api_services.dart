import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiServices {
  final String baseUrl =
      "https://zany-doodle-g46wvxjq59w9cv655-5000.app.github.dev"; // Replace with your backend URL

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
