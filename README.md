# 🌾 JagaTani - Smart Agriculture Monitoring App

> **Aplikasi Cerdas Manajemen & Pemantauan Pertanian Berbasis IoT (Zigbee & MQTT) dengan UI Neubrutalism**

Aplikasi mobile berbasis Flutter yang dirancang khusus untuk petani agar dapat memantau kondisi tanaman dan lahan secara *real-time* langsung dari smartphone tanpa perlu datang ke sawah/kebun secara fisik.

---

## 🎨 UI Style: Neubrutalism
Desain aplikasi dibangun sepenuhnya mengikuti kaidah **[Neubrutalism](https://neubrutalism.com/)**:
* **High Contrast Borders**: Garis tepi tegas $2.0\text{px} - 2.5\text{px}$ solid hitam (`#000000`).
* **Hard Sharp Drop Shadows**: Bayangan tanpa blur (`offset: Offset(4, 4)`, `blurRadius: 0`).
* **Vibrant Retro Color Palette**: Kombinasi warna cerah (Kuning `#FFD600`, Hijau Tani `#1A4D2E`, Merah Aksen, Background Krim `#FFFFF2`).
* **Chunky Typography**: Menggunakan font bold modern (`Space Grotesk`) dengan label status berbentuk badge tajam.
* **Tactile Buttons & Cards**: Komponen custom `NeuCard`, `NeuButton`, dan `NeuBadge` yang responsif terhadap ketukan (*press animation*).

---

## 🚀 Fitur Utama

### 1. 🔐 Autentikasi Petani (Login)
* Memproteksi akses data lahan pertanian.
* Terhubung langsung untuk inisialisasi koneksi aman ke **Zigbee Gateway / MQTT Broker**.

### 2. 📊 Dashboard Sensor Real-Time
Menampilkan indikator langsung dari sensor lahan:
* **🧪 Sensor pH Tanah**: Memantau tingkat keasaman tanah (Optimal: $6.0 - 7.5\text{ pH}$).
* **💧 Kelembaban Tanah**: Memantau kadar air tanah per zona lahan.
* **🌧️ Sensor Hujan (Precipitation)**: Deteksi presipitasi/hujan di kebun secara instan.
* **🌬️ Kelembaban & Suhu Udara**: Pemantauan iklim mikro sekitar tanaman.
* **⚡ Status Pompa Irigasi**: Indikator otomatis aktif/mati berdasarkan batas kelembaban tanah.

### 3. 🌤️ API Cuaca Live (Open-Meteo)
* Integrasi REST API dari **Open-Meteo** (gratis, tanpa API key).
* Menampilkan prakiraan cuaca lokal, suhu terkini, kelembaban udara sekitar, dan kecepatan angin.

### 4. 📡 Backend Koneksi Zigbee & MQTT
* **Komunikasi Lapangan**: Sensor kebun terhubung melalui jaringan nirkabel hemat daya **Zigbee**.
* **MQTT Broker**: Gateway meneruskan telemetri via MQTT topik (`jagatani/sensor/#`).
* **Fallback Telemetri Dinamis**: Dilengkapi simulasi telemetri otomatis jika broker fisik sedang dalam mode offline/demo.

---

## 🛠️ Menjalankan Aplikasi

```bash
# Pindah ke direktori proyek
cd C:\Users\Admin\eduvault\JagaTani

# Unduh dependensi
flutter pub get

# Jalankan di emulator / perangkat fisik
flutter run
```
