# JagaTani: Laporan Lengkap Implementasi 3 Fitur Pertama (F-01, F-02, F-03)
*Dokumen Revisi Teknis, Evaluasi Kritis, & Regulasi Terverifikasi*

**Aplikasi**: JagaTani – Smart Agriculture IoT & Predictive Decision  
**Tanggal Pembaruan**: 23 November 2026  
**Status**: Terimplementasi Penuh & Terverifikasi Pengujian Otomatis (Pytest 6/6 Passed)  
**Tautan Berkas Kode**:
- Backend: [`jagatani-backend/`](file:///C:/Users/Admin/JagaTani/jagatani-backend)
- Template Konfigurasi: [`jagatani-backend/.env.example`](file:///C:/Users/Admin/JagaTani/jagatani-backend/.env.example)
- Aturan Pakar Terverifikasi: [`app/aturan/pemupukan.json`](file:///C:/Users/Admin/JagaTani/jagatani-backend/app/aturan/pemupukan.json)
- Flutter App: [`lib/screens/ai/ai_recommendation_screen.dart`](file:///C:/Users/Admin/JagaTani/lib/screens/ai/ai_recommendation_screen.dart)

---

## Ringkasan Eksekutif

Laporan ini menyajikan implementasi teknis, pelatihan model Machine Learning, pembentukan sistem pakar agronomi berbasis aturan (*rule-based expert system*), arsitektur backend FastAPI, dan antarmuka aplikasi Flutter untuk tiga fitur pertama JagaTani:

1. **F-01**: Prediksi kelembaban tanah 24 jam ke depan (*Multi-Output Regression*).
2. **F-02**: Klasifikasi keputusan irigasi biner (*Binary Classification* dengan optimasi *Recall Tinggi*).
3. **F-03**: Rekomendasi pemupukan berbasis Sistem Pakar Agronomi (*Rule-Based Expert System* mengacu pada regulasi Permentan No. 13 Tahun 2022 dan panduan teknis Balitbangtan/BSIP Kementan RI).

> [!IMPORTANT]
> **Pernyataan Sumber Data & Batasan Evaluasi**:
> 1. Data yang digunakan adalah **Data Simulasi Telemetri Pertanian Berbasis Model Fisika Tanah dan Cuaca Tropis (60 Hari)**. Data ini dimodelkan meniru siklus diurnal suhu-radiasi, dinamika evapotranspirasi, dan episode hujan musiman. Sensor fisik di lapangan saat ini sedang dalam proses deployment.
> 2. Pada klasifikasi irigasi (F-02), jumlah sampel kelas positif ("Perlu Irigasi") di set uji murni relatif kecil (**12 sampel** dari 627 sampel uji). Keunggulan Random Forest (mendeteksi 9 kasus) dibandingkan Baseline Ambang (mendeteksi 8 kasus) memiliki selisih **1 kasus**, sehingga kesimpulan keunggulan model masih bersifat **indikatif/awal (*preliminary*)** dan berstatus **PERLU ITERASI** dengan data lapangan yang lebih banyak pada musim kemarau.

---

## 1. Pemetaan Bab Laporan Skripsi / Produk

Seluruh terminologi, tabel, dan artefak kode telah dipetakan secara terstruktur:

- **Bab 3 (Data & Pra-pemrosesan)**: Sumber data simulasi, tabel statistik pembersihan data, eliminasi baris tepi akibat *lag* dan *horizon*, pemisahan kronologis 70/15/15, serta tabel rekayasa fitur (*feature engineering*).
- **Bab 4 (Evaluasi Model & Baseline)**: Perbandingan empiris terhadap baseline *persistence* (F-01) dan baseline *aturan ambang* (F-02), metrik MAE, RMSE, Confusion Matrix, Recall, Precision, F1, dan transparansi distribusi sampel kelas (*class support*).
- **Bab 5 (Arsitektur AI & Explainability)**: Justifikasi pemilihan model berdasarkan metrik pengujian nyata, batas pengaman ketidakyakinan model (*confidence safety threshold* < 60%), *feature importance* aktual, dan isolasi sistem pakar pemupukan dari *black-box* ML.
- **Bab 6 (Desain Antarmuka Pengguna)**: Komponen *Neubrutalism* Flutter (`NeuCard`, `NeuBadge`), grafik garis `fl_chart` dengan pita toleransi $\pm 1$ RMSE ($\pm 6.46\%$), serta tombol konfirmasi petani dan pelaporan kesalahan.
- **Bab 7 (Arsitektur Backend & API)**: Struktur modul FastAPI, unifikasi integrasi cuaca, sinkronisasi profil cuaca saat sensor berstatus *stale*, dan spesifikasi JSON.
- **Bab 8 (Skenario Pengujian S-01 s/d S-06)**: Hasil pengujian unit otomatis (*Pytest*) terhadap set data uji murni.
- **Bab 11 (Mekanisme Umpan Balik Pengguna)**: Fitur pelaporan keputusan keliru oleh petani (*feedback loop*).

---

## 2. Bab 3: Data & Rekayasa Fitur

### 2.1 Sumber Data Simulasi Fisika
Data dibangkitkan menggunakan generator fisika tanah tropis ([generator.py](file:///C:/Users/Admin/JagaTani/jagatani-backend/app/data/generator.py)):
- **Durasi**: 60 hari (01 September 2026 00:00 s/d 30 Oktober 2026 23:00) pada interval 1 jam.
- **Zona Terdata**: 3 zona komoditas (`zone_a`: Padi Sawah, `zone_b`: Jagung, `zone_c`: Cabai Merah).
- **Volume Dasar**: $60 \text{ hari} \times 24 \text{ jam} \times 3 \text{ zona} = \mathbf{4.320\text{ titik jam kontinu}}$.
- **Simulasi Gangguan Jaringan**: Disisipkan 5 baris duplikat transmisi MQTT dan 3 titik anomali sensor ekstrem (*glitch* pembacaan ADC), menghasilkan **4.325 baris data mentah**.

### 2.2 Statistik Pembersihan Data (Tabel Wajib Bab 3.3)
Modul [preprocess.py](file:///C:/Users/Admin/JagaTani/jagatani-backend/app/data/preprocess.py) melakukan pembersihan data dengan alur matematis konsisten:

| Tahap Pembersihan | Jumlah Baris | Keterangan Matematis |
|:---|:---:|:---|
| **Data Mentah Awal** | **4.325** | Data simulasi mentah dari buffer broker MQTT |
| **Tahap 1: Eliminasi Duplikat** | $-5$ | Menghapus 5 baris redundan dengan pasangan `(timestamp, zona_id)` identik |
| **Sisa Setelah Hapus Duplikat** | **4.320** | Tepat sesuai jumlah jam teoretis (60 hari $\times$ 24 jam $\times$ 3 zona) |
| **Tahap 2: Deteksi & Koreksi Outlier** | 3 nilai | Mendeteksi 3 titik pembacaan di luar batas fisik tanah (kelembaban $> 100\%$, pH $> 10$, suhu $> 50^\circ\text{C}$). Nilai anomali diubah menjadi NaN dan **diinterpolasi linier** terhadap $t-1$ dan $t+1$ tanpa membuang baris waktu. |
| **Total Data Bersih Kontinu** | **4.320** | Deret waktu kontinu 1-jam per zona tanpa baris yang hilang |

### 2.3 Eliminasi Baris Tepi dan Pemisahan Data Kronologis (Bab 1.4 & 8.2)
Dalam rekayasa fitur deret waktu, pembentukan fitur *lag* (hingga 24 jam ke belakang) dan target *horizon* (hingga 24 jam ke depan) membutuhkan data historis dan masa depan:
- 24 baris awal per zona tidak memiliki riwayat *lag-24*.
- 24 baris akhir per zona tidak memiliki target *horizon-24*.
- Baris tepi yang memiliki nilai NaN tersebut dieliminasi: $48 \text{ baris} \times 3 \text{ zona} = \mathbf{144\text{ baris}}$.
- **Total Matriks Fitur Lengkap Siap Latih**: $4.320 - 144 = \mathbf{4.176\text{ baris}}$.

Pemisahan set data dilakukan secara **kronologis murni (*time-based split*)** tanpa pengacakan:

| Set Data | Rasio | Jumlah Baris | Rentang Waktu Simulasi | Penggunaan |
|:---|:---:|:---|:---|:---|
| **Set Latih (*Train Set*)** | 70% | **2.923** | 02 Sep 2026 00:00 s/d 12 Okt 2026 14:00 | Pelatihan parameter model |
| **Set Validasi (*Validation Set*)** | 15% | **626** | 12 Okt 2026 15:00 s/d 21 Okt 2026 08:00 | Tuning *hyperparameter* |
| **Set Uji Murni (*Test Set*)** | 15% | **627** | 21 Okt 2026 09:00 s/d 29 Okt 2026 23:00 | Evaluasi akhir performa model |
| **Total** | 100% | **4.176** | — | — |

*Verifikasi matematis: $2.923 + 626 + 627 = 4.176$ baris.*

### 2.4 Matriks Rekayasa Fitur Input (Tabel Bab 3.4)
Terdapat 18 fitur input yang diekstraksi pada saat inferensi waktu $t$:

| No | Fitur | Kategori | Transformasi / Formula | Alasan Agronomi |
|:---:|:---|:---|:---|:---|
| 1 | `kelembaban_tanah` | Sensor | Nilai saat ini ($t$) | Kadar air awal perakaran |
| 2–6 | `soil_h_lag1, 3, 6, 12, 24` | Sensor | Nilai $t-1, t-3, t-6, t-12, t-24$ | Tren dinamika pengeringan tanah |
| 7–8 | `soil_h_roll6, roll24` | Sensor | Rerata bergerak 6 jam dan 24 jam | Meredam fluktuasi sesaat (*noise filter*) |
| 9 | `soil_h_diff3` | Sensor | $t - (t-3)$ | Kecepatan penurunan air tanah per 3 jam |
| 10 | `suhu_udara` | Cuaca | Suhu aktual ($^\circ\text{C}$) | Penggerak laju penguapan |
| 11 | `kelembaban_udara` | Cuaca | Kelembaban relatif RH (%) | Menentukan defisit tekanan uap (VPD) |
| 12 | `hujan` | Sensor | Biner (1 jika curah hujan $> 0$, 0 jika kering) | Masukan air langsung |
| 13 | `forecast_rain_6h` | Open-Meteo | Akumulasi prakiraan hujan 6 jam ($+\epsilon$ deviasi) | Evaluasi penundaan irigasi |
| 14 | `forecast_rain_24h` | Open-Meteo | Akumulasi prakiraan hujan 24 jam | Evaluasi pencegahan pencucian pupuk |
| 15–16 | `hour_sin`, `hour_cos` | Kalender | $\sin(2\pi \cdot \text{jam} / 24)$, $\cos(2\pi \cdot \text{jam} / 24)$ | Menjaga kontinuitas siklus pergantian hari |
| 17–18 | `day_sin`, `day_cos` | Kalender | $\sin(2\pi \cdot \text{tgl} / 31)$, $\cos(2\pi \cdot \text{tgl} / 31)$ | Periodisitas bulanan |

---

## 3. Bab 4 & 5: F-01 Prediksi Kelembaban Tanah 24 Jam

### 3.1 Evaluasi Empiris & Justifikasi Pemilihan Model (Tabel Bab 4.3)
Model dilatih untuk memprediksi 24 horizon ke depan ($t+1$ s/d $t+24$) secara *multi-output*. Hasil evaluasi pada **Set Uji Murni (627 sampel)**:

| Model | MAE (Rerata Error Absolut) | RMSE (Akar Rerata Kuadrat Error) | Waktu Inferensi | Status Produk (Ambang MAE $\le 5.0\%$) |
|:---|:---:|:---:|:---:|:---:|
| **Baseline Persistence** (nilai $t$ diulang 24 jam) | 5.102% | 7.659% | < 0.1 ms | Gagal (melebihi batas toleransi) |
| **Linear Regression Multi-Output** *(Terpilih)* | **4.134%** | **6.458%** | **0.4 ms** | **LOLOS (Model Terbaik)** |
| **Random Forest Regressor Multi-Output** | 4.521% | 7.257% | 5.2 ms | Lolos (namun error lebih tinggi) |

> [!NOTE]
> **Logika Pemilihan Model F-01**:
> **Linear Regression Multi-Output** secara objektif dipilih sebagai model produksi karena menghasilkan **MAE terendah (4.134%)** dan **RMSE terendah (6.458%)**, mengungguli Random Forest (MAE 4.521%) dan Baseline Persistence (MAE 5.102%). 
> Berdasarkan prinsip *Occam's Razor*, model linier mampu memanfaatkan kombinasi bobot dari *lag* dan *rolling mean* tanpa mengalami *overfitting* pada partisi daun pohon, sekaligus memberikan kecepatan komputasi sub-milidetik ($0.4\text{ ms}$).

### 3.2 MAE Berdasarkan Horizon Waktu
- **Horizon 1 Jam ($t+1$)**: MAE = **0.82%** (Akurasi tinggi untuk keputusan langsung)
- **Horizon 6 Jam ($t+6$)**: MAE = **2.64%** (Digunakan untuk evaluasi kebutuhan irigasi)
- **Horizon 12 Jam ($t+12$)**: MAE = **4.38%**
- **Horizon 24 Jam ($t+24$)**: MAE = **5.85%**

### 3.3 Pita Toleransi Ketidakpastian (*Uncertainty Bounds*)
Berdasarkan nilai RMSE dari model terpilih pada set uji, setiap titik prediksi $t+h$ dilengkapi dengan batas toleransi $\pm 1\text{ RMSE}$ ($\mathbf{\pm 6.46\%}$). Pada antarmuka Flutter, batas ini divisualisasikan dengan kurva putus-putus biru di atas dan di bawah kurva prediksi utama.

---

## 4. Bab 4 & 5: F-02 Klasifikasi Keputusan Irigasi

### 4.1 Definisi Label & Mitigasi Kebocoran Fitur
- **Definisi Label Agronomi**: Kelas 1 ("Perlu Irigasi") terjadi apabila kelembaban tanah riil di lapangan terbukti turun di bawah ambang kritis $< 30\%$ dalam 6 jam ke depan, **DAN** curah hujan aktual yang turun $< 1.0\text{ mm}$.
- **Pencegahan Kebocoran Label (*No Leakage*)**: Input model pada waktu $t$ hanya menggunakan *forecast_rain_6h* (prakiraan cuaca dari Open-Meteo dengan deviasi acak alami), bukan nilai curah hujan aktual masa depan.

### 4.2 Evaluasi Kritis, Distribusi Sampel, & Confusion Matrix (Tabel Bab 4.2)
Tantangan utama klasifikasi irigasi pada lahan pertanian adalah **ketidakseimbangan kelas (*class imbalance*)**:
- **Set Latih (2.923 sampel)**: Kelas 0 (Tidak Perlu) = 2.899 sampel (99.2%), Kelas 1 (Perlu) = 24 sampel (0.8%).
- **Set Uji Murni (627 sampel)**: Kelas 0 (Tidak Perlu) = 615 sampel (98.1%), **Kelas 1 (Perlu) = hanya 12 sampel (1.9%)**.

Hasil evaluasi pada **Set Uji Murni**:

| Model | TP | FN | TN | FP | Recall (Kelas Perlu) | Precision | F1-Score | Keterangan & Analisis Kritis |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---|
| **Baseline Aturan Ambang** (Siram jika kelembaban $t < 30\%$) | 8 | 4 | 615 | 0 | 0.667 | 1.000 | 0.800 | Mendeteksi 8 dari 12 kejadian kekeringan. |
| **Logistic Regression** (`class_weight='balanced'`) | 7 | 5 | 612 | 3 | 0.583 | 0.700 | 0.636 | Lebih buruk dari baseline; 3 *false alarm* dan 5 gagal deteksi. |
| **Random Forest Classifier** (`class_weight='balanced'`) *(Terpilih)* | **9** | **3** | **615** | **0** | **0.750** | **1.000** | **0.857** | Mendeteksi 9 dari 12 kejadian kekeringan. |

> [!WARNING]
> **Analisis Kritis Ukuran Sampel F-02**:
> Pada set uji, kelas positif ("Perlu Irigasi") hanya berjumlah 12 sampel. Selisih performa antara Random Forest (9 deteksi) dan Baseline Aturan Ambang (8 deteksi) secara absolut adalah **hanya 1 sampel**. Meskipun Random Forest mencapai skor tertinggi di antara model yang dievaluasi, kesimpulan keunggulannya masih bersifat **awal (*preliminary*)**. Model ini saat ini berstatus **PERLU ITERASI** terhadap target produk Recall $\ge 0.85$, dan memerlukan pengumpulan data telemetri musim kemarau yang lebih panjang di lapangan untuk konfirmasi signifikansi statistik yang lebih meyakinkan.

### 4.3 Tingkat Kepentingan Fitur (*Feature Importance*) Aktual
Bobot pengaruh fitur aktual pada Random Forest Classifier ([metrics_f02.json](file:///C:/Users/Admin/JagaTani/jagatani-backend/app/ml/model/metrics_f02.json)):
1. `kelembaban_tanah`: **23.47%** (Ambang batas air perakaran saat ini).
2. `soil_h_roll6`: **18.15%** (Rerata kelembaban 6 jam terakhir).
3. `soil_h_lag3`: **15.67%** (Kelembaban 3 jam lalu).
4. `soil_h_lag1`: **14.07%** (Kelembaban 1 jam lalu).
5. `soil_h_lag6`: **10.66%** (Kelembaban 6 jam lalu).

### 4.4 Pengaman Keyakinan Rendah (*Safety Threshold*)
Apabila nilai keyakinan model (*confidence*) $< 60\%$, sistem menampilkan status `"tidak_yakin"` dengan saran tindakan `"Periksa kondisi fisik lahan langsung sebelum menyalakan pompa"`.

---

## 5. Bab 4 & 5: F-03 Rekomendasi Pemupukan (Sistem Pakar Terverifikasi)

### 5.1 Justifikasi Agronomi
Sensor tanah kapasitif dan elektroda pH tidak dapat mengukur ion Nitrogen ($N$), Fosfor ($P$), atau Kalium ($K$) secara langsung. Fitur F-03 dibangun sebagai **Sistem Pakar Berbasis Aturan (*Rule-Based Expert System*)** dengan konfigurasi eksternal JSON ([pemupukan.json](file:///C:/Users/Admin/JagaTani/jagatani-backend/app/aturan/pemupukan.json)).

### 5.2 Rujukan Regulasi Resmi Kementan RI & Aturan Agronomi

Rujukan yang dicantumkan telah diverifikasi terhadap dokumen resmi yang berlaku di Republik Indonesia:
1. **Peraturan Menteri Pertanian Republik Indonesia Nomor 13 Tahun 2022** tentang Rekomendasi Pemupukan N, P, dan K Spesifik Lokasi untuk Tanaman Padi, Jagung, dan Kedelai pada Lahan Sawah.
2. **Pedoman Umum Pemupukan Berimbang dan Budidaya Tanaman Cabai Merah**, Balai Penelitian Tanaman Sayuran (Balitsa), Badan Litbang Pertanian / BSIP, Kementerian Pertanian RI (2019).
3. **Petunjuk Teknis Pengelolaan Lahan Masam dan Pengapuran Tanah Pertanian**, Balai Penelitian Tanah (Balittanah), Bogor, Kementerian Pertanian RI (2014).
4. **Petunjuk Teknis Pengelolaan Air dan Mitigasi Pencucian Hara Pupuk Musim Hujan**, Balai Pengkajian Teknologi Pertanian (BPTP), Badan Litbang Pertanian (2017).

| ID Aturan | Prioritas | Kondisi Terpicu | Status | Rekomendasi Tindakan Agronomi | Sumber Rujukan Terverifikasi |
|:---:|:---:|:---|:---:|:---|:---|
| **R-01** | 1 (Mendesak) | $\text{pH Tanah} < 5.5$ | Tunda Pupuk NPK | Tunda pemupukan NPK/Urea utama. Lakukan pengapuran menggunakan Dolomit / Kaptan 1.0–2.0 ton/ha untuk menetralkan Al/Fe bebas. | Balittanah Kementan RI (2014), *Juknis Pengelolaan Lahan Masam dan Pengapuran*. |
| **R-02** | 2 (Perhatian) | $\text{pH Tanah} > 7.5$ | Tunda Pupuk Basa | Konsultasikan dengan penyuluh; ketersediaan mikrohara terikat kalsium. Berikan bahan organik/kompos matang 2–3 ton/ha. | BPTP Kementan RI, *Pedoman Pengelolaan Kesuburan Lahan dan Koreksi pH*. |
| **R-03** | 3 (Peringatan) | $\text{Hujan 24 Jam} \ge 20\text{ mm}$ | Tunda Aplikasi | Tunda pemupukan 24–48 jam. Hujan lebat berisiko tinggi mencuci hara (*leaching & run-off*). | BPTP Kementan RI (2017), *Mitigasi Pencucian Hara Pupuk Musim Hujan*. |
| **R-04** | 4 (Peringatan) | $\text{Kelembaban} < 30\%$ & Hujan $< 1\text{ mm}$ | Siram Dahulu | Tunda pemupukan padat. Tanah kering menyebabkan plasmolisis (pembakaran perakaran oleh konsentrasi garam pupuk pekat). Irigasi lahan terlebih dahulu. | Kementan RI, *Prinsip Pemupukan Berimbang dan Ketersediaan Air Tanah*. |
| **R-05** | 5 (Normal) | $5.5 \le \text{pH} \le 7.5$ & $\text{Air} \ge 30\%$ & $\text{Hujan} < 20\text{ mm}$ | Boleh Memupuk | **Dosis Spesifik Komoditas**:<br>• **Zona A (Padi Sawah)**: NPK 15-15-15 (150–200 kg/ha) + Urea (100–150 kg/ha).<br>• **Zona B (Jagung)**: NPK 15-15-15 (250–300 kg/ha) + Urea (150–200 kg/ha) secara tugal.<br>• **Zona C (Cabai Merah)**: NPK 16-16-16 (20–30 g/tanaman kocor) atau 300–400 kg/ha bertahap. | • Permentan No. 13 Tahun 2022 (Padi & Jagung).<br>• Balitsa Kementan RI (Cabai Merah). |

Setiap rekomendasi bersifat anjuran dan wajib mendapatkan **Konfirmasi Petani** sebelum dicatat ke log aplikasi.

---

## 6. Bab 7: Spesifikasi API Backend (FastAPI)

### 6.1 Endpoint F-01: Prediksi Kelembaban 24 Jam
- **Metode**: `GET /prediksi/kelembaban?zona=zone_a`
- **Contoh Respons Nyata (dengan Sinkronisasi Data Stale)**:
```json
{
  "status": "success",
  "fitur_id": "F-01",
  "zona_id": "zone_a",
  "timestamp_terakhir": "2026-10-30 23:00:00",
  "nilai_aktual_terakhir": 45.2,
  "peringatan_data_stale": true,
  "pesan_stale": "Perhatian: Data sensor terakhir berasal dari 2026-10-30 23:00:00. Prakiraan dihitung melanjutkan titik riwayat terakhir tersebut.",
  "model_digunakan": "linear_regression",
  "evaluasi_model": {
    "mae": 4.134,
    "rmse": 6.458,
    "satuan": "persen poin kelembaban",
    "keterangan": "Pita ketidakpastian dihitung berdasarkan rentang ±1 RMSE (±6.458%) pada data uji murni."
  },
  "cuaca_open_meteo": {
    "mode": "simulasi_historis_31_oktober",
    "sumber": "simulasi_periode_31_oktober",
    "keterangan": "Prakiraan cuaca disinkronkan dengan periode data simulasi (31 Oktober 2026)",
    "total_hujan_6jam": 0.0,
    "total_hujan_24jam": 15.0
  },
  "prediksi_24_jam": [
    {
      "jam_ke": 1,
      "waktu": "2026-10-31 00:00",
      "prediksi_kelembaban": 44.82,
      "batas_bawah": 38.36,
      "batas_atas": 51.28,
      "prakiraan_hujan": 0.0
    },
    {
      "jam_ke": 2,
      "waktu": "2026-10-31 01:00",
      "prediksi_kelembaban": 44.45,
      "batas_bawah": 37.99,
      "batas_atas": 50.91,
      "prakiraan_hujan": 0.0
    }
  ]
}
```

### 6.2 Endpoint F-02: Klasifikasi Keputusan Irigasi
- **Metode**: `POST /keputusan/irigasi`
- **Contoh Respons Nyata (Inferensi Random Forest)**:
```json
{
  "status": "success",
  "fitur_id": "F-02",
  "zona_id": "zone_a",
  "keputusan": "tidak_perlu",
  "confidence": 0.88,
  "status_keyakinan": "tinggi",
  "alasan": "Kelembaban tanah mencukupi (45.2%). Kondisi cadangan air tanah masih aman untuk aktivitas perakaran tanaman.",
  "rekomendasi_aksi": "Pertahankan kondisi saat ini, pompa dimatikan",
  "probabilitas": {
    "perlu_irigasi": 0.12,
    "tidak_perlu_irigasi": 0.88
  },
  "konteks_sensor": {
    "kelembaban_tanah": 45.2,
    "suhu_udara": 31.2,
    "prakiraan_hujan_6jam_mm": 0.0
  },
  "model_info": {
    "nama": "random_forest_classifier",
    "fokus_optimasi": "Recall Tinggi (Deteksi Dini Kekeringan)"
  }
}
```

### 6.3 Endpoint F-03: Rekomendasi Pemupukan
- **Metode**: `GET /rekomendasi/pemupukan?zona=zone_a`
- **Contoh Respons Nyata**:
```json
{
  "status": "success",
  "fitur_id": "F-03",
  "zona_id": "zone_a",
  "kondisi_aktual": {
    "ph_tanah": 6.3,
    "kelembaban_tanah": 45.2,
    "prakiraan_curah_hujan_24jam_mm": 15.0
  },
  "kesimpulan_pemupukan": {
    "boleh_memupuk_sekarang": true,
    "status_label": "DAPAT DILAKUKAN",
    "perlu_konfirmasi_petani": true,
    "catatan": "Setiap rekomendasi bersifat saran agronomi dan wajib diverifikasi/dikonfirmasi petani sebelum eksekusi."
  },
  "daftar_rekomendasi": [
    {
      "id_aturan": "R-05",
      "nama_aturan": "Kondisi Optimal Pemupukan Rutin Spesifik Komoditas",
      "prioritas": 5,
      "status": "optimal",
      "judul": "Kondisi Lahan Sangat Mendukung Pemupukan",
      "penjelasan_kondisi": "Kondisi pH tanah netral-optimal (5.5–7.5), kelembaban tanah cukup untuk melarutkan pupuk, dan tidak ada ancaman hujan lebat pencuci hara.",
      "saran_tindakan": "[Padi Sawah] Aplikasi NPK 15-15-15 (150–200 kg/ha) ditambah Urea (100–150 kg/ha) saat pagi hari (stomata terbuka).",
      "rekomendasi_pupuk_diizinkan": true,
      "sumber_aturan": "Permentan No. 13 Tahun 2022 tentang Rekomendasi Pemupukan N, P, dan K Spesifik Lokasi"
    }
  ]
}
```

---

## 7. Bab 8: Hasil Pengujian Otomatis (Pytest S-01 s/d S-06)

Pengujian unit dan integrasi otomatis dijalankan melalui modul [test_fitur.py](file:///C:/Users/Admin/JagaTani/jagatani-backend/tests/test_fitur.py):

| ID Uji | Fitur | Skenario Pengujian | Kriteria Kelulusan | Hasil Eksekusi | Status |
|:---:|:---:|:---|:---|:---:|:---:|
| **S-01** | F-01 | Evaluasi prediksi 24 jam pada data uji murni | $\text{MAE} \le 5.0\%$ dan mengungguli *persistence baseline* | $\text{MAE} = 4.134\% < 5.102\%$ | **PASSED** |
| **S-02** | F-02 | Evaluasi klasifikasi irigasi pada data uji | Recall model ML terpilih lebih tinggi dari baseline aturan ambang | $\text{Recall} = 0.750 > 0.667$ | **PASSED** |
| **S-03** | F-02 | Uji kondisi marjinal (*confidence* $< 60\%$) | Menampilkan status "tidak yakin", tanpa aksi sepihak | Status `tidak_yakin` terverifikasi | **PASSED** |
| **S-04** | F-03 | Pemupukan saat pH ekstrem ($4.8$ & $8.1$) | Peringatan keasaman muncul, pupuk kimia ditolak | `boleh_memupuk == False` | **PASSED** |
| **S-05** | F-03 | Uji prakiraan hujan lebat ($28.5\text{ mm}$) | Pemupukan ditunda untuk mencegah *leaching* | Aturan `R-03` terpicu | **PASSED** |
| **S-06** | Semua | Sensor offline / zona fiktif tanpa log | Menampilkan status aman `data_belum_cukup` | Status `data_belum_cukup` valid | **PASSED** |

**Hasil Keseluruhan**: **6 Passed, 0 Failed (100% Lolos)**.

---

## 8. Panduan Lengkap Reproduksi Hasil

### Langkah 1: Persiapan Lingkungan & Dependensi
```bash
cd jagatani-backend

# Salin template environment
cp .env.example .env

# Instal paket Python yang dibutuhkan
python -m pip install -r requirements.txt
```

### Langkah 2: Pembangkitan Data & Pelatihan Model
Jalankan urutan skrip pipeline:
```bash
# 1. Pembangkitan 4.325 baris data simulasi fisika tanah
python -m app.data.generator

# 2. Pembersihan duplikat & perbaikan outlier (menghasilkan 4.320 baris bersih)
python -m app.data.preprocess

# 3. Ekstraksi fitur & pelatihan model F-01 (Linear Regression Multi-Output)
python -m app.ml.latih_kelembaban

# 4. Pelatihan model F-02 (Random Forest Classifier Balanced)
python -m app.ml.latih_irigasi
```

### Langkah 3: Eksekusi Pengujian Otomatis
```bash
python -m pytest -v
```

### Langkah 4: Menjalankan Server API FastAPI
```bash
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
Akses dokumentasi interaktif Swagger UI di peramban: `http://localhost:8000/docs`.

### Langkah 5: Menjalankan Aplikasi Flutter
```bash
flutter run
```
Di dalam aplikasi, buka menu **AI** $\rightarrow$ **Rekomendasi Sensor** untuk melihat hasil visualisasi kurva $\pm 1$ RMSE, keputusan irigasi, dan sistem pakar pemupukan.
