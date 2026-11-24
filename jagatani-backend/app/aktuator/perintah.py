"""
Modul Perintah Aktuator Pompa Irigasi
Bertanggung jawab untuk:
1. Menyusun konteks keselamatan dan memvalidasi ke pengaman.py
2. Mencatat siklus hidup perintah di tabel aksi_aktuator
3. Mempublikasikan payload perintah ke broker MQTT: jagatani/aktuator/pompa/<zona>
"""
import os
import json
import uuid
import datetime
from typing import Dict, Any, Optional
import paho.mqtt.client as mqtt

from app.aktuator.pengaman import boleh_siram
from app.aktuator.status import get_status_pompa, STATUS_POMPA_CACHE
from app.db.model_aktuator import (
    get_mode_zona,
    catat_aksi_diminta,
    update_status_aksi,
    get_siraman_terakhir_berhasil,
    cek_pompa_sedang_berjalan
)
from app.api.prediksi import get_latest_zone_sensors
from app.data.cuaca import fetch_forecast_24h

MQTT_BROKER = os.getenv("MQTT_BROKER", "broker.emqx.io")
MQTT_PORT = int(os.getenv("MQTT_PORT", "1883"))


def publish_mqtt_command(topic: str, payload: Dict[str, Any]) -> bool:
    """Mengirimkan payload JSON ke topik MQTT dengan graceful handling jika broker offline."""
    try:
        client = mqtt.Client()
        client.connect(MQTT_BROKER, MQTT_PORT, keepalive=10)
        client.publish(topic, json.dumps(payload), qos=1)
        client.disconnect()
        return True
    except Exception as e:
        print(f"[MQTT Publish Warning] Gagal kirim ke {topic} ({e}). Perintah tetap dicatat di backend.")
        return False


