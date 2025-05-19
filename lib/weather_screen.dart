import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weather_app/weather_service.dart'; // your existing service
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const WeatherlyApp());
}

class WeatherlyApp extends StatelessWidget {
  const WeatherlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weatherly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        scaffoldBackgroundColor: Colors.blueAccent,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WeatherScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF66A6FF), Color(0xFF89F7FE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.jpg', // Path to your logo image in assets
                width: 150, // Adjust size as needed
                height: 150,
              ),
              const SizedBox(height: 24),
              Text(
                'Weatherly',
                style: GoogleFonts.montserrat(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(0, 3),
                      blurRadius: 6,
                    )
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your personal weather companion',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              const SpinKitFadingCircle(
                color: Colors.white,
                size: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String city = '';
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  String? error;
  Timer? _debounce;
  final TextEditingController _cityController = TextEditingController();
  bool isCelsius = true;
  int selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    // Do NOT load last city to start with empty screen
    // _loadLastCity();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cityController.dispose();
    super.dispose();
  }

  void getWeather() async {
    if (city.isEmpty) {
      setState(() => error = 'Please enter a city name');
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
      weatherData = null;
      selectedDayIndex = 0;
    });

    try {
      final isConnected = await Connectivity().checkConnectivity();
      if (isConnected == ConnectivityResult.none) {
        setState(() => error = 'No internet connection');
        return;
      }

      final data = await WeatherService.fetchWeatherWithForecast(city, days: 3);
      setState(() {
        weatherData = data;
      });

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('lastCity', city);
    } catch (e) {
      setState(() {
        error = 'Could not fetch weather.';
        weatherData = null;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void onCityChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => city = value);
    });
  }

  Future<void> _getCurrentLocationWeather() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final data = await WeatherService.fetchWeatherByCoordsWithForecast(
        position.latitude,
        position.longitude,
        days: 3,
      );
      setState(() {
        weatherData = data;
        city = data['location']['name'];
        _cityController.text = city;
        selectedDayIndex = 0;
      });
    } catch (e) {
      setState(() => error = 'Could not detect location');
    }
  }

  List<Color> _getGradientForWeather(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('sunny') || condition.contains('clear')) {
      return [Color(0xFFFFD700), Color(0xFFFF8C00)];
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return [Color(0xFF4B79CF), Color(0xFF283E51)];
    } else if (condition.contains('snow')) {
      return [Color(0xFFE0EAFC), Color(0xFFCFDEF3)];
    } else if (condition.contains('cloud')) {
      return [Color(0xFF616161), Color(0xFF9BC5C3)];
    } else {
      return [Color(0xFF66A6FF), Color(0xFF89F7FE)];
    }
  }

  void _clearCityAndWeather() {
    setState(() {
      city = '';
      weatherData = null;
      error = null;
      _cityController.clear();
      selectedDayIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = weatherData != null
        ? _getGradientForWeather(weatherData!['current']['condition']['text'])
        : [Color(0xFF66A6FF), Color(0xFF89F7FE)];

    return Scaffold(
      backgroundColor: gradientColors[0],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),

                      const SizedBox(height: 30),

                      _buildSearchBar(),

                      if (error != null) _buildErrorSection(),

                      if (isLoading)
                        Center(
                          child: SpinKitFadingCircle(
                            color: Colors.white,
                            size: 50,
                          ),
                        ),

                      if (weatherData != null && !isLoading) ...[
                        const SizedBox(height: 30),
                        _buildCurrentWeather(),
                        const SizedBox(height: 30),
                        _buildTodayDetails(),
                        const SizedBox(height: 30),
                        _buildForecast(),
                      ],

                      if (city.isEmpty && weatherData == null && !isLoading)
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: Text(
                                'Hey there! Enter a city name to get started 🌤️ ',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final conditionText =
    weatherData != null ? weatherData!['current']['condition']['text'] : '';
    final iconUrl = weatherData != null
        ? "https:${weatherData!['current']['condition']['icon']}"
        : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: GestureDetector(
            onTap: () {
              _clearCityAndWeather();
            },
            child: Text(
              'Weatherly',
              style: GoogleFonts.montserrat(
                fontSize: 25,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (weatherData != null)
          Row(
            children: [
              if (iconUrl != null)
                Image.network(
                  iconUrl,
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: Text(
                  conditionText,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _cityController,
            onChanged: onCityChanged,
            decoration: InputDecoration(
              hintText: 'Enter city name',
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            style: const TextStyle(color: Colors.white),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              setState(() {
                city = _cityController.text.trim();
              });
              getWeather();
            },
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            setState(() {
              city = _cityController.text.trim();
            });
            getWeather();
          },
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(14),
            backgroundColor: Colors.white24,
          ),
          child: const Icon(Icons.arrow_forward, color: Colors.white),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _getCurrentLocationWeather,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(14),
            backgroundColor: Colors.white24,
          ),
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildErrorSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Center(
        child: Text(
          error!,
          style: GoogleFonts.montserrat(
            color: Colors.redAccent,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentWeather() {
    final current = weatherData!['current'];
    final location = weatherData!['location'];

    final tempC = current['temp_c'];
    final tempF = current['temp_f'];
    final temp = isCelsius ? tempC : tempF;

    final lastUpdated = current['last_updated'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          location['name'],
          style: GoogleFonts.montserrat(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          location['region'],
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                '${temp.toInt()}°${isCelsius ? 'C' : 'F'}',
                style: GoogleFonts.montserrat(
                  fontSize: 60,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feels like: ${isCelsius
                        ? current['feelslike_c']
                        : current['feelslike_f']}°',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: $lastUpdated',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  isCelsius = true;
                });
              },
              child: Text(
                '°C',
                style: TextStyle(
                  color: isCelsius ? Colors.white : Colors.white54,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isCelsius = false;
                });
              },
              child: Text(
                '°F',
                style: TextStyle(
                  color: !isCelsius ? Colors.white : Colors.white54,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayDetails() {
    final current = weatherData!['current'];
    final windKph = current['wind_kph'];
    final humidity = current['humidity'];
    final uv = current['uv'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _infoCard('Wind', '$windKph kph', Icons.air),
        _infoCard('Humidity', '$humidity%', Icons.opacity),
        _infoCard('UV Index', '$uv', Icons.wb_sunny),
      ],
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecast() {
    final forecastDays = weatherData!['forecast']['forecastday'];
    final selectedDay = forecastDays[selectedDayIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3-Day Forecast',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: forecastDays.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final day = forecastDays[index];
              final dayDate = DateFormat('EEE').format(
                  DateTime.parse(day['date']));
              final iconUrl = "https:${day['day']['condition']['icon']}";
              final maxTemp = isCelsius
                  ? day['day']['maxtemp_c']
                  : day['day']['maxtemp_f'];
              final minTemp = isCelsius
                  ? day['day']['mintemp_c']
                  : day['day']['mintemp_f'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDayIndex = index;
                  });
                },
                child: Container(
                  width: 110,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: selectedDayIndex == index ? Colors.white24 : Colors
                        .white12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          dayDate,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Image.network(iconUrl, width: 48, height: 48),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          '${maxTemp.toInt()}° / ${minTemp.toInt()}°',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildDetailedDayInfo(selectedDay),
      ],
    );
  }

  Widget _buildDetailedDayInfo(Map<String, dynamic> day) {
    final dayInfo = day['day'];
    final date = DateFormat('EEEE, MMM d').format(DateTime.parse(day['date']));
    final sunrise = day['astro']['sunrise'];
    final sunset = day['astro']['sunset'];
    final chanceOfRain = dayInfo['daily_chance_of_rain'];
    final maxTemp = isCelsius ? dayInfo['maxtemp_c'] : dayInfo['maxtemp_f'];
    final minTemp = isCelsius ? dayInfo['mintemp_c'] : dayInfo['mintemp_f'];
    final avgHumidity = dayInfo['avghumidity'];
    final condition = dayInfo['condition']['text'];
    final iconUrl = "https:${dayInfo['condition']['icon']}";

    Widget _rectInfoCard(String title, String value, IconData icon) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 28),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15), // lighter translucent shade
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white38), // lighter border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15), // subtle shadow
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 32),
            const SizedBox(width: 28),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.montserrat(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  iconUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.error, color: Colors.redAccent, size: 72),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  condition,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Column(
            children: [
              _rectInfoCard(
                  'Max Temp', '${maxTemp.toInt()}°', Icons.thermostat_outlined),
              _rectInfoCard(
                  'Min Temp', '${minTemp.toInt()}°', Icons.ac_unit_outlined),
              _rectInfoCard('Humidity', '$avgHumidity%', Icons.opacity),
              _rectInfoCard(
                  'Rain Chance', '$chanceOfRain%', Icons.umbrella_outlined),
              _rectInfoCard('Sunrise', sunrise, Icons.wb_sunny_outlined),
              _rectInfoCard('Sunset', sunset, Icons.nightlight_round),
            ],
          ),
        ],
      ),
    );
  }
}