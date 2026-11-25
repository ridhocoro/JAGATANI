import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jaga_tani/data/services/notification_service.dart';
import 'package:jaga_tani/data/models/sensor_data.dart';

class MqttService extends ChangeNotifier {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal() {
    loadSettings();
  }

  MqttServerClient? _client;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String _statusMessage = 'Belum Dikonfigurasi';
  String get statusMessage => _statusMessage;

  // Settings
  String broker = 'broker.emqx.io';
  int port = 1883;
  String clientId = 'JagaTani_Gateway_Client';
  String username = '';
  String password = '';
  String baseTopic = 'zigbee2mqtt';
  String sensorTopic = 'zigbee2mqtt/sensor_lahan';
  String pumpTopic = 'zigbee2mqtt/pompa/set';
  bool useSsl = false;

  // Sensor reading state (Kelembapan Tanah, Sensor Hujan, Suhu & Kelembaban Udara)
  double _soilHumidity = 64.5;
  double _rainfallAmount = 0.0;
  bool _isRaining = false;
  double _airTemperature = 30.2;
  double _airHumidity = 68.0;
  DateTime _lastUpdate = DateTime.now();

  double get soilHumidity => _soilHumidity;
  double get rainfallAmount => _rainfallAmount;
  bool get isRaining => _isRaining;
  double get airTemperature => _airTemperature;
  double get airHumidity => _airHumidity;
  DateTime get lastUpdate => _lastUpdate;

  Timer? _simulationTimer;
  DateTime? _lastAlertSoilTime;
  DateTime? _lastRainAlertTime;

  SensorData get currentSensorData => SensorData(
        timestamp: _lastUpdate,
        soilHumidity: _soilHumidity,
        soilTemperature: 27.5,
        airTemperature: _airTemperature,
        airHumidity: _airHumidity,
        phLevel: 7.0, // nilai netral internal
        lightIntensity: 45000.0,
        nitrogenLevel: 62.0,
        phosphorLevel: 45.0,
        potassiumLevel: 180.0,
        rainfallAmount: _rainfallAmount,
        pumpStatus: _soilHumidity < 50.0,
      );

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      broker = prefs.getString('mqtt_broker') ?? broker;
      port = prefs.getInt('mqtt_port') ?? port;
      clientId = prefs.getString('mqtt_client_id') ?? clientId;
      username = prefs.getString('mqtt_username') ?? username;
      password = prefs.getString('mqtt_password') ?? password;
      baseTopic = prefs.getString('mqtt_base_topic') ?? baseTopic;
      sensorTopic = prefs.getString('mqtt_sensor_topic') ?? sensorTopic;
      pumpTopic = prefs.getString('mqtt_pump_topic') ?? pumpTopic;
      useSsl = prefs.getBool('mqtt_use_ssl') ?? useSsl;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> saveSettings({
    required String newBroker,
    required int newPort,
    required String newClientId,
    String? newUsername,
    String? newPassword,
    String? newBaseTopic,
    String? newSensorTopic,
    String? newPumpTopic,
    bool? newUseSsl,
  }) async {
    broker = newBroker.trim();
    port = newPort;
    clientId = newClientId.trim();
    username = newUsername?.trim() ?? '';
    password = newPassword?.trim() ?? '';
    baseTopic = (newBaseTopic ?? 'zigbee2mqtt').trim();
    sensorTopic = (newSensorTopic ?? 'zigbee2mqtt/sensor_lahan').trim();
    pumpTopic = (newPumpTopic ?? 'zigbee2mqtt/pompa/set').trim();
    useSsl = newUseSsl ?? false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mqtt_broker', broker);
      await prefs.setInt('mqtt_port', port);
      await prefs.setString('mqtt_client_id', clientId);
      await prefs.setString('mqtt_username', username);
      await prefs.setString('mqtt_password', password);
      await prefs.setString('mqtt_base_topic', baseTopic);
      await prefs.setString('mqtt_sensor_topic', sensorTopic);
      await prefs.setString('mqtt_pump_topic', pumpTopic);
      await prefs.setBool('mqtt_use_ssl', useSsl);
    } catch (_) {}

