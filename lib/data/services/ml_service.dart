import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jaga_tani/data/models/ml_result_models.dart';

class MlService {
  // Gunakan localhost (untuk Windows desktop / Web) atau 10.0.2.2 (untuk Android Emulator)
  static String baseUrl = 'http://127.0.0.1:8000';
  static const Duration requestTimeout = Duration(seconds: 4);

  // In-memory cache untuk penanganan kondisi offline
  static F01MoisturePredictionResponse? _cachedF01;
  static F02IrrigationDecisionResponse? _cachedF02;
  static F03FertilizerRecommendationResponse? _cachedF03;
  static DateTime? _lastFetchTime;

  static DateTime? get lastFetchTime => _lastFetchTime;

  /// F-01: Prediksi kelembaban tanah 24 jam ke depan
  static Future<F01MoisturePredictionResponse> fetchMoisturePrediction({
    String zonaId = 'zone_a',
  }) async {
    final url = Uri.parse('$baseUrl/prediksi/kelembaban?zona=$zonaId');
    try {
      final response = await http.get(url).timeout(requestTimeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = F01MoisturePredictionResponse.fromJson(data);
        _cachedF01 = result;
        _lastFetchTime = DateTime.now();
        return result;
      }
    } catch (_) {
      // Offline fallback
    }

    if (_cachedF01 != null) {
      return _cachedF01!;
    }
    return F01MoisturePredictionResponse.mockFallback(zonaId);
  }

  /// F-02: Klasifikasi keputusan irigasi
  static Future<F02IrrigationDecisionResponse> fetchIrrigationDecision({
    String zonaId = 'zone_a',
    double? soilHumidity,
    double? airTemp,
    double? airHumidity,
    int? isRain,
  }) async {
    final url = Uri.parse('$baseUrl/keputusan/irigasi');
    final body = {
      'zona_id': zonaId,
      if (soilHumidity != null) 'kelembaban_tanah': soilHumidity,
      if (airTemp != null) 'suhu_udara': airTemp,
      if (airHumidity != null) 'kelembaban_udara': airHumidity,
      if (isRain != null) 'hujan': isRain,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = F02IrrigationDecisionResponse.fromJson(data);
        _cachedF02 = result;
        _lastFetchTime = DateTime.now();
        return result;
      }
    } catch (_) {
      // Offline fallback
    }

    if (_cachedF02 != null) {
      return _cachedF02!;
    }
    return F02IrrigationDecisionResponse.mockFallback(zonaId);
  }

  /// F-03: Rekomendasi pemupukan berbasis Sistem Pakar
  static Future<F03FertilizerRecommendationResponse> fetchFertilizerRecommendation({
    String zonaId = 'zone_a',
    double? manualPh,
    double? manualHumidity,
  }) async {
    var query = 'zona=$zonaId';
    if (manualPh != null) query += '&ph_manual=$manualPh';
    if (manualHumidity != null) query += '&kelembaban_manual=$manualHumidity';

    final url = Uri.parse('$baseUrl/rekomendasi/pemupukan?$query');
    try {
      final response = await http.get(url).timeout(requestTimeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = F03FertilizerRecommendationResponse.fromJson(data);
        _cachedF03 = result;
        _lastFetchTime = DateTime.now();
        return result;
      }
    } catch (_) {
      // Offline fallback
    }

    if (_cachedF03 != null) {
      return _cachedF03!;
    }
    return F03FertilizerRecommendationResponse.mockFallback(zonaId);
  }
}
