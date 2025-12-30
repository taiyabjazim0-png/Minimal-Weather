import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = '33c0e64dbf681ecb34ad19ca20de16af';

  // ---------------- CURRENT + FORECAST BY LOCATION ----------------
  Future<Map<String, dynamic>> fetchWeatherByLocation({
    required double lat,
    required double lon,
  }) async {
    final weatherUrl = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$_apiKey',
    );

    final forecastUrl = Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&appid=$_apiKey',
    );

    final weatherResponse = await http.get(weatherUrl);
    final forecastResponse = await http.get(forecastUrl);

    if (weatherResponse.statusCode == 200 &&
        forecastResponse.statusCode == 200) {
      return {
        'weather': json.decode(weatherResponse.body),
        'forecast': json.decode(forecastResponse.body),
      };
    } else {
      throw Exception('Failed to load weather');
    }
  }

  // ---------------- OPTIONAL: CITY VERSION (KEEP IF YOU WANT) ----------------
  Future<Map<String, dynamic>> fetchWeatherAndForecast(String city) async {
    final weatherUrl = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$_apiKey',
    );

    final forecastUrl = Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast?q=$city&units=metric&appid=$_apiKey',
    );

    final weatherResponse = await http.get(weatherUrl);
    final forecastResponse = await http.get(forecastUrl);

    if (weatherResponse.statusCode == 200 &&
        forecastResponse.statusCode == 200) {
      return {
        'weather': json.decode(weatherResponse.body),
        'forecast': json.decode(forecastResponse.body),
      };
    } else {
      throw Exception('Failed to load weather');
    }
  }
}