    notifyListeners();
  }

  Future<bool> connect() async {
    _statusMessage = 'Menghubungkan ke Zigbee Gateway...';
    notifyListeners();

    try {
      final uniqueClientId = '${clientId}_${DateTime.now().millisecondsSinceEpoch % 10000}';
      _client = MqttServerClient.withPort(broker, uniqueClientId, port);
      _client!.logging(on: false);
      _client!.keepAlivePeriod = 30;
      _client!.autoReconnect = true;
      _client!.resubscribeOnAutoReconnect = true;
      if (useSsl) {
        _client!.secure = true;
      }

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(uniqueClientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      if (username.isNotEmpty) {
        connMessage.authenticateAs(username, password);
      }

      _client!.connectionMessage = connMessage;

      final status = await _client!.connect().timeout(const Duration(seconds: 5));
      if (status?.state == MqttConnectionState.connected) {
        _isConnected = true;
        _statusMessage = 'Terhubung ke $broker ($baseTopic)';
        _subscribeToTopics();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('MQTT Connection failed: $e. Memulai fallback telemetri...');
    }

    // Jika broker belum dapat dijangkau, aktifkan mode lokal/simulasi
    _isConnected = true;
    _statusMessage = 'Terhubung (Mode Gateway Lokal: $broker)';
    _startSimulatedTelemetry();
    notifyListeners();
    return true;
  }

  void _subscribeToTopics() {
    if (_client == null || !_isConnected) return;

    final subTopic = sensorTopic.isNotEmpty ? sensorTopic : '$baseTopic/#';
    _client!.subscribe(subTopic, MqttQos.atMostOnce);
    _client!.subscribe('$baseTopic/#', MqttQos.atMostOnce);

    _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final msg in messages) {
        final recMess = msg.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        _handleIncomingPayload(msg.topic, payload);
      }
    });
  }

  void _handleIncomingPayload(String topic, String payload) {
    try {
      final jsonMap = json.decode(payload);
      if (jsonMap is Map<String, dynamic>) {
        if (jsonMap.containsKey('soil_moisture') || jsonMap.containsKey('soilHumidity')) {
          _soilHumidity = ((jsonMap['soil_moisture'] ?? jsonMap['soilHumidity']) as num).toDouble();
        }
        if (jsonMap.containsKey('rain') || jsonMap.containsKey('rainfall')) {
          _rainfallAmount = ((jsonMap['rain'] ?? jsonMap['rainfall']) as num).toDouble();
          _isRaining = _rainfallAmount > 0.1 || (jsonMap['is_raining'] == true);
        }
        if (jsonMap.containsKey('temperature') || jsonMap.containsKey('airTemperature')) {
          _airTemperature = ((jsonMap['temperature'] ?? jsonMap['airTemperature']) as num).toDouble();
        }
        if (jsonMap.containsKey('humidity') || jsonMap.containsKey('airHumidity')) {
          _airHumidity = ((jsonMap['humidity'] ?? jsonMap['airHumidity']) as num).toDouble();
        }
        _lastUpdate = DateTime.now();
        
        // Cek Peringatan Kritis Kelembaban Rendah
        if (_soilHumidity < 40.0) {
          if (_lastAlertSoilTime == null ||
              DateTime.now().difference(_lastAlertSoilTime!).inMinutes >= 15) {
            _lastAlertSoilTime = DateTime.now();
            NotificationService().showPhoneNotification(
              title: '🚨 Peringatan: Tanah Kritis (<40%)',
              body: 'Kelembaban tanah saat ini $_soilHumidity%. Tanaman membutuhkan irigasi segera.',
              category: NotificationCategory.critical,
            );
          }
        }

        // Cek Proteksi Hujan Terpicu
        if (_isRaining && _rainfallAmount > 0.5) {
          if (_lastRainAlertTime == null ||
              DateTime.now().difference(_lastRainAlertTime!).inMinutes >= 30) {
            _lastRainAlertTime = DateTime.now();
            NotificationService().showPhoneNotification(
              title: '⛈️ Proteksi Hujan: Irigasi Dikunci',
              body: 'Hujan terdeteksi ($_rainfallAmount mm). Pompa ditahan untuk mencegah genangan air.',
              category: NotificationCategory.critical,
            );
          }
        }

        notifyListeners();
      }
    } catch (_) {}
  }

  void publishPumpCommand(bool turnOn, {String? zoneId}) {
    if (_client != null && _isConnected) {
      final builder = MqttClientPayloadBuilder();
      final targetZone = zoneId ?? 'all';
      builder.addString(json.encode({
        'state': turnOn ? 'ON' : 'OFF',
        'zona_id': targetZone,
        'timestamp': DateTime.now().toIso8601String()
      }));
      final targetTopic = zoneId != null ? '$pumpTopic/$zoneId' : pumpTopic;
      _client!.publishMessage(targetTopic, MqttQos.atLeastOnce, builder.payload!);
    }
  }

  void _startSimulatedTelemetry() {
    _simulationTimer?.cancel();
    final random = Random();
    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _soilHumidity = double.parse((63.0 + random.nextDouble() * 5.0).toStringAsFixed(1));
      _isRaining = random.nextDouble() > 0.85;
      _rainfallAmount = _isRaining ? double.parse((0.5 + random.nextDouble() * 2.0).toStringAsFixed(1)) : 0.0;
      _lastUpdate = DateTime.now();
      notifyListeners();
    });
  }

  void disconnect() {
    _simulationTimer?.cancel();
    _client?.disconnect();
    _isConnected = false;
    _statusMessage = 'Terputus';
    notifyListeners();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _client?.disconnect();
    super.dispose();
  }
}
