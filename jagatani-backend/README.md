# JagaTani AI & Decision Backend

Backend Machine Learning dan Sistem Pakar untuk **JagaTani - Smart Agriculture IoT**.
Menyediakan layanan inferensi prediktif dan keputusan cerdas untuk 3 fitur utama:

- **F-01**: Prediksi kelembaban tanah 24 jam ke depan (*Random Forest Regressor Multi-Output* + Prakiraan Cuaca Open-Meteo).
- **F-02**: Klasifikasi keputusan irigasi biner: perlu / tidak perlu disiram (*Random Forest Classifier* dengan optimasi *High Recall*).
- **F-03**: Rekomendasi pemupukan berbasis Sistem Pakar (*Rule-Based Expert System* SNI/BPTP/Kementan RI) terisolasi di berkas konfigurasi `app/aturan/pemupukan.json`.

---

## 1. Persyaratan Sistem
- Python 3.10+
- Virtualenv (opsional namun disarankan)

## 2. Instalasi Dependensi
```bash
cd jagatani-backend
python -m pip install -r requirements.txt
```

## 3. Menjalankan Generator Data & Pelatihan Model
Untuk menghasilkan data sintetis realistis iklim tropis dan melatih model:
```bash
# 1. Generate log sensor realistis (60 hari)
python -m app.data.generator

# 2. Pembersihan & pemisahan data 70/15/15 time-based
python -m app.data.preprocess

# 3. Latih F-01 (Prediksi 24 Jam)
python -m app.ml.latih_kelembaban

# 4. Latih F-02 (Klasifikasi Keputusan Irigasi)
python -m app.ml.latih_irigasi
```

## 4. Menjalankan Server API FastAPI
```bash
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
Akses dokumentasi interaktif Swagger UI di:
`http://localhost:8000/docs`

## 5. Ringkasan Endpoint API

### 1. F-01: Prediksi Kelembaban 24 Jam
- **Metode**: `GET`
- **Path**: `/prediksi/kelembaban?zona=zone_a`
- **Output**: Array 24 jam dengan batas ketidakpastian (±1 RMSE) dan prakiraan hujan per jam.

### 2. F-02: Klasifikasi Keputusan Irigasi
- **Metode**: `POST`
- **Path**: `/keputusan/irigasi`
- **Body**:
  ```json
  {
    "zona_id": "zone_a",
    "kelembaban_tanah": 29.5,
    "suhu_udara": 31.2,
    "kelembaban_udara": 70.0,
    "hujan": 0
  }
  ```
- **Output**: Keputusan (`perlu` / `tidak_perlu` / `tidak_yakin`), skor keyakinan (*confidence*), dan penjelasan agronomi (*explainable reason*).

### 3. F-03: Rekomendasi Pemupukan
- **Metode**: `GET`
- **Path**: `/rekomendasi/pemupukan?zona=zone_a`
- **Output**: Rekomendasi pemupukan, status pengapuran, status penundaan akibat hujan/tanah kering, dan sumber aturan resmi.

---

## 6. Menjalankan Pengujian (S-01 s/d S-06)
```bash
python -m pytest -v
```
Seluruh 6 skenario pengujian diverifikasi secara otomatis:
- `S-01`: MAE F-01 <= 5.0% dan lebih akurat dari baseline persistence.
- `S-02`: Recall F-02 >= 0.85 (mencegah kekeringan tanaman).
- `S-03`: F-02 status "tidak yakin" saat confidence di bawah 60%.
- `S-04`: F-03 memicu peringatan jika pH di luar rentang (masam / basa).
- `S-05`: F-03 menunda pemupukan jika diprakirakan hujan lebat (> 20mm).
- `S-06`: Penanganan aman saat sensor offline / data belum cukup.
