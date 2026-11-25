import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';
import 'package:jaga_tani/data/services/mqtt_service.dart';

class ZigbeeMqttConfigScreen extends StatefulWidget {
  const ZigbeeMqttConfigScreen({super.key});

  @override
  State<ZigbeeMqttConfigScreen> createState() => _ZigbeeMqttConfigScreenState();
}

class _ZigbeeMqttConfigScreenState extends State<ZigbeeMqttConfigScreen> {
  final _mqtt = MqttService();

  late final TextEditingController _brokerController;
  late final TextEditingController _portController;
  late final TextEditingController _clientIdController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _baseTopicController;
  late final TextEditingController _sensorTopicController;
  late final TextEditingController _pumpTopicController;
  bool _useSsl = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _brokerController = TextEditingController(text: _mqtt.broker);
    _portController = TextEditingController(text: _mqtt.port.toString());
    _clientIdController = TextEditingController(text: _mqtt.clientId);
    _usernameController = TextEditingController(text: _mqtt.username);
    _passwordController = TextEditingController(text: _mqtt.password);
    _baseTopicController = TextEditingController(text: _mqtt.baseTopic);
    _sensorTopicController = TextEditingController(text: _mqtt.sensorTopic);
    _pumpTopicController = TextEditingController(text: _mqtt.pumpTopic);
    _useSsl = _mqtt.useSsl;
  }

  @override
  void dispose() {
    _brokerController.dispose();
    _portController.dispose();
    _clientIdController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _baseTopicController.dispose();
    _sensorTopicController.dispose();
    _pumpTopicController.dispose();
    super.dispose();
  }

  void _applyDefaultCloud() {
    setState(() {
      _brokerController.text = 'broker.emqx.io';
      _portController.text = '1883';
      _baseTopicController.text = 'zigbee2mqtt';
      _sensorTopicController.text = 'zigbee2mqtt/sensor_lahan';
      _pumpTopicController.text = 'zigbee2mqtt/pompa/set';
      _useSsl = false;
    });
  }

  void _applyLocalGateway() {
    setState(() {
      _brokerController.text = '192.168.1.100';
      _portController.text = '1883';
      _baseTopicController.text = 'zigbee2mqtt';
      _sensorTopicController.text = 'zigbee2mqtt/sensor_lahan';
      _pumpTopicController.text = 'zigbee2mqtt/pompa/set';
      _useSsl = false;
    });
  }

  Future<void> _saveAndConnect() async {
    setState(() => _isLoading = true);

    final port = int.tryParse(_portController.text.trim()) ?? 1883;
    await _mqtt.saveSettings(
      newBroker: _brokerController.text,
      newPort: port,
      newClientId: _clientIdController.text,
      newUsername: _usernameController.text,
      newPassword: _passwordController.text,
      newBaseTopic: _baseTopicController.text,
      newSensorTopic: _sensorTopicController.text,
      newPumpTopic: _pumpTopicController.text,
      newUseSsl: _useSsl,
    );

    await _mqtt.connect();

    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                border: Border(bottom: BorderSide(color: Colors.black, width: 2.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text('📡', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GATEWAY ZIGBEE MQTT',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Konfigurasi alamat sensor kebun',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Presets Bar
                    Text(
                      'PRESET CEPAT',
                      style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _applyDefaultCloud,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF9C3),
                                border: Border.all(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '☁️ Cloud (EMQX)',
                                  style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _applyLocalGateway,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                border: Border.all(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '🏠 Gateway Lokal',
                                  style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Section 1: Broker
                    _buildSectionHeader('1. KONEKSI BROKER MQTT', '🌐'),
                    const SizedBox(height: 8),

                    _buildLabel('Broker Host / IP Gateway'),
                    _buildTextField(_brokerController, 'contoh: broker.emqx.io atau 192.168.1.100'),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Port'),
                              _buildTextField(_portController, '1883', keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Client ID'),
                              _buildTextField(_clientIdController, 'ID Unik Klien'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Username (Opsional)'),
                              _buildTextField(_usernameController, 'user'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Password (Opsional)'),
                              _buildTextField(_passwordController, '••••••', obscureText: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Section 2: Topik Zigbee
                    _buildSectionHeader('2. TOPIK ZIGBEE TELEMETRI', '📡'),
                    const SizedBox(height: 8),

                    _buildLabel('Base Topic Zigbee'),
                    _buildTextField(_baseTopicController, 'zigbee2mqtt'),
                    const SizedBox(height: 12),

                    _buildLabel('Topik Sensor Kelembaban & Hujan'),
                    _buildTextField(_sensorTopicController, 'zigbee2mqtt/sensor_lahan'),
                    const SizedBox(height: 12),

                    _buildLabel('Topik Perintah Pompa Irigasi'),
                    _buildTextField(_pumpTopicController, 'zigbee2mqtt/pompa/set'),
                    const SizedBox(height: 24),

                    // Action Button
                    GestureDetector(
                      onTap: _isLoading ? null : _saveAndConnect,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          border: Border.all(color: Colors.black, width: 2.5),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                                )
                              : Text(
                                  'SIMPAN & BUKA DASHBOARD →',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          filled: false,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          hintText: hint,
          hintStyle: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
