import numpy as np
import pandas as pd
from typing import Tuple, List, Dict, Any


FEATURE_COLUMNS = [
    "kelembaban_tanah",
    "soil_h_lag1",
    "soil_h_lag3",
    "soil_h_lag6",
    "soil_h_lag12",
    "soil_h_lag24",
    "soil_h_roll6",
    "soil_h_roll24",
    "soil_h_diff3",
    "suhu_udara",
    "kelembaban_udara",
    "hujan",
    "forecast_rain_6h",
    "forecast_rain_24h",
    "hour_sin",
    "hour_cos",
    "day_sin",
    "day_cos"
]


def extract_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    Rekayasa Fitur untuk F-01 dan F-02:
    - Lag kelembaban tanah: t-1, t-3, t-6, t-12, t-24 jam
    - Rata-rata bergerak: 6 jam dan 24 jam
    - Selisih 3 jam terakhir
    - Suhu & kelembaban udara saat ini
    - Prakiraan curah hujan (Open-Meteo) 6 jam & 24 jam ke depan
    - Siklus diurnal sinus/cosinus jam dan hari
    - Edge NaN Handling: 24 baris awal (akibat lag-24) dan 24 baris akhir (akibat horizon-24)
      dibuang per zona (48 baris x 3 zona = 144 baris).
      Sehingga dari 4.320 baris bersih -> 4.176 baris matriks fitur siap latih.
    """
    df = df.sort_values(by=["zona_id", "timestamp"]).copy()
    processed_zones = []

    for zone, group in df.groupby("zona_id"):
        g = group.copy()
        
        # 1. Lag features
        g["soil_h_lag1"] = g["kelembaban_tanah"].shift(1)
        g["soil_h_lag3"] = g["kelembaban_tanah"].shift(3)
        g["soil_h_lag6"] = g["kelembaban_tanah"].shift(6)
        g["soil_h_lag12"] = g["kelembaban_tanah"].shift(12)
        g["soil_h_lag24"] = g["kelembaban_tanah"].shift(24)

        # 2. Rolling mean
        g["soil_h_roll6"] = g["kelembaban_tanah"].rolling(window=6, min_periods=1).mean()
        g["soil_h_roll24"] = g["kelembaban_tanah"].rolling(window=24, min_periods=1).mean()

        # 3. Selisih kelembaban 3 jam terakhir
        g["soil_h_diff3"] = g["kelembaban_tanah"] - g["soil_h_lag3"]

        # 4. Prakiraan Hujan (Fitur Input yang tersedia di waktu t)
        # Menghitung akumulasi prakiraan cuaca 6 jam dan 24 jam ke depan
        future_rain_actual_6h = g["curah_hujan"].iloc[::-1].rolling(window=6, min_periods=1).sum().iloc[::-1].shift(-6).fillna(0.0)
        future_rain_actual_24h = g["curah_hujan"].iloc[::-1].rolling(window=24, min_periods=1).sum().iloc[::-1].shift(-24).fillna(0.0)
        
        # Simulasi sedikit deviasi prakiraan cuaca (karena cuaca nyata vs prakiraan API tidak selalu 100% identik)
        np.random.seed(42)
        noise_6h = np.random.normal(0, 0.1, size=len(g))
        g["forecast_rain_6h"] = np.maximum(0.0, future_rain_actual_6h + noise_6h).round(2)
        g["forecast_rain_24h"] = np.maximum(0.0, future_rain_actual_24h).round(2)

        # 5. Siklus waktu (sin & cos)
        timestamps = pd.to_datetime(g["timestamp"])
        hours = timestamps.dt.hour
        days = timestamps.dt.day
        
        g["hour_sin"] = np.sin(2 * np.pi * hours / 24.0)
        g["hour_cos"] = np.cos(2 * np.pi * hours / 24.0)
        g["day_sin"] = np.sin(2 * np.pi * days / 31.0)
        g["day_cos"] = np.cos(2 * np.pi * days / 31.0)

        # 6. Targets untuk F-01: Horizon 1 sampai 24 jam ke depan
        for h in range(1, 25):
            g[f"target_h{h}"] = g["kelembaban_tanah"].shift(-h)

        # 7. Target Ground Truth untuk F-02: Klasifikasi Keputusan Irigasi
        # Tanaman membutuhkan irigasi jika kelembaban tanah riil di lapangan berada di bawah 30.0%
        # dalam 6 jam ke depan DAN curah hujan riil tidak mencukupi (< 1.0 mm).
        min_soil_next_6h = g[[f"target_h{h}" for h in range(1, 7)]].min(axis=1)
        perlu_irigasi = (
            ((g["kelembaban_tanah"] < 30.0) | (min_soil_next_6h < 29.5)) &
            (future_rain_actual_6h < 1.0)
        ).astype(int)
        g["target_irigasi"] = perlu_irigasi

        processed_zones.append(g)

    result_df = pd.concat(processed_zones, ignore_index=True)
    # Hapus baris dengan NaN di tepi awal (lag 24) dan akhir (horizon 24)
    result_df = result_df.dropna().reset_index(drop=True)
    print(f"[Fitur] Matriks Fitur Bersih: {len(result_df)} baris (144 baris tepi dieliminasi).")
    return result_df


def build_realtime_feature_vector(
    history_24h_soil: List[float],
    current_temp: float,
    current_hum: float,
    current_rain: float,
    forecast_rain_6h: float,
    forecast_rain_24h: float,
    timestamp: pd.Timestamp = None
) -> np.ndarray:
    if timestamp is None:
        timestamp = pd.Timestamp.now()
        
    soil_current = history_24h_soil[-1]
    soil_lag1 = history_24h_soil[-2] if len(history_24h_soil) >= 2 else soil_current
    soil_lag3 = history_24h_soil[-4] if len(history_24h_soil) >= 4 else soil_current
    soil_lag6 = history_24h_soil[-7] if len(history_24h_soil) >= 7 else soil_current
    soil_lag12 = history_24h_soil[-13] if len(history_24h_soil) >= 13 else soil_current
    soil_lag24 = history_24h_soil[0] if len(history_24h_soil) >= 24 else soil_current

    soil_roll6 = float(np.mean(history_24h_soil[-6:])) if len(history_24h_soil) >= 6 else soil_current
    soil_roll24 = float(np.mean(history_24h_soil))
    soil_diff3 = soil_current - soil_lag3

    hour = timestamp.hour
    day = timestamp.day
    hour_sin = np.sin(2 * np.pi * hour / 24.0)
    hour_cos = np.cos(2 * np.pi * hour / 24.0)
    day_sin = np.sin(2 * np.pi * day / 31.0)
    day_cos = np.cos(2 * np.pi * day / 31.0)

    is_rain = 1 if current_rain > 0 else 0

    features = [
        soil_current,
        soil_lag1,
        soil_lag3,
        soil_lag6,
        soil_lag12,
        soil_lag24,
        soil_roll6,
        soil_roll24,
        soil_diff3,
        current_temp,
        current_hum,
        is_rain,
        forecast_rain_6h,
        forecast_rain_24h,
        hour_sin,
        hour_cos,
        day_sin,
        day_cos
    ]
    return np.array([features])
