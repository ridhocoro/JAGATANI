"""
Modul Pemantau Status Aktuator ESP32
Menerima payload status dari ESP32 melalui MQTT dan memperbarui database serta cache status.
Topik: jagatani/aktuator/status/<zona>
Payload: {"pompa": "on"|"off", "id_perintah": "<uuid>", "sisa_detik": 0}
"""
import datetime
import json
from typing import Dict, Any, Optional

from app.db.model_aktuator import update_status_aksi

# In-memory status pompa per zona
STATUS_POMPA_CACHE: Dict[str, Dict[str, Any]] = {
    "zone_a": {"pompa": "off", "sisa_detik": 0, "id_perintah": None, "updated_at": None},
    "zone_b": {"pompa": "off", "sisa_detik": 0, "id_perintah": None, "updated_at": None},
    "zone_c": {"pompa": "off", "sisa_detik": 0, "id_perintah": None, "updated_at": None},
}


def get_status_pompa(zona_id: str) -> Dict[str, Any]:
    """Membaca status real-time pompa untuk zona tertentu."""
    now_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    if zona_id not in STATUS_POMPA_CACHE:
        STATUS_POMPA_CACHE[zona_id] = {
            "pompa": "off",
            "sisa_detik": 0,
            "id_perintah": None,
            "updated_at": now_str
        }
    return STATUS_POMPA_CACHE[zona_id]


def update_status_dari_esp32(zona_id: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    """
    Memproses status yang dikirimkan oleh firmware ESP32.
    Format payload: {"pompa": "on"|"off", "id_perintah": "...", "sisa_detik": 0}
    """
    now_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    status_pompa = str(payload.get("pompa", "off")).lower()
    sisa_detik = int(payload.get("sisa_detik", 0))
    id_perintah = payload.get("id_perintah")

    # Update cache lokal
    STATUS_POMPA_CACHE[zona_id] = {
        "pompa": status_pompa,
        "sisa_detik": sisa_detik,
        "id_perintah": id_perintah,
        "updated_at": now_str
    }

    # Jika pompa telah selesai (mati dan sisa_detik == 0), perbarui status aksi di DB
    if status_pompa == "off" and sisa_detik == 0 and id_perintah:
        try:
            update_status_aksi(id_perintah, status="berhasil", alasan_tolak=None)
        except Exception:
            pass

    return STATUS_POMPA_CACHE[zona_id]


def on_mqtt_status_message(client, userdata, msg):
    """Callback pemroses pesan MQTT masuk pada topik status."""
    try:
        topic_parts = msg.topic.split("/")
        # jagatani/aktuator/status/<zona>
        if len(topic_parts) >= 4 and topic_parts[2] == "status":
            zona_id = topic_parts[3]
            payload = json.loads(msg.payload.decode("utf-8"))
            update_status_dari_esp32(zona_id, payload)
    except Exception as e:
        print(f"[MQTT Status Error] Gagal memproses payload status: {e}")
