import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotificationCategory {
  critical,
  ai,
  actuator,
  reminder,
}

class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationCategory category;
  bool isRead;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.category,
    this.isRead = false,
  });
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  final List<AppNotificationItem> _notifications = [];

  List<AppNotificationItem> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Request notification permission for Android 13+
      final androidPlatform = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.requestNotificationsPermission();
      }

      _isInitialized = true;
      _seedDefaultNotifications();
    } catch (e) {
      debugPrint('Failed to initialize local notifications: $e');
    }
  }

  void _seedDefaultNotifications() {
    if (_notifications.isNotEmpty) return;
    final now = DateTime.now();
    _notifications.addAll([
      AppNotificationItem(
        id: '1',
        title: '🌱 AI: Rekomendasi Pemupukan Siap',
        body: 'Model F-03 merekomendasikan pupuk NPK 16-16-16 (120 kg/ha) untuk fase vegetatif Zona A.',
        timestamp: now.subtract(const Duration(minutes: 25)),
        category: NotificationCategory.ai,
        isRead: false,
      ),
      AppNotificationItem(
        id: '2',
        title: '🚿 Pompa Irigasi Selesai',
        body: 'Penyiraman otomatis Zona B telah selesai (durasi 15 menit, debit 30 liter). Kelembaban kini 68%.',
        timestamp: now.subtract(const Duration(hours: 2)),
        category: NotificationCategory.actuator,
        isRead: false,
      ),
      AppNotificationItem(
        id: '3',
        title: '⛈️ Proteksi Hujan Aktif',
        body: 'Sensor hujan mendeteksi presipitasi di lahan Bogor. Penyiraman otomatis ditahan sementara demi efisiensi.',
        timestamp: now.subtract(const Duration(hours: 5)),
        category: NotificationCategory.critical,
        isRead: true,
      ),
    ]);
  }

  /// Menampilkan push notification langsung ke HP (Android Status Bar)
  Future<void> showPhoneNotification({
    required String title,
    required String body,
    required NotificationCategory category,
    String? payload,
  }) async {
    // 1. Simpan di riwayat aplikasi
    final item = AppNotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      category: category,
      isRead: false,
    );
    _notifications.insert(0, item);
    notifyListeners();

    // 2. Tampilkan di sistem HP
    String channelId;
    String channelName;
    Importance importance;
    Priority priority;

    switch (category) {
      case NotificationCategory.critical:
        channelId = 'jagatani_alerts';
        channelName = 'Peringatan Darurat Lahan';
        importance = Importance.max;
        priority = Priority.high;
        break;
      case NotificationCategory.ai:
        channelId = 'jagatani_ai';
        channelName = 'Rekomendasi Cerdas AI';
        importance = Importance.high;
        priority = Priority.high;
        break;
      case NotificationCategory.actuator:
        channelId = 'jagatani_actuator';
        channelName = 'Status Pompa & Irigasi';
        importance = Importance.defaultImportance;
        priority = Priority.defaultPriority;
        break;
      case NotificationCategory.reminder:
        channelId = 'jagatani_reminders';
        channelName = 'Pengingat Rutin';
        importance = Importance.low;
        priority = Priority.low;
        break;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: priority,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      await _localNotifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing phone notification: $e');
    }
  }

  /// Kirim tes notifikasi instan ke HP petani
  Future<void> sendTestNotification() async {
    await showPhoneNotification(
      title: '🚨 Peringatan Lahan: Tanah Mulai Kering!',
      body: 'Kelembaban tanah terdeteksi 38% di Zona A (Bogor). Sistem merekomendasikan irigasi 15 menit.',
      category: NotificationCategory.critical,
    );
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
