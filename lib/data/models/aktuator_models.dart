// Model data untuk fitur Aktuator Pengairan (A-01) dan Pemupukan (A-02)

class ModeZonaModel {
  final String zonaId;
  final String mode; // 'manual', 'semi_otomatis', 'otomatis'
  final String diubahOleh;
  final String diubahPada;

  ModeZonaModel({
    required this.zonaId,
    required this.mode,
    required this.diubahOleh,
    required this.diubahPada,
  });

  factory ModeZonaModel.fromJson(Map<String, dynamic> json) {
    return ModeZonaModel(
      zonaId: json['zona_id'] ?? '',
      mode: json['mode'] ?? 'semi_otomatis',
      diubahOleh: json['diubah_oleh'] ?? 'sistem',
      diubahPada: json['diubah_pada'] ?? '',
    );
  }

  factory ModeZonaModel.fallback(String zonaId) {
    return ModeZonaModel(
      zonaId: zonaId,
      mode: 'semi_otomatis',
      diubahOleh: 'sistem_default',
      diubahPada: DateTime.now().toIso8601String(),
    );
  }
}

class StatusPompaModel {
  final String pompa; // 'on' atau 'off'
  final int sisaDetik;
  final String? idPerintah;
  final String? updatedAt;

  StatusPompaModel({
    required this.pompa,
    required this.sisaDetik,
    this.idPerintah,
    this.updatedAt,
  });

  bool get isOn => pompa.toLowerCase() == 'on';

  factory StatusPompaModel.fromJson(Map<String, dynamic> json) {
    return StatusPompaModel(
      pompa: json['pompa'] ?? 'off',
      sisaDetik: (json['sisa_detik'] as num?)?.toInt() ?? 0,
      idPerintah: json['id_perintah'],
      updatedAt: json['updated_at'],
    );
  }

  factory StatusPompaModel.fallback() {
    return StatusPompaModel(pompa: 'off', sisaDetik: 0);
  }
}

class AksiAktuatorModel {
  final String id;
  final String waktu;
  final String zonaId;
  final String jenis; // 'pompa_irigasi' atau 'pupuk'
  final String sumber; // 'manual', 'semi_otomatis', 'otomatis'
  final String? keputusanF02;
  final double? confidenceF02;
  final String? alasan;
  final int? durasiMenit;
  final String? jenisPupuk;
  final String? dosis;
  final String status; // 'diminta', 'ditolak_pengaman', 'dikirim', 'berhasil', 'gagal'
  final String? alasanTolak;

  AksiAktuatorModel({
    required this.id,
    required this.waktu,
    required this.zonaId,
    required this.jenis,
    required this.sumber,
    this.keputusanF02,
    this.confidenceF02,
    this.alasan,
    this.durasiMenit,
    this.jenisPupuk,
    this.dosis,
    required this.status,
    this.alasanTolak,
  });

  factory AksiAktuatorModel.fromJson(Map<String, dynamic> json) {
    return AksiAktuatorModel(
      id: json['id'] ?? '',
      waktu: json['waktu'] ?? '',
      zonaId: json['zona_id'] ?? '',
      jenis: json['jenis'] ?? '',
      sumber: json['sumber'] ?? '',
      keputusanF02: json['keputusan_f02'],
      confidenceF02: (json['confidence_f02'] as num?)?.toDouble(),
      alasan: json['alasan'],
      durasiMenit: (json['durasi_menit'] as num?)?.toInt(),
      jenisPupuk: json['jenis_pupuk'],
      dosis: json['dosis'],
      status: json['status'] ?? '',
      alasanTolak: json['alasan_tolak'],
    );
  }
}

class HasilTriggerPompa {
  final String status; // 'dikirim' atau 'ditolak_pengaman'
  final String idAksi;
  final String zonaId;
  final int durasiMenit;
  final String? alasan;
  final String? alasanTolak;
  final bool perintahDikirim;

  HasilTriggerPompa({
    required this.status,
    required this.idAksi,
    required this.zonaId,
    required this.durasiMenit,
    this.alasan,
    this.alasanTolak,
    required this.perintahDikirim,
  });

  factory HasilTriggerPompa.fromJson(Map<String, dynamic> json) {
    return HasilTriggerPompa(
      status: json['status'] ?? 'gagal',
      idAksi: json['id_aksi'] ?? '',
      zonaId: json['zona_id'] ?? '',
      durasiMenit: (json['durasi_menit'] as num?)?.toInt() ?? 15,
      alasan: json['alasan'],
      alasanTolak: json['alasan_tolak'],
      perintahDikirim: json['perintah_dikirim'] ?? false,
    );
  }
}
