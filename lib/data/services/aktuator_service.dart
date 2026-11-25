import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jaga_tani/data/models/aktuator_models.dart';
import 'package:jaga_tani/data/services/ml_service.dart';
import 'package:jaga_tani/data/services/notification_service.dart';

class AktuatorService {
  static String get baseUrl => MlService.baseUrl;
  static const Duration requestTimeout = Duration(seconds: 4);

  // Riwayat aksi lokal (offline-first persistence)
  static final List<AksiAktuatorModel> _localRiwayat = [];

  /// Membaca mode kontrol zona (manual, semi_otomatis, otomatis)
  static Future<ModeZonaModel> fetchModeZona(String zonaId) async {
    final url = Uri.parse('$baseUrl/zona/$zonaId/mode');
    try {
      final response = await http.get(url).timeout(requestTimeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ModeZonaModel.fromJson(data);
      }
    } catch (_) {}
    return ModeZonaModel.fallback(zonaId);
  }

  /// Mengubah mode kontrol zona
  static Future<bool> updateModeZona(String zonaId, String mode, {String diubahOleh = 'petani'}) async {
    final url = Uri.parse('$baseUrl/zona/$zonaId/mode');
    final body = json.encode({
      'mode': mode,
      'diubah_oleh': diubahOleh,
    });
    try {
      final response = await http
          .put(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(requestTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Meminta aktivasi pompa irigasi (melewati pengaman)
  static Future<HasilTriggerPompa> triggerPompa({
    required String zonaId,
    int durasiMenit = 15,
    String sumber = 'semi_otomatis',
  }) async {
    final url = Uri.parse('$baseUrl/aktuator/pompa');
    final body = json.encode({
      'zona_id': zonaId,
      'durasi_menit': durasiMenit,
      'sumber': sumber,
    });

    try {
      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(requestTimeout);
      final data = json.decode(response.body);
      final hasil = HasilTriggerPompa.fromJson(data);

      if (hasil.perintahDikirim) {
        NotificationService().showPhoneNotification(
          title: '🚿 Pompa Irigasi Beroperasi',
          body: 'Penyiraman $zonaId dimulai selama $durasiMenit menit dengan pengaman otomatis.',
          category: NotificationCategory.actuator,
        );
      } else if (hasil.status == 'ditolak_pengaman') {
        NotificationService().showPhoneNotification(
          title: '🛑 Irigasi Ditolak Pengaman',
          body: hasil.alasanTolak ?? 'Pengaman mendeteksi kondisi belum aman untuk irigasi.',
          category: NotificationCategory.critical,
        );
      }

      return hasil;
    } catch (e) {
      return HasilTriggerPompa(
        status: 'ditolak_pengaman',
        idAksi: '',
        zonaId: zonaId,
        durasiMenit: durasiMenit,
        alasanTolak: 'Tidak dapat menghubungi server backend: $e',
        perintahDikirim: false,
      );
    }
  }

  /// Emergency Stop: Matikan pompa segera
  static Future<bool> matikanPompa(String zonaId) async {
    final url = Uri.parse('$baseUrl/aktuator/pompa/matikan');
    final body = json.encode({
      'zona_id': zonaId,
      'sumber': 'manual',
    });
    try {
      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(requestTimeout);
      final ok = response.statusCode == 200;
      if (ok) {
        NotificationService().showPhoneNotification(
          title: '⏹️ Pompa Dimatikan',
          body: 'Pompa irigasi $zonaId berhasil dimatikan secara manual.',
          category: NotificationCategory.actuator,
        );
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Membaca status real-time pompa dari ESP32
  static Future<StatusPompaModel> fetchStatusPompa(String zonaId) async {
    final url = Uri.parse('$baseUrl/aktuator/status/$zonaId');
    try {
      final response = await http.get(url).timeout(requestTimeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return StatusPompaModel.fromJson(data['data']);
        }
      }
    } catch (_) {}
    return StatusPompaModel.fallback();
  }

  /// Membaca riwayat aksi aktuator (pompa dan pupuk)
  static Future<List<AksiAktuatorModel>> fetchRiwayatAksi({String? zonaId, int limit = 20}) async {
    var query = 'limit=$limit';
    if (zonaId != null) query += '&zona=$zonaId';
    final url = Uri.parse('$baseUrl/aktuator/riwayat?$query');

    List<AksiAktuatorModel> remoteList = [];
    try {
      final response = await http.get(url).timeout(requestTimeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['data'] as List<dynamic>?) ?? [];
        remoteList = list.map((item) => AksiAktuatorModel.fromJson(item)).toList();
      }
    } catch (_) {}

    final combined = [..._localRiwayat, ...remoteList];
    if (zonaId != null) {
      return combined.where((item) => item.zonaId == zonaId).take(limit).toList();
    }
    return combined.take(limit).toList();
  }

  /// A-02: Mencatat pemupukan yang disetujui petani (dengan offline fallback)
  static Future<bool> catatPemupukan({
    required String zonaId,
    required String jenisPupuk,
    required String dosis,
    String? idRekomendasiF03,
  }) async {
    final entry = AksiAktuatorModel(
      id: 'PUPUK-${DateTime.now().millisecondsSinceEpoch}',
      waktu: DateTime.now().toIso8601String(),
      zonaId: zonaId,
      jenis: 'pupuk',
      sumber: 'manual',
      jenisPupuk: jenisPupuk,
      dosis: dosis,
      status: 'berhasil',
      alasan: idRekomendasiF03 != null
          ? 'Sesuai Rekomendasi $idRekomendasiF03'
          : 'Aplikasi Mandiri Petani',
    );

    // Simpan ke riwayat lokal terlebih dahulu (Offline-First)
    _localRiwayat.insert(0, entry);

    // Kirim notifikasi ponsel
    NotificationService().showPhoneNotification(
      title: '🌾 Pemupukan Berhasil Dicatat',
      body: 'Pemberian $jenisPupuk ($dosis) pada $zonaId berhasil disimpan.',
      category: NotificationCategory.ai,
    );

    // Sinkronisasi ke server jika online
    final url = Uri.parse('$baseUrl/pemupukan/catat');
    final body = json.encode({
      'zona_id': zonaId,
      'jenis_pupuk': jenisPupuk,
      'dosis': dosis,
      'id_rekomendasi_f03': idRekomendasiF03,
      'petani_setuju': true,
    });

    try {
      await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(requestTimeout);
    } catch (_) {
      // Offline fallback: tetap sukses karena sudah tersimpan secara lokal
    }

    return true;
  }
}
