import 'package:flutter/material.dart';
import 'package:jaga_tani/data/models/ai_recommendation.dart';
import 'package:jaga_tani/data/models/community_post.dart';
import 'package:jaga_tani/data/models/field_zone.dart';
import 'package:jaga_tani/data/models/sensor_data.dart';

/// Provides static mock data for development and UI prototyping.
///
/// All values are realistic representations of a tropical farm environment.
/// Replace these with live API/database calls in production.
class MockData {
  MockData._(); // Prevent instantiation

  // ──────────────────────────────────────────────────────────────────────────
  // Reference timestamp – all mock history is calculated relative to this.
  // ──────────────────────────────────────────────────────────────────────────

  static final DateTime _now = DateTime(2026, 10, 9, 14, 0, 0);

  // ──────────────────────────────────────────────────────────────────────────
  // CURRENT SENSOR DATA
  // ──────────────────────────────────────────────────────────────────────────

  /// The most recent sensor snapshot from the farm.
  ///
  /// Note: soilHumidity=45.2% is BELOW the optimal 50% threshold,
  /// which should trigger an urgent irrigation recommendation.
  static SensorData get currentSensorData => SensorData(
        timestamp: _now,
        soilHumidity: 45.2,
        soilTemperature: 28.5,
        airTemperature: 31.2,
        airHumidity: 72.0,
        phLevel: 6.3,
        lightIntensity: 42000.0,
        nitrogenLevel: 180.0,
        phosphorLevel: 95.0,
        potassiumLevel: 210.0,
        rainfallAmount: 0.0,
        pumpStatus: false,
      );

  // ──────────────────────────────────────────────────────────────────────────
  // SENSOR HISTORY (last 24 hours, one entry per hour)
  // ──────────────────────────────────────────────────────────────────────────

