import 'package:flutter/material.dart';
import 'package:jaga_tani/data/models/sensor_data.dart';

/// Controls how the irrigation pump is triggered for a zone.
enum PumpMode {
  /// Pump activates automatically based on sensor thresholds.
  auto,

  /// Pump follows a predefined timed schedule.
  schedule,

  /// Pump is controlled entirely by the farmer manually.
  manual,
}

/// Represents a distinct irrigation/monitoring zone on the farm.
class FieldZone {
  /// Unique identifier for this zone.
  final String id;

  /// Human-readable name, e.g. "Zona A".
  final String name;

  /// Area of this zone in hectares (Ha).
  final double area;

  /// Type of crop grown in this zone, e.g. "Padi".
  final String cropType;

  /// Color used to visually represent this zone on maps/charts.
  final Color zoneColor;

  /// The list of sensor readings associated with this zone.
  final List<SensorData> sensors;

  /// Whether the irrigation pump in this zone is currently running.
  final bool isIrrigating;

  /// The current irrigation control mode for this zone.
  final PumpMode pumpMode;

  /// Optional list of irrigation schedules set for this zone.
  final List<IrrigationSchedule> schedules;

  const FieldZone({
    required this.id,
    required this.name,
    required this.area,
    required this.cropType,
    required this.zoneColor,
    required this.sensors,
    required this.isIrrigating,
    required this.pumpMode,
    this.schedules = const [],
  });

  // ──────────────────────────── copyWith ───────────────────────────────────

  FieldZone copyWith({
    String? id,
    String? name,
    double? area,
    String? cropType,
    Color? zoneColor,
    List<SensorData>? sensors,
    bool? isIrrigating,
    PumpMode? pumpMode,
    List<IrrigationSchedule>? schedules,
  }) {
    return FieldZone(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      cropType: cropType ?? this.cropType,
      zoneColor: zoneColor ?? this.zoneColor,
      sensors: sensors ?? this.sensors,
      isIrrigating: isIrrigating ?? this.isIrrigating,
      pumpMode: pumpMode ?? this.pumpMode,
      schedules: schedules ?? this.schedules,
    );
  }

  // ─────────────────────────── Convenience ─────────────────────────────────

  /// Returns the most recent sensor reading, or null if [sensors] is empty.
  SensorData? get latestSensor =>
      sensors.isNotEmpty ? sensors.last : null;

  /// Returns the formatted area string, e.g. "1.5 Ha".
  String get areaFormatted => '${area.toStringAsFixed(1)} Ha';

  /// Returns the Bahasa Indonesia pump mode label.
  String get pumpModeLabel {
    switch (pumpMode) {
      case PumpMode.auto:
        return 'Otomatis';
      case PumpMode.schedule:
        return 'Jadwal';
      case PumpMode.manual:
        return 'Manual';
    }
  }

  /// Returns the irrigation status label in Bahasa Indonesia.
  String get irrigationStatusLabel => isIrrigating ? 'Menyiram' : 'Standby';

  @override
  String toString() =>
      'FieldZone(id: $id, name: $name, crop: $cropType, area: ${areaFormatted}, '
      'irrigating: $isIrrigating, mode: ${pumpMode.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldZone && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Defines a recurring irrigation schedule for a [FieldZone].
class IrrigationSchedule {
  /// Unique identifier for this schedule entry.
  final String id;

  /// The [FieldZone.id] this schedule belongs to.
  final String zoneId;

  /// Day of week: 1 = Monday … 7 = Sunday (ISO 8601).
  final int dayOfWeek;

  /// The time of day when irrigation starts.
  final TimeOfDay startTime;

  /// The time of day when irrigation ends.
  final TimeOfDay endTime;

  /// Total duration of the irrigation session in minutes.
  final int durationMinutes;

  /// Whether this schedule is currently enabled.
  final bool isActive;

  const IrrigationSchedule({
    required this.id,
    required this.zoneId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.isActive,
  });

  // ──────────────────────────── copyWith ───────────────────────────────────

  IrrigationSchedule copyWith({
    String? id,
    String? zoneId,
    int? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? durationMinutes,
    bool? isActive,
  }) {
    return IrrigationSchedule(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
    );
  }

  // ─────────────────────────── Display Helpers ─────────────────────────────

  /// Returns the Indonesian day name for [dayOfWeek].
  String get dayName {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final index = (dayOfWeek - 1).clamp(0, 6);
    return days[index];
  }

  /// Returns the start time formatted as HH:MM.
  String get startTimeFormatted =>
      '${startTime.hour.toString().padLeft(2, '0')}:'
      '${startTime.minute.toString().padLeft(2, '0')}';

  /// Returns the end time formatted as HH:MM.
  String get endTimeFormatted =>
      '${endTime.hour.toString().padLeft(2, '0')}:'
      '${endTime.minute.toString().padLeft(2, '0')}';

  /// Returns a readable time range string, e.g. "06:00 – 06:30".
  String get timeRangeFormatted => '$startTimeFormatted – $endTimeFormatted';

  /// Returns a readable duration string, e.g. "30 menit".
  String get durationFormatted => '$durationMinutes menit';

  @override
  String toString() =>
      'IrrigationSchedule(id: $id, zone: $zoneId, day: $dayName, '
      'time: $timeRangeFormatted, duration: $durationFormatted, active: $isActive)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IrrigationSchedule &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
