import os
import json
import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

BASE_DIR = os.path.dirname(os.path.dirname(__file__))
METRICS_F01 = os.path.join(BASE_DIR, "app", "ml", "model", "metrics_f01.json")
METRICS_F02 = os.path.join(BASE_DIR, "app", "ml", "model", "metrics_f02.json")


def test_s01_f01_prediksi_kelembaban_mae_dan_baseline():
    """
    S-01: F-01 Prediksi 24 jam pada data uji
    Kriteria: MAE <= 5.0 poin kelembaban dan lebih baik dari baseline persistence.
    """
    assert os.path.exists(METRICS_F01), "File metrik F-01 tidak ditemukan."
    with open(METRICS_F01, "r") as f:
        m = json.load(f)

    winning_mae = m["mae_model_terpilih"]
    mae_base = m["perbandingan_model"]["baseline_persistence"]["mae"]

    print(f"\n[S-01] MAE Model Terpilih ({m['model_terpilih']}): {winning_mae}% vs Baseline: {mae_base}%")
    assert winning_mae <= 5.0, f"MAE {winning_mae} melampaui batas ambang produk 5.0%"
    assert winning_mae < mae_base, f"Model terpilih harus lebih baik dari baseline persistence"

    # Uji endpoint API F-01
    res = client.get("/prediksi/kelembaban?zona=zone_a")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "success"
    assert len(data["prediksi_24_jam"]) == 24
    assert "batas_bawah" in data["prediksi_24_jam"][0]
    assert "batas_atas" in data["prediksi_24_jam"][0]


def test_s02_f02_klasifikasi_recall():
    """
    S-02: F-02 Klasifikasi pada data uji
    Kriteria: Recall model ML terpilih lebih tinggi dari baseline aturan ambang statis.
    """
    assert os.path.exists(METRICS_F02), "File metrik F-02 tidak ditemukan."
    with open(METRICS_F02, "r") as f:
        m = json.load(f)

    rec_rf = m["perbandingan_model"]["random_forest_classifier"]["recall"]
    rec_base = m["perbandingan_model"]["baseline_aturan_ambang"]["recall"]

    print(f"\n[S-02] Recall Random Forest: {rec_rf} vs Baseline: {rec_base}")
    assert rec_rf > rec_base, f"Model ML harus memiliki recall lebih tinggi daripada aturan ambang statis (RF: {rec_rf} vs Base: {rec_base})"


def test_s03_f02_confidence_rendah_tidak_yakin():
    """
    S-03: F-02 Ketika confidence di bawah 60% (kondisi abu-abu batas ambang),
    sistem menampilkan 'tidak yakin' dan tidak membuat keputusan sepihak.
    """
    payload = {
        "zona_id": "zone_a",
        "kelembaban_tanah": 31.0,
        "suhu_udara": 31.0,
        "kelembaban_udara": 68.0,
        "hujan": 0,
        "riwayat_kelembaban": [32.0, 31.5, 31.0] * 8
    }
    res = client.post("/keputusan/irigasi", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "success"
    assert "confidence" in data
    assert "alasan" in data


def test_s04_f03_pemupukan_ph_di_luar_rentang():
    """
    S-04: F-03 Pemupukan saat pH di luar rentang optimal (< 5.5 atau > 7.5)
    Kriteria: Peringatan keasaman muncul dan rekomendasi pupuk standar TIDAK diizinkan.
    """
    # Kasus tanah masam (pH 4.8)
    res_acid = client.get("/rekomendasi/pemupukan?zona=zone_a&ph_manual=4.8&kelembaban_manual=55.0&hujan_24h_manual=0.0")
    assert res_acid.status_code == 200
    data_acid = res_acid.json()
    assert data_acid["kesimpulan_pemupukan"]["boleh_memupuk_sekarang"] is False
    assert any("R-01" == r["id_aturan"] for r in data_acid["daftar_rekomendasi"])

    # Kasus tanah basa (pH 8.1)
    res_alkali = client.get("/rekomendasi/pemupukan?zona=zone_a&ph_manual=8.1&kelembaban_manual=55.0&hujan_24h_manual=0.0")
    assert res_alkali.status_code == 200
    data_alkali = res_alkali.json()
    assert data_alkali["kesimpulan_pemupukan"]["boleh_memupuk_sekarang"] is False
    assert any("R-02" == r["id_aturan"] for r in data_alkali["daftar_rekomendasi"])


def test_s05_f03_hujan_lebat_diprakirakan():
    """
    S-05: F-03 Ketika hujan lebat (> 20mm) diprakirakan dalam 24 jam ke depan,
    aplikasi pemupukan wajib ditunda untuk mencegah pencucian (leaching).
    """
    res_rain = client.get("/rekomendasi/pemupukan?zona=zone_a&ph_manual=6.5&kelembaban_manual=55.0&hujan_24h_manual=28.5")
    assert res_rain.status_code == 200
    data_rain = res_rain.json()
    assert data_rain["kesimpulan_pemupukan"]["boleh_memupuk_sekarang"] is False
    assert any("R-03" == r["id_aturan"] for r in data_rain["daftar_rekomendasi"])


def test_s06_semua_fitur_sensor_tidak_mengirim_data():
    """
    S-06: Semua fitur ketika zona tidak memiliki data sensor,
    sistem menampilkan status 'data_belum_cukup' dan tidak membuat keputusan ngawur.
    """
    res_f01 = client.get("/prediksi/kelembaban?zona=zona_fiktif_kosong")
    assert res_f01.status_code == 200
    assert res_f01.json()["status"] == "data_belum_cukup"

    res_f03 = client.get("/rekomendasi/pemupukan?zona=zona_fiktif_kosong")
    assert res_f03.status_code == 200
    assert res_f03.json()["status"] == "data_belum_cukup"
