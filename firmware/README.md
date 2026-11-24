# JagaTani Firmware Aktuator (ESP32)

Dokumentasi firmware ESP32 untuk pengendalian relay pompa irigasi (**A-01**) dengan proteksi *hardware failsafe*.

---

## 1. Spesifikasi Hardware & Rangkaian

| Komponen | Spesifikasi / Tipe | Keterangan Sambungan |
|----------|-------------------|----------------------|
| **Mikrokontroler** | ESP32 DevKit v1 | Pin GPIO 26 (Signal Relay) |
| **Relay Modul** | 1-Channel Relay 5V Optocoupler | *Active-LOW* terisolasi |
| **Catu Daya** | Dual Power Supply (5V & 12V) | Catu daya relay & pompa dipisah dari ESP32 untuk menghindari *noise back-EMF* induktif. |
| **Pompa** | Pompa Celup / Mini DC Diaphragm 12V | Terhubung ke terminal NO (*Normally Open*) Relay |

---

## 2. Topik MQTT

- **Perintah (Subscribe):** `jagatani/aktuator/pompa/<ZONA_ID>`
  - Payload ON: `{"aksi":"on","durasi_detik":900,"id_perintah":"<uuid>"}`
  - Payload OFF: `{"aksi":"off","id_perintah":"<uuid>"}`
- **Status (Publish):** `jagatani/aktuator/status/<ZONA_ID>`
  - Payload: `{"pompa":"on"|"off","id_perintah":"<uuid>","sisa_detik":0}`

---

## 3. Matriks Skenario Uji Hardware (H-01 s.d. H-04)

| ID | Skenario Uji | Prosedur Pengujian | Kriteria Lulus |
|----|--------------|-------------------|----------------|
| **H-01** | Perintah ON 60 detik, backend/jaringan diputus | Kirim payload ON durasi 60 detik. Saat pompa menyala, matikan WiFi access point atau broker MQTT. | Pompa mati sendiri tepat setelah 60 detik oleh timer lokal firmware ESP32. |
| **H-02** | Perintah ON, backend crash | Kirim payload ON, lalu matikan proses server FastAPI. | Pompa mati otomatis setelah durasi habis, meski tanpa pesan OFF dari backend. |
| **H-03** | Reset perangkat saat pompa menyala | Nyalakan pompa, lalu tekan tombol EN/Reset fisik pada ESP32. | Setelah boot, pin relay langsung berstatus OFF (pompa tidak menyala sendiri). |
| **H-04** | Emergency Stop | Saat pompa menyala, kirim payload `{"aksi":"off","id_perintah":"..."}`. | Pompa mati dalam waktu kurang dari 1 detik. |

---

## 4. Cara Flashing ke ESP32

1. Buka Arduino IDE.
2. Install board ESP32 via Board Manager (`esp32 by Espressif Systems`).
3. Install Library yang dibutuhkan via Library Manager:
   - `PubSubClient` by Nick O'Leary
   - `ArduinoJson` (v6 atau v7) by Benoit Blanchon
4. Pilih board: `ESP32 Dev Module`.
5. Sesuaikan SSID WiFi, Password, dan IP Broker MQTT di bagian konfigurasi sketsa.
6. Klik **Upload**.
