import os
import json
import sqlite3
import datetime
from typing import Dict, Any

DB_PATH = os.path.join(os.path.dirname(__file__), "jagatani.db")


def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS sensor_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            zona_id TEXT NOT NULL,
            kelembaban_tanah REAL NOT NULL,
            ph_tanah REAL NOT NULL,
            suhu_udara REAL NOT NULL,
            kelembaban_udara REAL NOT NULL,
            suhu_tanah REAL,
            intensitas_cahaya REAL,
            curah_hujan REAL,
            hujan INTEGER,
            status_pompa INTEGER
        )
    """)
    conn.commit()
    conn.close()


def save_sensor_reading(data: Dict[str, Any]) -> int:
    """
    Menyimpan satu paket data telemetri sensor dari MQTT ke SQLite.
    Format payload:
    {
        "timestamp": "2026-11-23 16:30:00",
        "zona_id": "zone_a",
        "kelembaban_tanah": 45.2,
        "ph_tanah": 6.3,
        "suhu_udara": 31.2,
        "kelembaban_udara": 72.0,
        "suhu_tanah": 28.5,
        "intensitas_cahaya": 42000.0,
        "curah_hujan": 0.0,
        "hujan": 0,
        "status_pompa": 0
    }
    """
    init_db()
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    ts = data.get("timestamp", datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    zona = data.get("zona_id", "zone_a")
    soil_h = float(data.get("kelembaban_tanah", 50.0))
    ph = float(data.get("ph_tanah", 6.5))
    temp = float(data.get("suhu_udara", 30.0))
    hum = float(data.get("kelembaban_udara", 70.0))
    soil_t = float(data.get("suhu_tanah", temp - 2.0))
    light = float(data.get("intensitas_cahaya", 0.0))
    rain = float(data.get("curah_hujan", 0.0))
    is_rain = int(data.get("hujan", 1 if rain > 0 else 0))
    pump = int(data.get("status_pompa", 0))

    cursor.execute("""
        INSERT INTO sensor_logs 
        (timestamp, zona_id, kelembaban_tanah, ph_tanah, suhu_udara, kelembaban_udara, suhu_tanah, intensitas_cahaya, curah_hujan, hujan, status_pompa)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (ts, zona, soil_h, ph, temp, hum, soil_t, light, rain, is_rain, pump))

    conn.commit()
    inserted_id = cursor.lastrowid
    conn.close()
    return inserted_id


def start_mqtt_listener(broker_host="localhost", broker_port=1883, topic="jagatani/sensor/#"):
    """
    Menghubungkan ke broker MQTT dan mendengarkan data sensor.
    (Hanya dijalankan jika broker aktif).
    """
    try:
        import paho.mqtt.client as mqtt

        def on_connect(client, userdata, flags, rc):
            print(f"[MQTT] Terhubung ke broker dengan return code {rc}")
            client.subscribe(topic)

        def on_message(client, userdata, msg):
            try:
                payload_str = msg.payload.decode("utf-8")
                payload = json.loads(payload_str)
                row_id = save_sensor_reading(payload)
                print(f"[MQTT] Data tersimpan id={row_id} topik={msg.topic}")
            except Exception as e:
                print(f"[MQTT Error] Gagal parsing pesan: {e}")

        client = mqtt.Client()
        client.on_connect = on_connect
        client.on_message = on_message
        client.connect(broker_host, broker_port, 60)
        client.loop_forever()
    except Exception as e:
        print(f"[MQTT] Tidak dapat terhubung ke broker ({e}). Berjalan dalam mode database lokal.")
