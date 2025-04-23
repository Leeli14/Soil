import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<Map<String, dynamic>> getPrediction(
    String crop,
    Map<String, dynamic> sensorData,
  ) async {
    const url =
        "https://zany-doodle-g46wvxjq59w9cv655-5000.app.github.dev/predict"; // Replace with your backend URL

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"crop": crop, "features": sensorData}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to get prediction: ${response.body}");
    }
  }
}