def evaluasi_dan_kirim_pompa(
    zona_id: str,
    durasi_menit: int = 15,
    sumber: str = "semi_otomatis",
    context_override: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """
    Mengevaluasi pengaman dan memicu pengaktifan pompa irigasi.
    Menyimpan status 'diminta', 'ditolak_pengaman', atau 'dikirim' di tabel aksi_aktuator.
    """
    # 1. Baca mode zona saat ini
    mode_info = get_mode_zona(zona_id)
    mode_zona = mode_info.get("mode", "semi_otomatis")

    # 2. Siapkan parameter konteks pengaman
    override = context_override or {}

    # Umur data sensor & nilai sensor terkini
    umur_data_menit = override.get("umur_data_menit")
    hujan_aktual = override.get("hujan_aktual", 0)
    current_soil = 45.0

    if umur_data_menit is None:
        df_hist = get_latest_zone_sensors(zona_id, limit_hours=1)
        if df_hist.empty:
            umur_data_menit = 999.0
        else:
            latest = df_hist.iloc[-1]
            current_soil = float(latest["kelembaban_tanah"])
            hujan_aktual = int(latest.get("hujan", 0))
            try:
                t_log = datetime.datetime.strptime(str(latest["timestamp"]), "%Y-%m-%d %H:%M:%S")
                umur_data_menit = max(0.0, (datetime.datetime.now() - t_log).total_seconds() / 60.0)
            except Exception:
                umur_data_menit = 5.0  # Fallback default untuk simulasi jika timestamp historis

    # Keputusan F-02
    keputusan_f02 = override.get("keputusan_f02")
    confidence_f02 = override.get("confidence_f02")
    alasan_f02 = override.get("alasan_f02", "Evaluasi otomatis F-02")

    if keputusan_f02 is None:
        # Default fallback logika jika tidak di-override
        if current_soil < 30.0:
            keputusan_f02 = "perlu"
            confidence_f02 = 0.95
            alasan_f02 = f"Kelembaban tanah rendah ({current_soil:.1f}%), perlu irigasi."
        else:
            keputusan_f02 = "tidak_perlu"
            confidence_f02 = 0.90
            alasan_f02 = f"Kelembaban tanah mencukupi ({current_soil:.1f}%)."

    # Prakiraan hujan 6 jam
    prakiraan_hujan_6jam = override.get("prakiraan_hujan_6jam")
    if prakiraan_hujan_6jam is None:
        try:
            weather = fetch_forecast_24h()
            prakiraan_hujan_6jam = float(weather.get("total_hujan_6jam", 0.0))
        except Exception:
            prakiraan_hujan_6jam = 0.0

    # Jeda sejak siraman terakhir yang berhasil
    jeda_jam = override.get("jeda_siraman_terakhir_jam")
    if jeda_jam is None:
        siraman_terakhir = get_siraman_terakhir_berhasil(zona_id)
        if siraman_terakhir:
            try:
                t_siram = datetime.datetime.strptime(siraman_terakhir["waktu"], "%Y-%m-%d %H:%M:%S")
                jeda_jam = max(0.0, (datetime.datetime.now() - t_siram).total_seconds() / 3600.0)
            except Exception:
                jeda_jam = 12.0
        else:
            jeda_jam = 24.0  # Belum pernah siram

    # Cek apakah pompa sedang aktif berjalan
    pompa_aktif = override.get("pompa_sedang_berjalan")
    if pompa_aktif is None:
        pompa_aktif = (
            cek_pompa_sedang_berjalan(zona_id) or
            get_status_pompa(zona_id).get("pompa") == "on"
        )

    # 3. Susun objek konteks murni untuk modul pengaman
    konteks = {
        "mode_zona": mode_zona,
        "sumber": sumber,
        "umur_data_menit": umur_data_menit,
        "keputusan_f02": keputusan_f02,
        "confidence_f02": confidence_f02,
        "hujan_aktual": hujan_aktual,
        "prakiraan_hujan_6jam": prakiraan_hujan_6jam,
        "jeda_siraman_terakhir_jam": jeda_jam,
        "durasi_diminta_menit": durasi_menit,
        "pompa_sedang_berjalan": pompa_aktif
    }

    # 4. Catat entri awal ke database dengan status 'diminta'
    id_aksi = catat_aksi_diminta(
        zona_id=zona_id,
        jenis="pompa_irigasi",
        sumber=sumber,
        alasan=alasan_f02,
        durasi_menit=durasi_menit,
        keputusan_f02=keputusan_f02,
        confidence_f02=confidence_f02
    )

    # 5. Uji seluruh syarat pengaman
    boleh, catatan_atau_alasan, durasi_efektif = boleh_siram(konteks)

    if not boleh:
        # Ditolak pengaman
        update_status_aksi(id_aksi, status="ditolak_pengaman", alasan_tolak=catatan_atau_alasan)
        return {
            "status": "ditolak_pengaman",
            "id_aksi": id_aksi,
            "zona_id": zona_id,
            "durasi_menit": durasi_efektif,
            "alasan_tolak": catatan_atau_alasan,
            "sumber": sumber,
            "mode_zona": mode_zona,
            "perintah_dikirim": False
        }

    # 6. Jika lolos pengaman -> kirim perintah ke ESP32 melalui MQTT
    topic = f"jagatani/aktuator/pompa/{zona_id}"
    payload_mqtt = {
        "aksi": "on",
        "durasi_detik": durasi_efektif * 60,
        "id_perintah": id_aksi
    }

    update_status_aksi(id_aksi, status="dikirim", alasan_tolak=None)
    mqtt_terkirim = publish_mqtt_command(topic, payload_mqtt)

    # Update cache status lokal sementara
    STATUS_POMPA_CACHE[zona_id] = {
        "pompa": "on",
        "sisa_detik": durasi_efektif * 60,
        "id_perintah": id_aksi,
        "updated_at": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }

    return {
        "status": "dikirim",
        "id_aksi": id_aksi,
        "zona_id": zona_id,
        "durasi_menit": durasi_efektif,
        "alasan": catatan_atau_alasan,
        "sumber": sumber,
        "mode_zona": mode_zona,
        "perintah_dikirim": True,
        "mqtt_published": mqtt_terkirim,
        "payload_mqtt": payload_mqtt
    }


def matikan_pompa_segera(zona_id: str, sumber: str = "manual") -> Dict[str, Any]:
    """
    Emergency Stop: Mematikan pompa irigasi segera.
    Menerbitkan payload {"aksi":"off","id_perintah":"<uuid>"} ke topik jagatani/aktuator/pompa/<zona>.
    """
    id_aksi = catat_aksi_diminta(
        zona_id=zona_id,
        jenis="pompa_irigasi",
        sumber=sumber,
        alasan="Perintah manual matikan pompa segera (Emergency Stop)",
        durasi_menit=0
    )

    topic = f"jagatani/aktuator/pompa/{zona_id}"
    payload_mqtt = {
        "aksi": "off",
        "id_perintah": id_aksi
    }

    mqtt_terkirim = publish_mqtt_command(topic, payload_mqtt)
    update_status_aksi(id_aksi, status="berhasil", alasan_tolak=None)

    # Update cache lokal
    STATUS_POMPA_CACHE[zona_id] = {
        "pompa": "off",
        "sisa_detik": 0,
        "id_perintah": id_aksi,
        "updated_at": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }

    return {
        "status": "berhasil",
        "id_aksi": id_aksi,
        "zona_id": zona_id,
        "pesan": "Pompa dihentikan segera.",
        "mqtt_published": mqtt_terkirim
    }
