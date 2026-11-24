"""
Pengujian Otomatis Fitur Aktuator (S-A1 s.d. S-A8)
Berdasarkan Dokumen Panduan Implementasi Pengairan & Pemupukan (MVP)
"""
import pytest
from app.aktuator.pengaman import boleh_siram


def get_base_context():
    return {
        "mode_zona": "otomatis",
        "sumber": "otomatis",
        "umur_data_menit": 5.0,
        "keputusan_f02": "perlu",
        "confidence_f02": 0.95,
        "hujan_aktual": 0,
        "prakiraan_hujan_6jam": 0.0,
        "jeda_siraman_terakhir_jam": 8.0,
        "durasi_diminta_menit": 15,
        "pompa_sedang_berjalan": False
    }


def test_s_a1_data_sensor_basi():
    """S-A1: Data sensor berumur lebih dari 15 menit, mode otomatis -> boleh_siram False"""
    ctx = get_base_context()
    ctx["umur_data_menit"] = 20.0  # > 15 menit
    boleh, alasan, durasi = boleh_siram(ctx)
    assert boleh is False
    assert "basi" in alasan.lower() or "15" in alasan


def test_s_a2_dua_siram_dalam_6_jam():
    """S-A2: Dua siram dalam 6 jam -> Permintaan kedua berstatus ditolak_pengaman (jeda < 6 jam)"""
    ctx = get_base_context()
    ctx["jeda_siraman_terakhir_jam"] = 2.5  # < 6.0 jam
    boleh, alasan, durasi = boleh_siram(ctx)
    assert boleh is False
    assert "jeda" in alasan.lower() or "6.0" in alasan


def test_s_a3_durasi_dipotong_ke_15_menit():
    """S-A3: Diminta 30 menit -> Durasi dipotong ke 15 menit, alasan tercatat"""
    ctx = get_base_context()
    ctx["durasi_diminta_menit"] = 30
    boleh, alasan, durasi = boleh_siram(ctx)
    assert boleh is True
    assert durasi == 15
    assert "dipotong" in alasan.lower() and "15" in alasan


def test_s_a4_mode_manual_penjadwal_otomatis():
    """S-A4: Mode manual, penjadwal berjalan (sumber otomatis) -> Tidak ada perintah dikirim"""
    ctx = get_base_context()
    ctx["mode_zona"] = "manual"
    ctx["sumber"] = "otomatis"
    boleh, alasan, durasi = boleh_siram(ctx)
    assert boleh is False
    assert "manual" in alasan.lower()


def test_s_a5_hujan_aktual_terdeteksi():
    """S-A5: Hujan aktual terdeteksi -> Pompa tidak dinyalakan, alasan hujan tercatat"""
    ctx = get_base_context()
    ctx["hujan_aktual"] = 1
    boleh, alasan, durasi = boleh_siram(ctx)
    assert boleh is False
    assert "hujan" in alasan.lower()


def test_s_a6_validasi_pemupukan_tanpa_dosis():
    """S-A6: Pemupukan dicatat tanpa dosis atau jenis pupuk -> Harus divalidasi dan ditolak"""
    from app.api.pemupukan import validasi_catatan_pemupukan
    hasil, pesan = validasi_catatan_pemupukan("NPK 15-15-15", "")
    assert hasil is False
    assert "dosis" in pesan.lower()

    hasil2, pesan2 = validasi_catatan_pemupukan("", "150 kg/ha")
    assert hasil2 is False
    assert "jenis" in pesan2.lower()

    hasil3, pesan3 = validasi_catatan_pemupukan("NPK 15-15-15", "-50 kg/ha")
    assert hasil3 is False
    assert "positif" in pesan3.lower()

    hasil_valid, _ = validasi_catatan_pemupukan("NPK 15-15-15", "150 kg/ha")
    assert hasil_valid is True


def test_s_a7_dua_perintah_pompa_bersamaan():
    """S-A7: Dua perintah pompa bersamaan di satu zona -> Hanya satu yang diproses, kedua ditolak"""
    ctx = get_base_context()
    ctx["pompa_sedang_berjalan"] = True
    boleh, alasan, durasi = boleh_siram(ctx)
    assert boleh is False
    assert "sedang aktif" in alasan.lower()


def test_s_a8_mode_semi_otomatis_tidak_auto_kirim():
    """S-A8: Mode semi-otomatis, sumber otomatis -> Ditolak dari pengiriman langsung (hanya dibuat draft)"""
    ctx = get_base_context()
    ctx["mode_zona"] = "semi_otomatis"
    ctx["sumber"] = "otomatis"  # Penjadwal mencoba kirim otomatis saat mode semi-otomatis
    boleh, alasan, durasi = boleh_siram(ctx)
    assert boleh is False
    assert "semi_otomatis" in alasan.lower()
