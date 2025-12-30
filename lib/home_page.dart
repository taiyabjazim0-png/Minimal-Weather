import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:geolocator/geolocator.dart';
import 'weather_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // ---------------- STATE ----------------
  String city = 'Loading...';
  String weatherType = 'sunny';
  String statusText = '';
  double temperature = 0;

  int highs = 0;
  int lows = 0;

  int day1 = 0, day2 = 0, day3 = 0, day4 = 0;

  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    loadWeatherWithLocation();
  }

  // ---------------- LOCATION ----------------
  Future<Position> _getAccurateLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception("Enable GPS");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception("Location permission denied");
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 20),
      );
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      rethrow;
    }
  }

  // ---------------- HIGH / LOW FIX ----------------
  Map<String, int> calculateHighLow(List forecastList) {
    final temps = forecastList
        .take(8) // first 24 hours
        .map((e) => e['main']['temp'] as num)
        .toList();

    final high = temps.reduce((a, b) => a > b ? a : b);
    final low = temps.reduce((a, b) => a < b ? a : b);

    return {
      'high': high.toInt(),
      'low': low.toInt(),
    };
  }

  // ---------------- LOAD WEATHER ----------------
  Future<void> loadWeatherWithLocation() async {
    try {
      final position = await _getAccurateLocation();

      final service = WeatherService();
      final data = await service.fetchWeatherByLocation(
        lat: position.latitude,
        lon: position.longitude,
      );

      final current = data['weather'];
      final forecast = data['forecast'];
      final hl = calculateHighLow(forecast['list']);

      setState(() {
        city = current['name'];
        temperature = (current['main']['temp'] as num).toDouble();
        weatherType = current['weather'][0]['main'].toLowerCase();
        statusText = current['weather'][0]['description'];

        highs = hl['high']!;
        lows = hl['low']!;

        day1 = (forecast['list'][8]['main']['temp'] as num).toInt();
        day2 = (forecast['list'][16]['main']['temp'] as num).toInt();
        day3 = (forecast['list'][24]['main']['temp'] as num).toInt();
        day4 = (forecast['list'][32]['main']['temp'] as num).toInt();

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // ---------------- GRAPH HELPERS ----------------
  double getMinTemp() {
    final temps = [day1, day2, day3, day4]..sort();
    return (temps.first - 5).toDouble();
  }

  double getMaxTemp() {
    final temps = [day1, day2, day3, day4]..sort();
    return (temps.last + 5).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error.isNotEmpty) {
      return Scaffold(
        body: Center(child: Text(error)),
      );
    }

    // ---------------- WEATHER IMAGE ----------------
    String bg = 'assets/images/sunny.jpg';
    if (weatherType.contains('rain')) bg = 'assets/images/rainy.png';
    if (weatherType.contains('haze')) {
      bg = 'assets/images/haze.jpg';
    }
    if(weatherType.contains("mist")) {
      bg = 'assets/images/mist.jpg';
    }
    if(weatherType.contains("fog")){
      bg = 'assets/images/fog.jpg';
    }
    if(weatherType.contains("cloud")){
      bg = 'assets/images/rainy.jpg';
    }
    if (weatherType.contains('thunder')) bg = 'assets/images/thunder.png';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(bg, fit: BoxFit.cover),
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 50),

                  Text(
                    city,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Nunito',
                    ),
                  ),

                  const SizedBox(height: 60),

                  Text(
                    '${temperature.toStringAsFixed(0)}°C',
                    style: const TextStyle(fontSize: 42),
                  ),

                  Text(
                    statusText,
                    style: const TextStyle(fontSize: 20),
                  ),

                  Text(
                    'H:$highs°  L:$lows°',
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 120),

                  SizedBox(
                    width: 380,
                    height: 240,
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 3,
                        minY: getMinTemp(),
                        maxY: getMaxTemp(),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            barWidth: 4,
                            dotData: FlDotData(show: false),
                            spots: [
                              FlSpot(0, day1.toDouble()),
                              FlSpot(1, day2.toDouble()),
                              FlSpot(2, day3.toDouble()),
                              FlSpot(3, day4.toDouble()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
