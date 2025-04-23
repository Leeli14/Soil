import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<Map<String, dynamic>> getPrediction(
    String crop,
    Map<String, dynamic> sensorData,
  ) async {
    const url =
        "http://<YOUR_LOCAL_IP>:5000/predict"; // Replace with your Flask server IP

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
q