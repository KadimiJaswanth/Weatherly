import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String apiKey = 'YOUR_API_KEY'; // Your API key
  static const String baseUrl = 'http://api.weatherapi.com/v1';

  // Fetch weather + forecast by city name (default 7 days)
  static Future<Map<String, dynamic>> fetchWeatherWithForecast(String city, {int days = 7}) async {
    final url = '$baseUrl/forecast.json?key=$apiKey&q=$city&days=$days&aqi=yes&alerts=no';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather and forecast');
    }
  }

  // Fetch weather + forecast by coords (default 7 days)
  static Future<Map<String, dynamic>> fetchWeatherByCoordsWithForecast(double lat, double lon, {int days = 7}) async {
    final url = '$baseUrl/forecast.json?key=$apiKey&q=$lat,$lon&days=$days&aqi=yes&alerts=no';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather and forecast by coords');
    }
  }
}
