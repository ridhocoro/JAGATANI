import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import json
from app.main import app
from fastapi.testclient import TestClient

client = TestClient(app)

print("====================================================================")
print("HASIL PENGUJIAN VALIDASI MVP DENGAN INPUT NYATA (F-01, F-02, F-03)")
print("====================================================================")

# 1. PENGUJIAN F-01
print("\n[1] PENGUJIAN F-01: PREDIKSI KELEMBABAN 24 JAM")
r1 = client.get("/prediksi/kelembaban?zona=zone_a")
d1 = r1.json()
print("-> Status HTTP       :", r1.status_code)
print("-> Status Respons    :", d1["status"])
print("-> Zona Lahan        :", d1["zona_id"])
print("-> Nilai Terakhir    :", d1["nilai_aktual_terakhir"], "%")
print("-> Model Digunakan   :", d1["model_digunakan"], f"(MAE: {d1['evaluasi_model']['mae']}%, RMSE: {d1['evaluasi_model']['rmse']}%)")
print("-> Peringatan Stale  :", d1["peringatan_data_stale"])
print("-> Jumlah Jam Horizon:", len(d1["prediksi_24_jam"]), "jam")
print("   Jam ke-1 (+1h)    :", d1["prediksi_24_jam"][0])
print("   Jam ke-6 (+6h)    :", d1["prediksi_24_jam"][5])
print("   Jam ke-24 (+24h)   :", d1["prediksi_24_jam"][23])

# 2. PENGUJIAN F-02
print("\n[2] PENGUJIAN F-02: KLASIFIKASI KEPUTUSAN IRIGASI")

# Skenario 2A: Tanah Kering Kritis (22.5%) dan TIDAK ADA hujan (0 mm) -> Harus SIRAM
input_2a = {
    "zona_id": "zone_a",
    "kelembaban_tanah": 22.5,
    "suhu_udara": 34.0,
    "kelembaban_udara": 50.0,
    "hujan": 0,
    "prakiraan_hujan_6jam": 0.0,
    "riwayat_kelembaban": [28.0, 26.0, 24.0, 22.5] * 6
}
r2_a = client.post("/keputusan/irigasi", json=input_2a).json()
print("\nSkenario 2A (Tanah Kritis 22.5%, Tanpa Hujan):")
print("-> Keputusan        :", r2_a["keputusan"].upper())
print("-> Confidence       :", f"{r2_a['confidence']*100:.1f}%")
print("-> Rekomendasi Aksi :", r2_a["rekomendasi_aksi"])
print("-> Alasan           :", r2_a["alasan"])

# Skenario 2B: Tanah Kering (24.0%) tapi DIPRAKIRAKAN HUJAN (12 mm) -> TUNDA
input_2b = {
    "zona_id": "zone_a",
    "kelembaban_tanah": 24.0,
    "suhu_udara": 29.0,
    "kelembaban_udara": 85.0,
    "hujan": 0,
    "prakiraan_hujan_6jam": 12.0
}
r2_b = client.post("/keputusan/irigasi", json=input_2b).json()
print("\nSkenario 2B (Tanah Kering 24.0%, Ada Prakiraan Hujan 12mm):")
print("-> Keputusan        :", r2_b["keputusan"].upper())
print("-> Confidence       :", f"{r2_b['confidence']*100:.1f}%")
print("-> Rekomendasi Aksi :", r2_b["rekomendasi_aksi"])
print("-> Alasan           :", r2_b["alasan"])

# Skenario 2C: Tanah Lembab Aman (65.0%) -> TIDAK PERLU
input_2c = {
    "zona_id": "zone_a",
    "kelembaban_tanah": 65.0,
    "suhu_udara": 28.0,
    "kelembaban_udara": 78.0,
    "hujan": 0,
    "prakiraan_hujan_6jam": 0.0
}
r2_c = client.post("/keputusan/irigasi", json=input_2c).json()
print("\nSkenario 2C (Tanah Lembab 65.0%):")
print("-> Keputusan        :", r2_c["keputusan"].upper())
print("-> Confidence       :", f"{r2_c['confidence']*100:.1f}%")
print("-> Rekomendasi Aksi :", r2_c["rekomendasi_aksi"])
print("-> Alasan           :", r2_c["alasan"])

# 3. PENGUJIAN F-03
print("\n[3] PENGUJIAN F-03: SISTEM PAKAR REKOMENDASI PEMUPUKAN")

# Skenario 3A: Zona A (Padi Sawah) Kondisi Netral-Optimal (pH 6.3, Kelembaban 52%, Hujan 0mm)
r3_a = client.get("/rekomendasi/pemupukan?zona=zone_a&ph_manual=6.3&kelembaban_manual=52.0&hujan_24h_manual=0.0").json()
print("\nSkenario 3A (Zona A: Padi Sawah Kondisi Optimal):")
print("-> Status Pemupukan :", r3_a["kesimpulan_pemupukan"]["status_label"])
for at in r3_a["daftar_rekomendasi"]:
    print("   •", at["judul"], "->", at["saran_tindakan"])
    print("     Sumber:", at["sumber_aturan"])

# Skenario 3B: Zona B (Jagung) Tanah Masam (pH 4.8) -> Tunda Pupuk & Beri Dolomit
r3_b = client.get("/rekomendasi/pemupukan?zona=zone_b&ph_manual=4.8&kelembaban_manual=50.0&hujan_24h_manual=0.0").json()
print("\nSkenario 3B (Zona B: Jagung Tanah Masam pH 4.8):")
print("-> Status Pemupukan :", r3_b["kesimpulan_pemupukan"]["status_label"])
for at in r3_b["daftar_rekomendasi"]:
    print("   •", at["judul"], "->", at["saran_tindakan"])
    print("     Sumber:", at["sumber_aturan"])

# Skenario 3C: Zona C (Cabai) Prakiraan Hujan Lebat (35.0 mm) -> Tunda Cegah Leaching
r3_c = client.get("/rekomendasi/pemupukan?zona=zone_c&ph_manual=6.5&kelembaban_manual=55.0&hujan_24h_manual=35.0").json()
print("\nSkenario 3C (Zona C: Cabai Prakiraan Hujan Lebat 35mm):")
print("-> Status Pemupukan :", r3_c["kesimpulan_pemupukan"]["status_label"])
for at in r3_c["daftar_rekomendasi"]:
    print("   •", at["judul"], "->", at["saran_tindakan"])
    print("     Sumber:", at["sumber_aturan"])
