import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/config/zigbee_mqtt_config_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/monitoring/monitoring_screen.dart';
import 'screens/control/control_screen.dart';
import 'screens/ai/ai_hub_screen.dart';
import 'screens/ai/ai_recommendation_screen.dart';
import 'screens/ai/ai_diagnosa_screen.dart';
import 'screens/report/report_screen.dart';
import 'screens/community/community_screen.dart';
import 'screens/profile/profile_screen.dart';

final GoRouter _router = GoRouter(
  initialLocation: AppConstants.routeSplash,
  routes: [
    GoRoute(
      path: AppConstants.routeSplash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppConstants.routeOnboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppConstants.routeConfig,
      builder: (context, state) => const ZigbeeMqttConfigScreen(),
    ),
    GoRoute(
      path: AppConstants.routeRegister,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppConstants.routeDashboard,
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: AppConstants.routeMonitoring,
      builder: (context, state) => const MonitoringScreen(),
    ),
    GoRoute(
      path: AppConstants.routeControl,
      builder: (context, state) => const ControlScreen(),
    ),
    GoRoute(
      path: AppConstants.routeAiHub,
      builder: (context, state) => const AiHubScreen(),
    ),
    GoRoute(
      path: AppConstants.routeAiRecommendation,
      builder: (context, state) => const AiRecommendationScreen(),
    ),
    GoRoute(
      path: AppConstants.routeAiDiagnosa,
      builder: (context, state) => const AiDiagnosaScreen(),
    ),
    GoRoute(
      path: AppConstants.routeReport,
      builder: (context, state) => const ReportScreen(),
    ),
    GoRoute(
      path: AppConstants.routeCommunity,
      builder: (context, state) => const CommunityScreen(),
    ),
    GoRoute(
      path: AppConstants.routeProfile,
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);

class JagaTaniApp extends StatelessWidget {
  const JagaTaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
