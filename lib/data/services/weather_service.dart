import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final int humidity;
  final double precipitation;
  final double windSpeed;
  final int weatherCode;
  final String description;
  final String emoji;
  final DateTime updatedAt;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.precipitation,
    required this.windSpeed,
    required this.weatherCode,
    required this.description,
    required this.emoji,
    required this.updatedAt,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 30.0;
    final hum = (current['relative_humidity_2m'] as num?)?.toInt() ?? 70;
    final precip = (current['precipitation'] as num?)?.toDouble() ?? 0.0;
    final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 10.0;
    final code = (current['weather_code'] as num?)?.toInt() ?? 0;

    final info = _mapWeatherCode(code);

    return WeatherData(
      temperature: temp,
      humidity: hum,
      precipitation: precip,
      windSpeed: wind,
      weatherCode: code,
      description: info.$1,
      emoji: info.$2,
      updatedAt: DateTime.now(),
    );
  }

  static (String, String) _mapWeatherCode(int code) {
    switch (code) {
      case 0:
        return ('Cerah', '☀️');
      case 1:
      case 2:
        return ('Cerah Berawan', '🌤️');
      case 3:
        return ('Berawan', '☁️');
      case 45:
      case 48:
        return ('Berkabut', '🌫️');
      case 51:
      case 53:
      case 55:
        return ('Gerimis', '🌦️');
      case 61:
      case 63:
      case 65:
        return ('Hujan', '🌧️');
      case 80:
      case 81:
      case 82:
        return ('Hujan Deras', '🌧️');
      case 95:
      case 96:
      case 99:
        return ('Badai Petir', '⛈️');
      default:
        return ('Sebagian Berawan', '⛅');
    }
  }

  static WeatherData defaultData() {
    return WeatherData(
      temperature: 29.5,
      humidity: 72,
      precipitation: 0.0,
      windSpeed: 11.2,
      weatherCode: 1,
      description: 'Cerah Berawan',
      emoji: '🌤️',
      updatedAt: DateTime.now(),
    );
  }
}

class WeatherService {
  // Default koordinat lahan pertanian (misal: Jawa Barat / Lahan Sawah Indonesia)
  static const double defaultLat = -6.5971; // Bogor / Sawah sekitar
  static const double defaultLng = 106.8060;

  static Future<WeatherData> fetchCurrentWeather({
    double lat = defaultLat,
    double lng = defaultLng,
  }) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current=temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m&timezone=Asia%2FJakarta',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      }
    } catch (_) {
      // Fallback data jika offline / timeout
    }
    return WeatherData.defaultData();
  }
}
