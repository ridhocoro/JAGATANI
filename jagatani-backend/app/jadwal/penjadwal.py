"""
Modul Penjadwal Otomatis (Background Worker)
Menjalankan evaluasi berkala (setiap 15 menit) untuk zona lahan pertanian.

Aturan Mode:
- 'otomatis': Mengambil keputusan F-02, memanggil modul pengaman, dan jika lolos mengirim perintah pompa irigasi.
- 'semi_otomatis': Hanya membuat draft/rekomendasi 'diminta' yang menunggu konfirmasi manual petani (tidak kirim ke MQTT).
- 'manual': Diabaikan oleh penjadwal (tidak ada aksi).
"""
import time
import threading
import datetime
from typing import Dict, Any, List

from app.db.model_aktuator import (
    get_mode_zona,
    catat_aksi_diminta
)
from app.aktuator.perintah import evaluasi_dan_kirim_pompa
from app.api.prediksi import get_latest_zone_sensors
from app.data.cuaca import fetch_forecast_24h

_PENJADWAL_LOCK = threading.Lock()
_PENJADWAL_RUNNING = False


def proses_evaluasi_zona(zona_id: str) -> Dict[str, Any]:
    """Menjalankan siklus evaluasi keputusan untuk satu zona."""
    mode_info = get_mode_zona(zona_id)
    mode = mode_info.get("mode", "semi_otomatis")

    if mode == "manual":
        return {
            "zona_id": zona_id,
            "mode": mode,
            "status": "lewati",
            "keterangan": "Zona dalam mode manual. Penjadwal tidak melakukan intervensi."
        }

    # Ambil kondisi kelembaban dan prakiraan cuaca
    df_hist = get_latest_zone_sensors(zona_id, limit_hours=1)
    if df_hist.empty:
        return {
            "zona_id": zona_id,
            "mode": mode,
            "status": "gagal",
            "keterangan": "Tidak ada data sensor terbaru."
        }

    latest = df_hist.iloc[-1]
    soil_current = float(latest["kelembaban_tanah"])
    hujan_aktual = int(latest.get("hujan", 0))

    # Logika keputusan F-02
    weather = fetch_forecast_24h()
    rain_6h = float(weather.get("total_hujan_6jam", 0.0))

    if soil_current < 30.0 and rain_6h < 1.0 and hujan_aktual == 0:
        keputusan_f02 = "perlu"
        confidence_f02 = 0.95
        alasan_f02 = f"Kelembaban tanah rendah ({soil_current:.1f}%) dan tidak ada hujan."
    else:
        keputusan_f02 = "tidak_perlu"
        confidence_f02 = 0.90
        alasan_f02 = f"Kelembaban tanah mencukupi ({soil_current:.1f}%) atau ada hujan."

    if mode == "semi_otomatis":
        # Mode semi-otomatis: hanya buat rekomendasi status 'diminta' jika F-02 perlu
        if keputusan_f02 == "perlu":
            id_aksi = catat_aksi_diminta(
                zona_id=zona_id,
                jenis="pompa_irigasi",
                sumber="semi_otomatis",
                alasan=alasan_f02,
                durasi_menit=15,
                keputusan_f02=keputusan_f02,
                confidence_f02=confidence_f02
            )
            return {
                "zona_id": zona_id,
                "mode": mode,
                "status": "rekomendasi_dibuat",
                "id_aksi": id_aksi,
                "keterangan": "Rekomendasi irigasi dibuat menunggu persetujuan petani."
            }
        else:
            return {
                "zona_id": zona_id,
                "mode": mode,
                "status": "tidak_perlu",
                "keterangan": "Kondisi tanah optimal, tidak diperlukan rekomendasi irigasi."
            }

    elif mode == "otomatis":
        # Mode otomatis: langsung evaluasi pengaman dan eksekusi jika lolos
        hasil_siram = evaluasi_dan_kirim_pompa(
            zona_id=zona_id,
            durasi_menit=15,
            sumber="otomatis",
            context_override={
                "keputusan_f02": keputusan_f02,
                "confidence_f02": confidence_f02,
                "alasan_f02": alasan_f02,
                "prakiraan_hujan_6jam": rain_6h,
                "hujan_aktual": hujan_aktual,
                "umur_data_menit": 5.0
            }
        )
        return {
            "zona_id": zona_id,
            "mode": mode,
            "status": hasil_siram.get("status"),
            "detail": hasil_siram
        }

    return {"zona_id": zona_id, "mode": mode, "status": "selesai"}


def jalankan_siklus_penjadwal(daftar_zona: List[str] = None) -> List[Dict[str, Any]]:
    """Menjalankan evaluasi sekali untuk seluruh zona yang terdaftar."""
    zonas = daftar_zona or ["zone_a", "zone_b", "zone_c"]
    hasil = []
    # Cegah eksekusi tumpang tindih
    with _PENJADWAL_LOCK:
        for z in zonas:
            res = proses_evaluasi_zona(z)
            hasil.append(res)
    return hasil


def _loop_penjadwal(interval_detik: int = 900):
    global _PENJADWAL_RUNNING
    while _PENJADWAL_RUNNING:
        try:
            jalankan_siklus_penjadwal()
        except Exception as e:
            print(f"[Penjadwal Error] Kesalahan saat menjalankan siklus: {e}")
        time.sleep(interval_detik)


def mulai_penjadwal_background(interval_detik: int = 900):
    """Memulai worker thread background jika belum berjalan."""
    global _PENJADWAL_RUNNING
    if not _PENJADWAL_RUNNING:
        _PENJADWAL_RUNNING = True
        worker = threading.Thread(target=_loop_penjadwal, args=(interval_detik,), daemon=True)
        worker.start()
        print(f"[Penjadwal] Worker background aktif dengan interval {interval_detik} detik.")


def hentikan_penjadwal():
    global _PENJADWAL_RUNNING
    _PENJADWAL_RUNNING = False
