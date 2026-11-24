import datetime
import math
import random
import sqlite3
import os
import pandas as pd
from typing import List, Dict, Any

DB_PATH = os.path.join(os.path.dirname(__file__), "jagatani.db")
CSV_PATH = os.path.join(os.path.dirname(__file__), "sensor_raw.csv")


def generate_synthetic_farm_data(days: int = 60, seed: int = 42) -> pd.DataFrame:
    """
    Menghasilkan data deret waktu sensor pertanian simulasi realistis untuk iklim tropis Indonesia.
    Total data dasar: 60 hari x 24 jam x 3 zona = 4.320 titik jam.
    Ditambah 5 baris duplikasi acak untuk simulasi noise jaringan MQTT (Total = 4.325 baris mentah).
    """
    random.seed(seed)
    
    start_time = datetime.datetime(2026, 9, 1, 0, 0, 0)
    total_hours = days * 24
    zones = ["zone_a", "zone_b", "zone_c"]
    
    all_records = []
    
    for zone in zones:
        if zone == "zone_a": # Sawah Padi
            base_soil_h = 56.0
            base_ph = 6.3
            crop_factor = 1.0
        elif zone == "zone_b": # Jagung
            base_soil_h = 50.0
            base_ph = 6.5
            crop_factor = 0.85
        else: # Cabai
            base_soil_h = 52.0
            base_ph = 6.2
            crop_factor = 0.95

        current_soil_h = base_soil_h
        current_ph = base_ph
        pump_active = False
        pump_remaining_hours = 0
        
        for h in range(total_hours):
            current_time = start_time + datetime.timedelta(hours=h)
            hour = current_time.hour
            
            # 1. Siklus Suhu & Kelembaban Udara Diurnal Tropis
            diurnal_temp_factor = math.sin((hour - 8) / 24 * 2 * math.pi)
            air_temp = 27.0 + 4.5 * diurnal_temp_factor + random.gauss(0, 0.5)
            air_temp = max(22.0, min(36.0, air_temp))
            
            air_hum = 75.0 - 15.0 * diurnal_temp_factor + random.gauss(0, 2.0)
            air_hum = max(50.0, min(95.0, air_hum))
            
            soil_temp = 25.5 + 2.5 * math.sin((hour - 10) / 24 * 2 * math.pi) + random.gauss(0, 0.3)
            
            # Intensitas cahaya (Lux)
            if 6 <= hour <= 18:
                sun_factor = math.sin((hour - 6) / 12 * math.pi)
                light = max(0.0, 50000 * sun_factor + random.gauss(0, 2500))
            else:
                light = 0.0
                
            # 2. Episode Hujan Stokastik
            rain_chance = 0.08 if 14 <= hour <= 18 else 0.03
            is_rain = random.random() < rain_chance
            rain_amount = 0.0
            if is_rain:
                rain_amount = round(-6.0 * math.log(random.random() + 1e-6), 1)
                rain_amount = max(0.5, min(65.0, rain_amount))
                air_hum = min(98.0, air_hum + 15.0)
                air_temp = max(23.0, air_temp - 2.5)

            # 3. Dinamika Kelembaban Tanah & Respon Irigasi
            vpd = (100 - air_hum) / 100.0
            evapotranspiration = (0.2 + 0.6 * vpd * (air_temp / 30.0)) * crop_factor
            
            if rain_amount > 0:
                moisture_increase = min(35.0, rain_amount * 1.5)
                current_soil_h = min(85.0, current_soil_h + moisture_increase)
                pump_active = False
                pump_remaining_hours = 0
            elif pump_active:
                current_soil_h = min(80.0, current_soil_h + 8.5)
                pump_remaining_hours -= 1
                if pump_remaining_hours <= 0:
                    pump_active = False
            else:
                current_soil_h = max(18.0, current_soil_h - evapotranspiration)
                
                # Simulasi tindakan penyiraman oleh petani jika tanah < 28%
                if current_soil_h < 28.0 and random.random() < 0.65:
                    pump_active = True
                    pump_remaining_hours = 2

            # 4. Dinamika pH Tanah
            current_ph += random.gauss(0, 0.015)
            current_ph = max(5.4, min(7.2, current_ph))
            
            record = {
                "timestamp": current_time.strftime("%Y-%m-%d %H:%M:%S"),
                "zona_id": zone,
                "kelembaban_tanah": round(current_soil_h, 2),
                "ph_tanah": round(current_ph, 2),
                "suhu_udara": round(air_temp, 2),
                "kelembaban_udara": round(air_hum, 2),
                "suhu_tanah": round(soil_temp, 2),
                "intensitas_cahaya": round(light, 1),
                "curah_hujan": round(rain_amount, 1),
                "hujan": 1 if rain_amount > 0 else 0,
                "status_pompa": 1 if pump_active else 0
            }
            all_records.append(record)

    df = pd.DataFrame(all_records)
    
    # 5 Duplikat acak (simulasi redundansi MQTT retransmit)
    duplicates = df.sample(n=5, random_state=123)
    
    # 3 Nilai anomali sensor (spike listrik / glitch ADC)
    outliers_idx = df.sample(n=3, random_state=456).index
    df.loc[outliers_idx[0], "kelembaban_tanah"] = 145.0
    df.loc[outliers_idx[1], "ph_tanah"] = 12.8
    df.loc[outliers_idx[2], "suhu_udara"] = 85.0
    
    df = pd.concat([df, duplicates], ignore_index=True)
    df = df.sort_values(by=["zona_id", "timestamp"]).reset_index(drop=True)
    
    return df


def save_to_db_and_csv(df: pd.DataFrame):
    df.to_csv(CSV_PATH, index=False)
    
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
    
    cursor.execute("DELETE FROM sensor_logs")
    df.to_sql("sensor_logs", conn, if_exists="append", index=False)
    conn.commit()
    conn.close()
    print(f"[Generator] Berhasil membuat {len(df)} baris data simulasi di {CSV_PATH} dan {DB_PATH}")


if __name__ == "__main__":
    df = generate_synthetic_farm_data(days=60)
    save_to_db_and_csv(df)
