/// Represents a single timestamped snapshot of all sensor readings on the farm.
class SensorData {
  /// When this snapshot was recorded.
  final DateTime timestamp;

  /// Soil moisture percentage (0–100%).
  final double soilHumidity;

  /// Soil temperature in degrees Celsius.
  final double soilTemperature;

  /// Ambient air temperature in degrees Celsius.
  final double airTemperature;

  /// Ambient air humidity percentage (0–100%).
  final double airHumidity;

  /// Soil pH level (0–14).
  final double phLevel;

  /// Light intensity in lux.
  final double lightIntensity;

  /// Nitrogen content in soil (mg/kg).
  final double nitrogenLevel;

  /// Phosphorus content in soil (mg/kg).
  final double phosphorLevel;

  /// Potassium content in soil (mg/kg).
  final double potassiumLevel;

  /// Rainfall accumulation in mm.
  final double rainfallAmount;

  /// Whether the irrigation pump is currently active.
  final bool pumpStatus;

  const SensorData({
    required this.timestamp,
    required this.soilHumidity,
    required this.soilTemperature,
    required this.airTemperature,
    required this.airHumidity,
    required this.phLevel,
    required this.lightIntensity,
    required this.nitrogenLevel,
    required this.phosphorLevel,
    required this.potassiumLevel,
    required this.rainfallAmount,
    required this.pumpStatus,
  });

  // ──────────────────────────── copyWith ───────────────────────────────────

  SensorData copyWith({
    DateTime? timestamp,
    double? soilHumidity,
    double? soilTemperature,
    double? airTemperature,
    double? airHumidity,
    double? phLevel,
    double? lightIntensity,
    double? nitrogenLevel,
    double? phosphorLevel,
    double? potassiumLevel,
    double? rainfallAmount,
    bool? pumpStatus,
  }) {
    return SensorData(
      timestamp: timestamp ?? this.timestamp,
      soilHumidity: soilHumidity ?? this.soilHumidity,
      soilTemperature: soilTemperature ?? this.soilTemperature,
      airTemperature: airTemperature ?? this.airTemperature,
      airHumidity: airHumidity ?? this.airHumidity,
      phLevel: phLevel ?? this.phLevel,
      lightIntensity: lightIntensity ?? this.lightIntensity,
      nitrogenLevel: nitrogenLevel ?? this.nitrogenLevel,
      phosphorLevel: phosphorLevel ?? this.phosphorLevel,
      potassiumLevel: potassiumLevel ?? this.potassiumLevel,
      rainfallAmount: rainfallAmount ?? this.rainfallAmount,
      pumpStatus: pumpStatus ?? this.pumpStatus,
    );
  }

  // ──────────────────────────── JSON ───────────────────────────────────────

  /// Serializes this [SensorData] to a JSON-compatible [Map].
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'soilHumidity': soilHumidity,
      'soilTemperature': soilTemperature,
      'airTemperature': airTemperature,
      'airHumidity': airHumidity,
      'phLevel': phLevel,
      'lightIntensity': lightIntensity,
      'nitrogenLevel': nitrogenLevel,
      'phosphorLevel': phosphorLevel,
      'potassiumLevel': potassiumLevel,
      'rainfallAmount': rainfallAmount,
      'pumpStatus': pumpStatus,
    };
  }

  /// Creates a [SensorData] instance from a JSON [Map].
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      timestamp: DateTime.parse(json['timestamp'] as String),
      soilHumidity: (json['soilHumidity'] as num).toDouble(),
      soilTemperature: (json['soilTemperature'] as num).toDouble(),
      airTemperature: (json['airTemperature'] as num).toDouble(),
      airHumidity: (json['airHumidity'] as num).toDouble(),
      phLevel: (json['phLevel'] as num).toDouble(),
      lightIntensity: (json['lightIntensity'] as num).toDouble(),
      nitrogenLevel: (json['nitrogenLevel'] as num).toDouble(),
      phosphorLevel: (json['phosphorLevel'] as num).toDouble(),
      potassiumLevel: (json['potassiumLevel'] as num).toDouble(),
      rainfallAmount: (json['rainfallAmount'] as num).toDouble(),
      pumpStatus: json['pumpStatus'] as bool,
    );
  }

  // ─────────────────────────── Convenience ─────────────────────────────────

  /// Returns the formatted pump status label in Bahasa Indonesia.
  String get pumpStatusLabel => pumpStatus ? 'AKTIF' : 'MATI';

  /// Returns a formatted pH string rounded to one decimal place.
  String get phLevelFormatted => phLevel.toStringAsFixed(1);

  /// Returns the NPK summary as a formatted string.
  String get npkSummary =>
      'N: ${nitrogenLevel.toStringAsFixed(0)} | P: ${phosphorLevel.toStringAsFixed(0)} | K: ${potassiumLevel.toStringAsFixed(0)}';

  @override
  String toString() =>
      'SensorData(timestamp: $timestamp, soilHumidity: $soilHumidity%, '
      'soilTemp: $soilTemperature°C, airTemp: $airTemperature°C, '
      'airHumidity: $airHumidity%, pH: $phLevel, pump: $pumpStatus)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorData &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          soilHumidity == other.soilHumidity &&
          soilTemperature == other.soilTemperature &&
          airTemperature == other.airTemperature &&
          airHumidity == other.airHumidity &&
          phLevel == other.phLevel &&
          lightIntensity == other.lightIntensity &&
          nitrogenLevel == other.nitrogenLevel &&
          phosphorLevel == other.phosphorLevel &&
          potassiumLevel == other.potassiumLevel &&
          rainfallAmount == other.rainfallAmount &&
          pumpStatus == other.pumpStatus;

  @override
  int get hashCode => Object.hash(
        timestamp,
        soilHumidity,
        soilTemperature,
        airTemperature,
        airHumidity,
        phLevel,
        lightIntensity,
        nitrogenLevel,
        phosphorLevel,
        potassiumLevel,
        rainfallAmount,
        pumpStatus,
      );
}