  /// Hourly sensor history for the past 24 hours.
  ///
  /// Values follow a realistic diurnal pattern:
  /// - Soil humidity decreases gradually through the day.
  /// - Air temperature peaks around midday.
  /// - Light intensity rises and falls with the sun.
  static List<SensorData> get sensorHistory {
    const baseValues = [
      // [soilH, soilT, airT, airH, pH, light, N, P, K, rain]  — hour 0..23
      [58.0, 27.0, 26.5, 78.0, 6.4, 0.0, 182.0, 96.0, 212.0, 0.0],
      [57.5, 26.8, 26.2, 79.0, 6.4, 0.0, 182.0, 96.0, 212.0, 0.0],
      [57.0, 26.5, 25.8, 80.0, 6.4, 0.0, 181.0, 95.5, 211.0, 0.0],
      [56.5, 26.3, 25.5, 80.5, 6.3, 0.0, 181.0, 95.5, 211.0, 0.0],
      [56.0, 26.0, 25.2, 81.0, 6.3, 0.0, 181.0, 95.0, 211.0, 0.0],
      [55.5, 25.8, 24.8, 81.5, 6.3, 500.0, 180.5, 95.0, 210.5, 0.0],
      [55.0, 26.0, 25.5, 80.0, 6.3, 3500.0, 180.5, 95.0, 210.5, 0.0],
      [54.5, 26.5, 27.0, 77.0, 6.3, 12000.0, 180.0, 95.0, 210.0, 0.0],
      [54.0, 27.0, 28.5, 74.0, 6.3, 22000.0, 180.0, 95.0, 210.0, 0.0],
      [53.5, 27.5, 29.8, 72.0, 6.3, 31000.0, 180.0, 95.0, 210.0, 0.0],
      [53.0, 28.0, 30.5, 70.0, 6.3, 38000.0, 180.0, 95.0, 210.0, 0.0],
      [52.0, 28.5, 31.0, 70.0, 6.3, 42000.0, 180.0, 95.0, 210.0, 0.0],
      [51.0, 29.0, 31.5, 69.0, 6.3, 45000.0, 180.0, 95.0, 210.0, 0.0],
      [50.0, 29.0, 32.0, 68.0, 6.3, 46000.0, 180.0, 95.0, 210.0, 0.0],
      [49.5, 28.8, 32.0, 68.5, 6.3, 44000.0, 180.0, 95.0, 210.0, 0.0],
      [49.0, 28.5, 31.8, 69.0, 6.3, 40000.0, 180.0, 95.0, 210.0, 0.0],
      [48.5, 28.5, 31.5, 70.0, 6.3, 35000.0, 180.0, 95.0, 210.0, 0.0],
      [48.0, 28.5, 31.2, 71.0, 6.3, 28000.0, 180.0, 95.0, 210.0, 0.0],
      [47.5, 28.5, 30.5, 72.0, 6.3, 18000.0, 180.0, 95.0, 210.0, 0.0],
      [47.0, 28.5, 29.8, 72.5, 6.3, 8000.0, 180.0, 95.0, 210.0, 0.0],
      [46.5, 28.5, 29.0, 72.0, 6.3, 1500.0, 180.0, 95.0, 210.0, 0.0],
      [46.0, 28.5, 28.2, 72.0, 6.3, 0.0, 180.0, 95.0, 210.0, 0.0],
      [45.5, 28.5, 27.5, 72.0, 6.3, 0.0, 180.0, 95.0, 210.0, 0.0],
      [45.2, 28.5, 31.2, 72.0, 6.3, 42000.0, 180.0, 95.0, 210.0, 0.0],
    ];

    return List.generate(24, (i) {
      final row = baseValues[i];
      final hourOffset = 23 - i; // entry 0 = 23h ago, entry 23 = now
      return SensorData(
        timestamp: _now.subtract(Duration(hours: hourOffset)),
        soilHumidity: row[0],
        soilTemperature: row[1],
        airTemperature: row[2],
        airHumidity: row[3],
        phLevel: row[4],
        lightIntensity: row[5],
        nitrogenLevel: row[6],
        phosphorLevel: row[7],
        potassiumLevel: row[8],
        rainfallAmount: row[9],
        pumpStatus: false,
      );
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FIELD ZONES
  // ──────────────────────────────────────────────────────────────────────────

  /// Three farm zones with distinct crops, sizes, and operational states.
  static List<FieldZone> get fieldZones => [
        FieldZone(
          id: 'zone_a',
          name: 'Zona A',
          area: 1.5,
          cropType: 'Padi',
          zoneColor: const Color(0xFF1A4D2E),
          sensors: [currentSensorData],
          isIrrigating: false,
          pumpMode: PumpMode.auto,
          schedules: [
            IrrigationSchedule(
              id: 'sched_a1',
              zoneId: 'zone_a',
              dayOfWeek: 1, // Senin
              startTime: const TimeOfDay(hour: 6, minute: 0),
              endTime: const TimeOfDay(hour: 6, minute: 30),
              durationMinutes: 30,
              isActive: true,
            ),
            IrrigationSchedule(
              id: 'sched_a2',
              zoneId: 'zone_a',
              dayOfWeek: 4, // Kamis
              startTime: const TimeOfDay(hour: 6, minute: 0),
              endTime: const TimeOfDay(hour: 6, minute: 30),
              durationMinutes: 30,
              isActive: true,
            ),
          ],
        ),
        FieldZone(
          id: 'zone_b',
          name: 'Zona B',
          area: 0.8,
          cropType: 'Jagung',
          zoneColor: const Color(0xFFFFD600),
          sensors: [
            SensorData(
              timestamp: _now,
              soilHumidity: 62.5,
              soilTemperature: 29.0,
              airTemperature: 31.2,
              airHumidity: 70.0,
              phLevel: 6.8,
              lightIntensity: 43000.0,
              nitrogenLevel: 165.0,
              phosphorLevel: 88.0,
              potassiumLevel: 195.0,
              rainfallAmount: 0.0,
              pumpStatus: true,
            ),
          ],
          isIrrigating: true,
          pumpMode: PumpMode.schedule,
          schedules: [
            IrrigationSchedule(
              id: 'sched_b1',
              zoneId: 'zone_b',
              dayOfWeek: 2, // Selasa
              startTime: const TimeOfDay(hour: 7, minute: 0),
              endTime: const TimeOfDay(hour: 7, minute: 20),
              durationMinutes: 20,
              isActive: true,
            ),
            IrrigationSchedule(
              id: 'sched_b2',
              zoneId: 'zone_b',
              dayOfWeek: 5, // Jumat
              startTime: const TimeOfDay(hour: 7, minute: 0),
              endTime: const TimeOfDay(hour: 7, minute: 20),
              durationMinutes: 20,
              isActive: false,
            ),
          ],
        ),
        FieldZone(
          id: 'zone_c',
          name: 'Zona C',
          area: 0.5,
          cropType: 'Cabai',
          zoneColor: const Color(0xFFE63946),
          sensors: [
            SensorData(
              timestamp: _now,
              soilHumidity: 55.8,
              soilTemperature: 27.8,
              airTemperature: 31.2,
              airHumidity: 73.0,
              phLevel: 6.1,
              lightIntensity: 41000.0,
              nitrogenLevel: 175.0,
              phosphorLevel: 102.0,
              potassiumLevel: 220.0,
              rainfallAmount: 0.0,
              pumpStatus: false,
            ),
          ],
          isIrrigating: false,
          pumpMode: PumpMode.manual,
          schedules: [],
        ),
      ];

  // ──────────────────────────────────────────────────────────────────────────
  // AI RECOMMENDATIONS
  // ──────────────────────────────────────────────────────────────────────────

  /// Five AI-generated recommendations based on the current mock sensor data.
  static List<AiRecommendation> get aiRecommendations => [
        // 1. URGENT — Soil humidity 45.2% is below 50% threshold
        AiRecommendation(
          id: 'rec_001',
          title: 'Segera Aktifkan Irigasi Zona A',
          description:
              'Kelembaban tanah di Zona A tercatat 45.2%, berada di bawah '
              'ambang batas minimum 50%. Kondisi ini berisiko menyebabkan stres '
              'kekeringan pada tanaman padi yang dapat menurunkan hasil panen '
              'secara signifikan.',
          action:
              'Aktifkan pompa irigasi Zona A segera selama minimal 30 menit, '
              'kemudian periksa kembali nilai kelembaban tanah setelah 1 jam.',
          reason:
              'Data sensor menunjukkan kelembaban tanah = 45.2% (batas minimum: 50%). '
              'Tidak ada curah hujan tercatat hari ini (0 mm). '
              'Suhu udara 31.2°C meningkatkan laju evapotranspirasi.',
          priority: RecommendationPriority.urgent,
          category: RecommendationCategory.irrigation,
          generatedAt: _now,
          sensorContext: {
            'soilHumidity': 45.2,
            'airTemperature': 31.2,
            'rainfallAmount': 0.0,
          },
          isActioned: false,
        ),

        // 2. ATTENTION — pH 6.3 is slightly below optimal 6.5 midpoint
        AiRecommendation(
          id: 'rec_002',
          title: 'pH Tanah Perlu Ditingkatkan',
          description:
              'Tingkat pH tanah saat ini adalah 6.3, yang berada di sisi asam '
              'dari rentang optimal (6.0–7.5). Meskipun masih dalam batas aman, '
              'pH yang rendah dapat menghambat penyerapan fosfor dan kalium '
              'oleh tanaman padi secara optimal.',
          action:
              'Tambahkan kapur dolomit (CaMgCO₃) dengan dosis 150–200 kg/Ha. '
              'Aplikasikan secara merata dan siram setelah pengaplikasian untuk '
              'mempercepat reaksi tanah.',
          reason:
              'Sensor pH menunjukkan nilai 6.3. Nilai optimal untuk padi adalah '
              '6.5–7.0. Pengapuran ringan akan membantu menstabilkan pH dan '
              'meningkatkan ketersediaan nutrisi bagi tanaman.',
          priority: RecommendationPriority.attention,
          category: RecommendationCategory.fertilizer,
          generatedAt: _now.subtract(const Duration(minutes: 15)),
          sensorContext: {
            'phLevel': 6.3,
            'phosphorLevel': 95.0,
          },
          isActioned: false,
        ),

        // 3. SAFE — Temperature 31.2°C is within the 20–35°C range
        AiRecommendation(
          id: 'rec_003',
          title: 'Suhu Udara dalam Kondisi Normal',
          description:
              'Suhu udara saat ini 31.2°C masih berada dalam rentang optimal '
              'untuk pertumbuhan tanaman padi (20–35°C). Kondisi iklim hari ini '
              'mendukung proses fotosintesis dan metabolisme tanaman yang baik.',
          action:
              'Tidak ada tindakan khusus yang diperlukan. Pantau suhu secara '
              'berkala, terutama saat memasuki musim kemarau panjang untuk '
              'mengantisipasi lonjakan suhu ekstrem.',
          reason:
              'Sensor suhu udara = 31.2°C, dalam batas optimal 20–35°C. '
              'Intensitas cahaya 42,000 lux mendukung fotosintesis optimal. '
              'Kelembaban udara 72% sesuai untuk tanaman tropis.',
          priority: RecommendationPriority.safe,
          category: RecommendationCategory.climate,
          generatedAt: _now.subtract(const Duration(minutes: 30)),
          sensorContext: {
            'airTemperature': 31.2,
            'airHumidity': 72.0,
            'lightIntensity': 42000.0,
          },
          isActioned: false,
        ),

        // 4. ATTENTION — Nitrogen 180 mg/kg, slightly high, consider balance
        AiRecommendation(
          id: 'rec_004',
          title: 'Kadar Nitrogen Perlu Diperhatikan',
          description:
              'Kadar nitrogen tanah tercatat 180 mg/kg. Nilai ini berada di '
              'level tinggi dan perlu diimbangi dengan pemupukan berimbang. '
              'Kelebihan nitrogen dapat menyebabkan pertumbuhan vegetatif '
              'berlebihan dan menunda fase generatif (pembungaan/pembuahan).',
          action:
              'Kurangi pemberian pupuk urea pada aplikasi berikutnya. '
              'Tingkatkan dosis pupuk KCl (Kalium Klorida) untuk menyeimbangkan '
              'rasio N:K. Lakukan soil test ulang dalam 2 minggu.',
          reason:
              'Sensor nitrogen = 180 mg/kg, di atas nilai ideal 120–160 mg/kg '
              'untuk fase vegetatif akhir. Rasio N:K saat ini adalah '
              '180:210, disarankan mendekati 1:1.5 untuk optimasi hasil panen.',
          priority: RecommendationPriority.attention,
          category: RecommendationCategory.fertilizer,
          generatedAt: _now.subtract(const Duration(minutes: 45)),
          sensorContext: {
            'nitrogenLevel': 180.0,
            'phosphorLevel': 95.0,
            'potassiumLevel': 210.0,
          },
          isActioned: false,
        ),

        // 5. SAFE — Overall farm condition summary
        AiRecommendation(
          id: 'rec_005',
          title: 'Kondisi Lahan Secara Keseluruhan Cukup Baik',
          description:
              'Berdasarkan analisis menyeluruh seluruh sensor, kondisi lahan '
              'Jaga Tani Anda secara umum dalam keadaan baik. Parameter utama '
              'seperti suhu, cahaya, kelembaban udara, serta NPK berada dalam '
              'rentang yang dapat diterima. Perhatian utama saat ini adalah '
              'kelembaban tanah yang mulai menurun.',
          action:
              'Prioritaskan penanganan irigasi Zona A. Jadwalkan pemeriksaan '
              'rutin setiap pagi hari pukul 07.00 untuk memantau perkembangan '
              'sensor. Catat setiap perubahan signifikan di buku laporan lahan.',
          reason:
              'Skor kesehatan lahan keseluruhan: 74/100. Rincian: Suhu ✅ | '
              'Kelembaban Udara ✅ | pH ⚠️ | Kelembaban Tanah ❌ | Nitrogen ⚠️. '
              'Dua parameter memerlukan perhatian, satu memerlukan tindakan segera.',
          priority: RecommendationPriority.safe,
          category: RecommendationCategory.irrigation,
          generatedAt: _now.subtract(const Duration(hours: 1)),
          sensorContext: {
            'soilHumidity': 45.2,
            'airTemperature': 31.2,
            'airHumidity': 72.0,
            'phLevel': 6.3,
            'nitrogenLevel': 180.0,
          },
          isActioned: false,
        ),
      ];

  // ──────────────────────────────────────────────────────────────────────────
  // COMMUNITY POSTS
  // ──────────────────────────────────────────────────────────────────────────

  /// Five realistic community forum posts from Indonesian farmers.
  static List<CommunityPost> get communityPosts => [
        CommunityPost(
          id: 'post_001',
          authorName: 'Pak Budi Santoso',
          authorAvatar: '👨‍🌾',
          title: 'Tips Mengatasi Hama Wereng Coklat di Musim Kemarau',
          content:
              'Assalamualaikum rekan-rekan tani. Saya mau berbagi pengalaman '
              'mengatasi serangan wereng coklat yang melanda sawah saya minggu '
              'lalu. Saya menggunakan campuran insektisida berbahan aktif '
              'imidakloprid dengan dosis 0.5 ml/liter air, disemprot pada pagi '
              'hari sebelum jam 8 agar tidak menguap terlalu cepat. '
              'Alhamdulillah dalam 3 hari serangan sudah berkurang drastis. '
              'Jangan lupa jaga kebersihan lahan dan hindari pengairan '
              'berlebihan karena wereng suka kondisi lembab berlebih.',
          category: 'Hama & Penyakit',
          likesCount: 234,
          commentsCount: 47,
          timestamp: _now.subtract(const Duration(hours: 3)),
          tags: ['wereng', 'hama', 'padi', 'musimkemarau', 'insektisida'],
        ),
        CommunityPost(
          id: 'post_002',
          authorName: 'Bu Siti Rahayu',
          authorAvatar: '👩‍🌾',
          title:
              'Pengalaman Pakai Pupuk Organik Cair untuk Cabai, Hasilnya Luar Biasa!',
          content:
              'Halo semua! Sudah 3 bulan ini saya beralih ke pupuk organik cair '
              'dari limbah kulit pisang dan daun lamtoro untuk kebun cabai saya. '
              'Caranya: fermentasi selama 2 minggu dengan EM4, lalu encerkan '
              '1:10 sebelum disiramkan. Hasilnya tanaman lebih hijau, buah '
              'lebih banyak, dan penghematan biaya pupuk hingga 60% per musim! '
              'Buat yang mau coba, saya siap berbagi resep lengkapnya. '
              'Tinggalkan komentar ya 🌶️',
          category: 'Pupuk & Nutrisi',
          likesCount: 512,
          commentsCount: 89,
          timestamp: _now.subtract(const Duration(hours: 8)),
          tags: ['pupukorganik', 'cabai', 'em4', 'fermentasi', 'hemat'],
        ),
        CommunityPost(
          id: 'post_003',
          authorName: 'Mas Agus Prasetyo',
          authorAvatar: '👨‍💼',
          title: 'Review Sensor IoT untuk Monitoring Kelembaban Tanah',
          content:
              'Baru saja pasang sensor IoT kelembaban tanah di lahan jagung saya '
              'yang 0.8 Ha. Awalnya ragu karena harganya lumayan, tapi ternyata '
              'investasinya worth it banget! Dalam 1 bulan pertama, konsumsi air '
              'irigasi turun 35% karena saya hanya siram saat sensor menunjukkan '
              'kelembaban di bawah 50%. Sebelumnya saya siram setiap hari tanpa '
              'tahu kondisi tanah sebenarnya. Kalau ada yang mau tanya-tanya '
              'soal pemasangan atau mereknya, feel free to ask!',
          category: 'Teknologi Tani',
          likesCount: 178,
          commentsCount: 32,
          timestamp: _now.subtract(const Duration(hours: 18)),
          tags: ['iot', 'sensor', 'teknologi', 'irigasi', 'jagung', 'hemat'],
        ),
        CommunityPost(
          id: 'post_004',
          authorName: 'Pak Hendra Wijaya',
          authorAvatar: '🧑‍🌾',
          title:
              'Prediksi Cuaca Salah Terus, Bagaimana Cara Antisipasi Hujan Tak Terduga?',
          content:
              'Sudah dua kali ini panen saya rusak karena hujan deras tiba-tiba '
              'saat masa pengeringan gabah. Prakiraan BMKG bilang cerah, '
              'ternyata langsung hujan lebat. Ada yang punya tips untuk '
              'antisipasi kondisi seperti ini? Saya sudah coba pakai terpal '
              'tapi tidak efektif untuk lahan yang luas. Mungkin ada teknologi '
              'atau metode panen yang bisa mengurangi risiko ini? '
              'Sangat butuh masukan dari yang sudah berpengalaman.',
          category: 'Cuaca & Iklim',
          likesCount: 93,
          commentsCount: 56,
          timestamp: _now.subtract(const Duration(days: 1)),
          tags: ['cuaca', 'panen', 'gabah', 'bmkg', 'antisipasi'],
        ),
        CommunityPost(
          id: 'post_005',
          authorName: 'Bu Dewi Kusuma',
          authorAvatar: '👩‍💻',
          title:
              'Berbagi: Cara Baca Data pH Tanah dan Pengaruhnya ke Pertumbuhan Padi',
          content:
              'Banyak yang tanya soal pH tanah dan pengaruhnya ke hasil panen. '
              'Jadi saya tuliskan di sini berdasarkan pengalaman 10 tahun '
              'bertani padi. pH optimal padi adalah 6.0–7.0. Jika pH di bawah '
              '6.0 (asam), tambahkan kapur dolomit. Jika di atas 7.0 (basa), '
              'tambahkan belerang atau pupuk ZA. Yang paling penting: ukur pH '
              'SEBELUM tanam, bukan setelah tanaman sudah stres. '
              'Semoga membantu! 🌾',
          category: 'Edukasi Tani',
          likesCount: 687,
          commentsCount: 124,
          timestamp: _now.subtract(const Duration(days: 2)),
          tags: ['pH', 'padi', 'kapur', 'tanah', 'edukasi', 'nutrisi'],
        ),
      ];

  // ──────────────────────────────────────────────────────────────────────────
  // WEATHER INFO
  // ──────────────────────────────────────────────────────────────────────────

  /// Current weather and 7-day forecast mock data.
  ///
  /// Keys:
  /// - `condition` (String): current weather description.
  /// - `temperature` (int): current temperature in °C.
  /// - `humidity` (int): current humidity in %.
  /// - `windSpeed` (int): wind speed in km/h.
  /// - `forecast` (List<String>): 7-day forecast descriptions.
  static Map<String, dynamic> get weatherInfo => {
        'condition': 'Cerah',
        'temperature': 31,
        'humidity': 68,
        'windSpeed': 12,
        'forecast': [
          'Cerah',
          'Berawan',
          'Hujan Ringan',
          'Berawan',
          'Cerah',
          'Cerah',
          'Cerah',
        ],
      };

  // ──────────────────────────────────────────────────────────────────────────
  // HELPER ACCESSORS
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the [FieldZone] matching [zoneId], or null if not found.
  static FieldZone? getZoneById(String zoneId) {
    try {
      return fieldZones.firstWhere((z) => z.id == zoneId);
    } catch (_) {
      return null;
    }
  }

  /// Returns AI recommendations filtered by [priority].
  static List<AiRecommendation> recommendationsByPriority(
    RecommendationPriority priority,
  ) {
    return aiRecommendations.where((r) => r.priority == priority).toList();
  }

  /// Returns AI recommendations filtered by [category].
  static List<AiRecommendation> recommendationsByCategory(
    RecommendationCategory category,
  ) {
    return aiRecommendations.where((r) => r.category == category).toList();
  }

  /// Returns community posts filtered by [category].
  static List<CommunityPost> postsByCategory(String category) {
    return communityPosts.where((p) => p.category == category).toList();
  }

  /// Returns the count of active (non-actioned, urgent) recommendations.
  static int get urgentRecommendationCount => aiRecommendations
      .where(
        (r) =>
            r.priority == RecommendationPriority.urgent && !r.isActioned,
      )
      .length;

  /// Returns a list of distinct community post categories.
  static List<String> get communityCategories =>
      communityPosts.map((p) => p.category).toSet().toList();
}
