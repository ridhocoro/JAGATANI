class HourlyMoisturePoint {
  final int jamKe;
  final String waktu;
  final double prediksi;
  final double batasBawah;
  final double batasAtas;
  final double prakiraanHujan;

  HourlyMoisturePoint({
    required this.jamKe,
    required this.waktu,
    required this.prediksi,
    required this.batasBawah,
    required this.batasAtas,
    required this.prakiraanHujan,
  });

  factory HourlyMoisturePoint.fromJson(Map<String, dynamic> json) {
    return HourlyMoisturePoint(
      jamKe: json['jam_ke'] as int? ?? 0,
      waktu: json['waktu'] as String? ?? '',
      prediksi: (json['prediksi_kelembaban'] as num?)?.toDouble() ?? 0.0,
      batasBawah: (json['batas_bawah'] as num?)?.toDouble() ?? 0.0,
      batasAtas: (json['batas_atas'] as num?)?.toDouble() ?? 0.0,
      prakiraanHujan: (json['prakiraan_hujan'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class F01MoisturePredictionResponse {
  final String status;
  final String zonaId;
  final String timestampTerakhir;
  final double nilaiAktualTerakhir;
  final double mae;
  final double rmse;
  final List<HourlyMoisturePoint> prediksi24Jam;
  final String? pesan;

  F01MoisturePredictionResponse({
    required this.status,
    required this.zonaId,
    required this.timestampTerakhir,
    required this.nilaiAktualTerakhir,
    required this.mae,
    required this.rmse,
    required this.prediksi24Jam,
    this.pesan,
  });

  bool get isDataCukup => status == 'success' && prediksi24Jam.isNotEmpty;

  factory F01MoisturePredictionResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'unknown';
    final pts = (json['prediksi_24_jam'] as List?)
            ?.map((e) => HourlyMoisturePoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final eval = json['evaluasi_model'] as Map<String, dynamic>? ?? {};

    return F01MoisturePredictionResponse(
      status: status,
      zonaId: json['zona_id'] as String? ?? 'zone_a',
      timestampTerakhir: json['timestamp_terakhir'] as String? ?? '',
      nilaiAktualTerakhir:
          (json['nilai_aktual_terakhir'] as num?)?.toDouble() ?? 0.0,
      mae: (eval['mae'] as num?)?.toDouble() ?? 4.13,
      rmse: (eval['rmse'] as num?)?.toDouble() ?? 6.46,
      prediksi24Jam: pts,
      pesan: json['pesan'] as String?,
    );
  }

  factory F01MoisturePredictionResponse.mockFallback(String zonaId) {
    return F01MoisturePredictionResponse(
      status: 'offline_cache',
      zonaId: zonaId,
      timestampTerakhir: '2026-10-30 23:00:00',
      nilaiAktualTerakhir: 45.2,
      mae: 4.13,
      rmse: 6.46,
      prediksi24Jam: List.generate(24, (i) {
        final val = 45.2 - (i * 0.45);
        return HourlyMoisturePoint(
          jamKe: i + 1,
          waktu: '${i + 1} jam lagi',
          prediksi: val,
          batasBawah: (val - 6.46).clamp(0.0, 100.0),
          batasAtas: (val + 6.46).clamp(0.0, 100.0),
          prakiraanHujan: i == 14 ? 3.5 : 0.0,
        );
      }),
    );
  }
}

class F02IrrigationDecisionResponse {
  final String status;
  final String zonaId;
  final String keputusan; // "perlu", "tidak_perlu", "tidak_yakin"
  final double confidence;
  final String statusKeyakinan;
  final String alasan;
  final String rekomendasiAksi;
  final double probPerlu;
  final double probTidakPerlu;

  F02IrrigationDecisionResponse({
    required this.status,
    required this.zonaId,
    required this.keputusan,
    required this.confidence,
    required this.statusKeyakinan,
    required this.alasan,
    required this.rekomendasiAksi,
    required this.probPerlu,
    required this.probTidakPerlu,
  });

  bool get isPerlu => keputusan == 'perlu';
  bool get isTidakYakin => keputusan == 'tidak_yakin';

  factory F02IrrigationDecisionResponse.fromJson(Map<String, dynamic> json) {
    final probs = json['probabilitas'] as Map<String, dynamic>? ?? {};
    return F02IrrigationDecisionResponse(
      status: json['status'] as String? ?? 'unknown',
      zonaId: json['zona_id'] as String? ?? 'zone_a',
      keputusan: json['keputusan'] as String? ?? 'tidak_yakin',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      statusKeyakinan: json['status_keyakinan'] as String? ?? 'rendah',
      alasan: json['alasan'] as String? ?? 'Informasi tidak tersedia',
      rekomendasiAksi: json['rekomendasi_aksi'] as String? ?? 'Pantau kondisi lahan',
      probPerlu: (probs['perlu_irigasi'] as num?)?.toDouble() ?? 0.0,
      probTidakPerlu: (probs['tidak_perlu_irigasi'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory F02IrrigationDecisionResponse.mockFallback(String zonaId) {
    return F02IrrigationDecisionResponse(
      status: 'offline_cache',
      zonaId: zonaId,
      keputusan: 'perlu',
      confidence: 0.88,
      statusKeyakinan: 'tinggi',
      alasan:
          'Kelembaban tanah saat ini 45.2% (kritis di bawah ambang optimal 50%) dan tidak ada prakiraan hujan signifikan.',
      rekomendasiAksi: 'Aktifkan pompa irigasi 20–30 menit',
      probPerlu: 0.88,
      probTidakPerlu: 0.12,
    );
  }
}

class FertilizerRuleItem {
  final String idAturan;
  final String namaAturan;
  final int prioritas;
  final String status;
  final String judul;
  final String penjelasan;
  final String saran;
  final bool rekomendasiPupukDiizinkan;
  final String sumber;

  FertilizerRuleItem({
    required this.idAturan,
    required this.namaAturan,
    required this.prioritas,
    required this.status,
    required this.judul,
    required this.penjelasan,
    required this.saran,
    required this.rekomendasiPupukDiizinkan,
    required this.sumber,
  });

  factory FertilizerRuleItem.fromJson(Map<String, dynamic> json) {
    return FertilizerRuleItem(
      idAturan: json['id_aturan'] as String? ?? '',
      namaAturan: json['nama_aturan'] as String? ?? '',
      prioritas: json['prioritas'] as int? ?? 99,
      status: json['status'] as String? ?? 'warning',
      judul: json['judul'] as String? ?? '',
      penjelasan: json['penjelasan_kondisi'] as String? ?? '',
      saran: json['saran_tindakan'] as String? ?? '',
      rekomendasiPupukDiizinkan:
          json['rekomendasi_pupuk_diizinkan'] as bool? ?? false,
      sumber: json['sumber_aturan'] as String? ?? '',
    );
  }
}

class F03FertilizerRecommendationResponse {
  final String status;
  final String zonaId;
  final double phTanah;
  final double kelembabanTanah;
  final double curahHujan24h;
  final bool bolehMemupuk;
  final String statusLabel;
  final bool perluKonfirmasiPetani;
  final List<FertilizerRuleItem> daftarRekomendasi;

  F03FertilizerRecommendationResponse({
    required this.status,
    required this.zonaId,
    required this.phTanah,
    required this.kelembabanTanah,
    required this.curahHujan24h,
    required this.bolehMemupuk,
    required this.statusLabel,
    required this.perluKonfirmasiPetani,
    required this.daftarRekomendasi,
  });

  factory F03FertilizerRecommendationResponse.fromJson(Map<String, dynamic> json) {
    final kondisi = json['kondisi_aktual'] as Map<String, dynamic>? ?? {};
    final kesimpulan = json['kesimpulan_pemupukan'] as Map<String, dynamic>? ?? {};
    final list = (json['daftar_rekomendasi'] as List?)
            ?.map((e) => FertilizerRuleItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return F03FertilizerRecommendationResponse(
      status: json['status'] as String? ?? 'unknown',
      zonaId: json['zona_id'] as String? ?? 'zone_a',
      phTanah: (kondisi['ph_tanah'] as num?)?.toDouble() ?? 6.3,
      kelembabanTanah: (kondisi['kelembaban_tanah'] as num?)?.toDouble() ?? 45.2,
      curahHujan24h:
          (kondisi['prakiraan_curah_hujan_24jam_mm'] as num?)?.toDouble() ?? 0.0,
      bolehMemupuk: kesimpulan['boleh_memupuk_sekarang'] as bool? ?? false,
      statusLabel: kesimpulan['status_label'] as String? ?? 'TUNDA / KOREKSI',
      perluKonfirmasiPetani:
          kesimpulan['perlu_konfirmasi_petani'] as bool? ?? true,
      daftarRekomendasi: list,
    );
  }

  factory F03FertilizerRecommendationResponse.mockFallback(String zonaId) {
    return F03FertilizerRecommendationResponse(
      status: 'offline_cache',
      zonaId: zonaId,
      phTanah: 6.3,
      kelembabanTanah: 45.2,
      curahHujan24h: 0.0,
      bolehMemupuk: true,
      statusLabel: 'DAPAT DILAKUKAN',
      perluKonfirmasiPetani: true,
      daftarRekomendasi: [
        FertilizerRuleItem(
          idAturan: 'R-05',
          namaAturan: 'Kondisi Optimal Pemupukan Rutin',
          prioritas: 5,
          status: 'optimal',
          judul: 'Kondisi Lahan Sangat Mendukung Pemupukan',
          penjelasan:
              'Kondisi pH tanah netral-optimal (6.3), kelembaban cukup, dan tidak ada ancaman hujan lebat pencuci hara.',
          saran:
              'Aplikasi pupuk NPK 15-15-15 (150-200 kg/ha) sesuai fase pertumbuhan padi. Aplikasikan di pagi hari saat stomata terbuka.',
          rekomendasiPupukDiizinkan: true,
          sumber:
              'Rekomendasi Pemupukan Padi/Palawija Spesifik Lokasi Balitbangtan',
        )
      ],
    );
  }
}
