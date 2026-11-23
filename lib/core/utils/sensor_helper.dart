import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jaga_tani/core/constants/app_constants.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';

/// Represents the health/status level of a sensor reading.
enum SensorStatus {
  /// Value is within optimal range — no action needed.
  optimal,

  /// Value is approaching a threshold — attention recommended.
  warning,

  /// Value is outside safe range — immediate action required.
  critical,
}

/// Utility class for evaluating and displaying sensor data statuses.
class SensorHelper {
  SensorHelper._(); // Prevent instantiation

  // ─────────────────────────── Status Evaluators ───────────────────────────

  /// Returns the [SensorStatus] for a given soil humidity percentage value.
  static SensorStatus getSoilHumidityStatus(double value) {
    if (value >= AppConstants.soilHumidityMin &&
        value <= AppConstants.soilHumidityMax) {
      return SensorStatus.optimal;
    } else if (value >= AppConstants.soilHumidityMin - 10 &&
        value <= AppConstants.soilHumidityMax + 10) {
      return SensorStatus.warning;
    }
    return SensorStatus.critical;
  }

  /// Returns the [SensorStatus] for a given temperature value in °C.
  static SensorStatus getTemperatureStatus(double value) {
    if (value >= AppConstants.tempMin && value <= AppConstants.tempMax) {
      return SensorStatus.optimal;
    } else if (value >= AppConstants.tempMin - 5 &&
        value <= AppConstants.tempMax + 5) {
      return SensorStatus.warning;
    }
    return SensorStatus.critical;
  }

  /// Returns the [SensorStatus] for a given soil pH value.
  static SensorStatus getPhStatus(double value) {
    if (value >= AppConstants.phMin && value <= AppConstants.phMax) {
      return SensorStatus.optimal;
    } else if (value >= AppConstants.phMin - 0.5 &&
        value <= AppConstants.phMax + 0.5) {
      return SensorStatus.warning;
    }
    return SensorStatus.critical;
  }

  /// Returns the [SensorStatus] for a given air humidity percentage value.
  static SensorStatus getAirHumidityStatus(double value) {
    if (value >= AppConstants.airHumidityMin &&
        value <= AppConstants.airHumidityMax) {
      return SensorStatus.optimal;
    } else if (value >= AppConstants.airHumidityMin - 10 &&
        value <= AppConstants.airHumidityMax + 10) {
      return SensorStatus.warning;
    }
    return SensorStatus.critical;
  }

  // ──────────────────────────── Display Helpers ────────────────────────────

  /// Returns the display [Color] corresponding to a [SensorStatus].
  static Color getStatusColor(SensorStatus status) {
    switch (status) {
      case SensorStatus.optimal:
        return AppColors.success;
      case SensorStatus.warning:
        return AppColors.warning;
      case SensorStatus.critical:
        return AppColors.danger;
    }
  }

  /// Returns the Bahasa Indonesia label for a [SensorStatus].
  static String getStatusLabel(SensorStatus status) {
    switch (status) {
      case SensorStatus.optimal:
        return 'Optimal';
      case SensorStatus.warning:
        return 'Perhatian';
      case SensorStatus.critical:
        return 'Kritis';
    }
  }

  /// Alias for [getStatusLabel].
  static String statusLabel(SensorStatus status) => getStatusLabel(status);

  /// Returns the representative [IconData] for a [SensorStatus].
  static IconData getStatusIcon(SensorStatus status) {
    switch (status) {
      case SensorStatus.optimal:
        return Iconsax.tick_circle5;
      case SensorStatus.warning:
        return Iconsax.warning_25;
      case SensorStatus.critical:
        return Iconsax.close_circle5;
    }
  }

  // ──────────────────────────── Score Calculator ───────────────────────────

  /// Computes an overall health score (0–100) from a list of sensor statuses.
  ///
  /// Each [SensorStatus.optimal] contributes full weight, [SensorStatus.warning]
  /// contributes half weight, and [SensorStatus.critical] contributes no weight.
  ///
  /// [values] and [statuses] must have the same length.
  static double getOverallScore(
    List<double> values,
    List<SensorStatus> statuses,
  ) {
    if (statuses.isEmpty) return 0;

    double totalScore = 0;
    for (final status in statuses) {
      switch (status) {
        case SensorStatus.optimal:
          totalScore += 100;
          break;
        case SensorStatus.warning:
          totalScore += 50;
          break;
        case SensorStatus.critical:
          totalScore += 0;
          break;
      }
    }

    return totalScore / statuses.length;
  }

  // ─────────────────────────── Convenience Getters ─────────────────────────

  /// Returns a human-readable percentage range string for soil humidity.
  static String get soilHumidityRange =>
      '${AppConstants.soilHumidityMin.toInt()}–${AppConstants.soilHumidityMax.toInt()}%';

  /// Returns a human-readable range string for temperature.
  static String get temperatureRange =>
      '${AppConstants.tempMin.toInt()}–${AppConstants.tempMax.toInt()}°C';

  /// Returns a human-readable range string for pH.
  static String get phRange =>
      '${AppConstants.phMin}–${AppConstants.phMax}';

  /// Returns a human-readable range string for air humidity.
  static String get airHumidityRange =>
      '${AppConstants.airHumidityMin.toInt()}–${AppConstants.airHumidityMax.toInt()}%';
}
