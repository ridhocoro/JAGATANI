"""
Script Uji End-to-End Fitur Aktuator & Pemupukan (A-01 & A-02)
"""
import sys
import os
import json

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from fastapi.testclient import TestClient
from app.main import app
from app.db.model_aktuator import init_aktuator_db, set_mode_zona

init_aktuator_db()
client = TestClient(app)

print("=" * 65)
print("PENGUJIAN INTEGRASI END-TO-END AKTUATOR & PEMUPUKAN (A-01 & A-02)")
print("=" * 65)

# 1. Mode Zona
set_mode_zona("zone_a", "semi_otomatis")
res = client.get("/zona/zone_a/mode")
assert res.status_code == 200
data_mode = res.json()
print(f"[1] Baca Mode Zona : {data_mode.get('mode')} (OK)")

res_put = client.put("/zona/zone_a/mode", json={"mode": "manual", "diubah_oleh": "petani"})
assert res_put.status_code == 200
print(f"[2] Ubah Mode Zona : {res_put.json().get('data', {}).get('mode')} (OK)")

# Kembalikan ke semi_otomatis
client.put("/zona/zone_a/mode", json={"mode": "semi_otomatis", "diubah_oleh": "sistem"})

# 2. Trigger Pompa (Normal flow)
res_pompa = client.post("/aktuator/pompa", json={
    "zona_id": "zone_a",
    "durasi_menit": 15,
    "sumber": "manual"
})
assert res_pompa.status_code == 200
hasil_pompa = res_pompa.json()
print(f"[3] Trigger Pompa  : Status={hasil_pompa.get('status')} | Dikirim={hasil_pompa.get('perintah_dikirim')} (OK)")

# 3. Emergency Stop (Matikan Pompa Segera)
res_off = client.post("/aktuator/pompa/matikan", json={
    "zona_id": "zone_a",
    "sumber": "manual"
})
assert res_off.status_code == 200
print(f"[4] Emergency Stop : {res_off.json().get('pesan')} (OK)")

# 4. Status Pompa Real-Time
res_status = client.get("/aktuator/status/zone_a")
assert res_status.status_code == 200
print(f"[5] Status Realtime: Pompa={res_status.json().get('data', {}).get('pompa')} (OK)")

# 5. Catat Pemupukan (A-02)
res_pupuk_valid = client.post("/pemupukan/catat", json={
    "zona_id": "zone_a",
    "jenis_pupuk": "NPK 15-15-15 + Urea",
    "dosis": "150 kg/ha",
    "id_rekomendasi_f03": "R-05",
    "petani_setuju": True
})
assert res_pupuk_valid.status_code == 200
print(f"[6] Catat Pemupukan: {res_pupuk_valid.json().get('pesan')} (OK)")

# Catat Pemupukan Tidak Valid (tanpa dosis)
res_pupuk_invalid = client.post("/pemupukan/catat", json={
    "zona_id": "zone_a",
    "jenis_pupuk": "NPK 15-15-15",
    "dosis": "",
    "petani_setuju": True
})
assert res_pupuk_invalid.status_code == 400
print(f"[7] Validasi Pupuk : Berhasil tolak dosis kosong ({res_pupuk_invalid.json().get('detail')}) (OK)")

# 6. Baca Riwayat Aksi
res_riwayat = client.get("/aktuator/riwayat?zona=zone_a&limit=5")
assert res_riwayat.status_code == 200
riwayat = res_riwayat.json().get("data", [])
print(f"[8] Riwayat Aksi   : Total {len(riwayat)} entri log ditemukan di SQLite:")
for item in riwayat[:3]:
    print(f"    • [{item.get('waktu')}] {item.get('jenis')} ({item.get('status')}): {item.get('alasan') or item.get('alasan_tolak')}")

print("\nSELURUH 8 INTEGRATION CHECKS SUKSES 100%!")
