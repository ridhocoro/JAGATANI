class AppConstants {
  // App Info
  static const String appName = 'Jaga Tani';
  static const String appTagline = 'Tani Cerdas, Panen Melimpah';
  static const String appVersion = '1.0.0';

  // Sensor Thresholds
  static const double soilHumidityMin = 50.0;
  static const double soilHumidityMax = 80.0;
  static const double tempMin = 20.0;
  static const double tempMax = 35.0;
  static const double phMin = 6.0;
  static const double phMax = 7.5;
  static const double airHumidityMin = 60.0;
  static const double airHumidityMax = 90.0;

  // Routes
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeConfig = '/config';
  static const String routeLogin = '/config'; // Menggantikan login dengan konfigurasi Zigbee MQTT
  static const String routeRegister = '/register';
  static const String routeDashboard = '/dashboard';
  static const String routeMonitoring = '/monitoring';
  static const String routeControl = '/control';
  static const String routeAiHub = '/ai';
  static const String routeAiRecommendation = '/ai/recommendation';
  static const String routeAiDiagnosa = '/ai/diagnosa';
  static const String routeReport = '/report';
  static const String routeCommunity = '/community';
  static const String routeProfile = '/profile';
}
