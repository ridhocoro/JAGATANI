"""
Modul Pengaman Aktuator (Safety Guardrails)
Fungsi murni: mengecek seluruh parameter dan syarat agronomi & operasional
sebelum perintah pompa irigasi diperbolehkan dikirim ke hardware.
"""
from typing import Dict, Any, Tuple


def boleh_siram(konteks: Dict[str, Any]) -> Tuple[bool, str, int]:
    """
    Mengevaluasi apakah penyiraman diizinkan berdasarkan 8 lapis syarat keselamatan.

    Parameter konteks (dict):
    - mode_zona: 'manual' | 'semi_otomatis' | 'otomatis'
    - sumber: 'manual' | 'semi_otomatis' | 'otomatis'
    - umur_data_menit: float (usia log sensor terakhir dalam menit)
    - keputusan_f02: str ('perlu' | 'tidak_perlu' | 'tidak_yakin')
    - confidence_f02: float (0.0 s.d. 1.0)
    - hujan_aktual: int (1 = hujan, 0 = tidak hujan)
    - prakiraan_hujan_6jam: float (dalam mm)
    - jeda_siraman_terakhir_jam: Optional[float] (jam sejak siram sukses terakhir, None jika belum pernah)
    - durasi_diminta_menit: int
    - pompa_sedang_berjalan: bool

    Returns:
    (boleh: bool, catatan_atau_alasan_tolak: str, durasi_efektif_menit: int)
    """
    mode_zona = str(konteks.get("mode_zona", "semi_otomatis")).lower()
    sumber = str(konteks.get("sumber", "semi_otomatis")).lower()
    durasi_diminta = int(konteks.get("durasi_diminta_menit", 15))

    # Klem durasi ke rentang 1 - 15 menit (Syarat #7)
    durasi_efektif = durasi_diminta
    catatan_klem = ""
    if durasi_diminta > 15:
        durasi_efektif = 15
        catatan_klem = f"Durasi dipotong dari {durasi_diminta} menit menjadi 15 menit untuk keselamatan akar. "
    elif durasi_diminta < 1:
        durasi_efektif = 1
        catatan_klem = f"Durasi disesuaikan dari {durasi_diminta} menit menjadi 1 menit minimum. "

    # 1. Mode zona adalah semi_otomatis atau otomatis, ATAU sumber adalah manual (dari petani)
    if mode_zona == "manual" and sumber != "manual":
        return False, "Zona dalam mode manual: perintah non-manual (otomatis/semi-otomatis) ditolak", durasi_efektif

    # 2. Jika sumber 'otomatis': mode zona harus 'otomatis'
    if sumber == "otomatis" and mode_zona != "otomatis":
        return False, f"Perintah otomatis ditolak: zona sedang dalam mode '{mode_zona}'", durasi_efektif

    # 3. Data sensor tidak basi: waktu data terakhir kurang dari 15 menit
    umur_data = konteks.get("umur_data_menit")
    if umur_data is None or umur_data > 15.0:
        return False, f"Data sensor basi atau tidak tersedia: umur data {umur_data} menit (> 15 menit)", durasi_efektif

    # 4. Keputusan F-02 adalah 'perlu', dan confidence >= 0.60
    # Catatan: Jika petani secara manual menyiram dan menyadari risikonya, aturan tetap memverifikasi F-02
    # untuk keamanan proteksi pompa, sesuai urutan pengecekan spesifikasi MVP.
    keputusan_f02 = str(konteks.get("keputusan_f02", "")).lower()
    confidence_f02 = float(konteks.get("confidence_f02", 0.0))
    if keputusan_f02 != "perlu" or confidence_f02 < 0.60:
        return False, f"F-02 tidak menyetujui: keputusan '{keputusan_f02}' dengan confidence {confidence_f02:.2f} (< 0.60)", durasi_efektif

    # 5. Tidak ada hujan aktual (hujan == 0) dan prakiraan hujan 6 jam di bawah 1 mm
    hujan_aktual = int(konteks.get("hujan_aktual", 0))
    prakiraan_hujan = float(konteks.get("prakiraan_hujan_6jam", 0.0))
    if hujan_aktual > 0:
        return False, "Hujan aktual terdeteksi di sensor: irigasi dibatalkan", durasi_efektif
    if prakiraan_hujan >= 1.0:
        return False, f"Prakiraan hujan signifikan ({prakiraan_hujan:.1f} mm dalam 6 jam): irigasi ditunda", durasi_efektif

    # 6. Jeda sejak siraman berhasil terakhir minimal 6 jam
    jeda_jam = konteks.get("jeda_siraman_terakhir_jam")
    if jeda_jam is not None and jeda_jam < 6.0:
        return False, f"Jeda penyiraman belum cukup: baru {jeda_jam:.1f} jam sejak siraman terakhir (minimal 6.0 jam)", durasi_efektif

    # 8. Tidak ada perintah pompa lain yang masih berjalan di zona yang sama
    if konteks.get("pompa_sedang_berjalan", False):
        return False, "Pompa di zona ini sedang aktif berjalan", durasi_efektif

    pesan_sukses = (catatan_klem + "Semua syarat pengaman terpenuhi. Perintah irigasi disetujui.").strip()
    return True, pesan_sukses, durasi_efektif
