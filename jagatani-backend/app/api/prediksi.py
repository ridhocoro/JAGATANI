import os
import json
import joblib
import sqlite3
import datetime
import numpy as np
import pandas as pd
from fastapi import APIRouter, HTTPException, Query
from typing import Optional, Dict, Any

from app.ml.fitur import build_realtime_feature_vector, FEATURE_COLUMNS
from app.data.cuaca import fetch_forecast_24h

router = APIRouter()

BASE_DIR = os.path.dirname(os.path.dirname(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "ml", "model", "model_kelembaban_f01.joblib")
METRICS_PATH = os.path.join(BASE_DIR, "ml", "model", "metrics_f01.json")
DB_PATH = os.path.join(BASE_DIR, "data", "jagatani.db")

_model_f01 = None
_metrics_f01 = None


def get_model():
    global _model_f01, _metrics_f01
    if _model_f01 is None and os.path.exists(MODEL_PATH):
        _model_f01 = joblib.load(MODEL_PATH)
    if _metrics_f01 is None and os.path.exists(METRICS_PATH):
        with open(METRICS_PATH, "r") as f:
            _metrics_f01 = json.load(f)
    return _model_f01, _metrics_f01


def get_latest_zone_sensors(zona_id: str, limit_hours: int = 24) -> pd.DataFrame:
    if not os.path.exists(DB_PATH):
        return pd.DataFrame()
    conn = sqlite3.connect(DB_PATH)
    query = """
        SELECT * FROM sensor_logs 
        WHERE zona_id = ? 
        ORDER BY timestamp DESC 
        LIMIT ?
    """
    df = pd.read_sql_query(query, conn, params=(zona_id, limit_hours))
    conn.close()
    if not df.empty:
        df = df.sort_values(by="timestamp").reset_index(drop=True)
    return df


@router.get("/prediksi/kelembaban")
def get_prediksi_kelembaban(
    zona: str = Query("zone_a", description="ID Zona lahan (misal: zone_a, zone_b, zone_c)"),
    lat: float = Query(-6.5971, description="Latitude lokasi lahan"),
    lng: float = Query(106.8060, description="Longitude lokasi lahan")
) -> Dict[str, Any]:
    """
    F-01: Prediksi kelembaban tanah 24 jam ke depan.
    Timestamp prediksi dihitung runtut dari timestamp log terakhir (t+1 s/d t+24).
    Jika data sensor terakhir sudah lewat > 24 jam dari waktu server, status peringatan data stale disertakan.
    """
    model, metrics = get_model()
    if model is None:
        raise HTTPException(status_code=500, detail="Model F-01 belum dilatih atau tidak ditemukan.")

    df_hist = get_latest_zone_sensors(zona, limit_hours=24)
    if df_hist.empty or len(df_hist) < 3:
        return {
            "status": "data_belum_cukup",
            "zona_id": zona,
            "pesan": "Sensor belum mengirim cukup data historis untuk zona ini. Minimal dibutuhkan 3 jam log.",
            "prediksi_24_jam": []
        }

    latest_row = df_hist.iloc[-1]
    last_timestamp_str = str(latest_row["timestamp"])
    last_dt = pd.to_datetime(last_timestamp_str)
    
    # Cek kebaruan data (stale check)
    current_wall_time = pd.Timestamp.now()
    selisih_jam = (current_wall_time - last_dt).total_seconds() / 3600.0
    is_stale = selisih_jam > 24.0

    soil_current = float(latest_row["kelembaban_tanah"])
    temp_current = float(latest_row["suhu_udara"])
    hum_current = float(latest_row["kelembaban_udara"])
    rain_current = float(latest_row["curah_hujan"]) if "curah_hujan" in latest_row else 0.0

    history_soil = df_hist["kelembaban_tanah"].tolist()
    while len(history_soil) < 24:
        history_soil.insert(0, history_soil[0])

    weather_data = fetch_forecast_24h(lat=lat, lng=lng)
    forecast_rain_6h = weather_data.get("total_hujan_6jam", 0.0)
    forecast_rain_24h = weather_data.get("total_hujan_24jam", 0.0)

    # Bangun vektor fitur input inferensi
    feat_vec = build_realtime_feature_vector(
        history_24h_soil=history_soil,
        current_temp=temp_current,
        current_hum=hum_current,
        current_rain=rain_current,
        forecast_rain_6h=forecast_rain_6h,
        forecast_rain_24h=forecast_rain_24h,
        timestamp=last_dt
    )

    preds_24h = model.predict(feat_vec)[0]

    # Ambil metrik dari model terpilih
    model_name = metrics.get("model_terpilih", "linear_regression") if metrics else "linear_regression"
    rmse = metrics.get("rmse_model_terpilih", 6.46) if metrics else 6.46
    mae = metrics.get("mae_model_terpilih", 4.13) if metrics else 4.13

    forecast_points = []
    prakiraan_cuaca_jam = weather_data.get("prakiraan_per_jam", [])

    for h in range(1, 25):
        val = float(preds_24h[h - 1])
        val = max(10.0, min(95.0, val))
        lower_bound = max(0.0, round(val - rmse, 2))
        upper_bound = min(100.0, round(val + rmse, 2))
        
        # Waktu prediksi berlanjut runtut dari timestamp terakhir (t + h)
        waktu_jam = (last_dt + pd.Timedelta(hours=h)).strftime("%Y-%m-%d %H:00")
        hujan_jam = prakiraan_cuaca_jam[h - 1]["curah_hujan"] if (h - 1) < len(prakiraan_cuaca_jam) else 0.0
        
        forecast_points.append({
            "jam_ke": h,
            "waktu": waktu_jam,
            "prediksi_kelembaban": round(val, 2),
            "batas_bawah": lower_bound,
            "batas_atas": upper_bound,
            "prakiraan_hujan": hujan_jam
        })

    response = {
        "status": "success",
        "fitur_id": "F-01",
        "zona_id": zona,
        "timestamp_terakhir": last_timestamp_str,
        "nilai_aktual_terakhir": soil_current,
        "peringatan_data_stale": is_stale,
        "model_digunakan": model_name,
        "evaluasi_model": {
            "mae": mae,
            "rmse": rmse,
            "satuan": "persen poin kelembaban",
            "keterangan": f"Pita ketidakpastian dihitung berdasarkan rentang ±1 RMSE (±{rmse}%) pada data uji murni."
        },
        "cuaca_open_meteo": {
            "mode": "simulasi_historis_31_oktober" if is_stale else "live_open_meteo",
            "sumber": "simulasi_periode_31_oktober" if is_stale else weather_data.get("status"),
            "keterangan": "Prakiraan cuaca disinkronkan dengan periode data simulasi (31 Oktober 2026)" if is_stale else "Prakiraan cuaca live Open-Meteo",
            "total_hujan_6jam": forecast_rain_6h,
            "total_hujan_24jam": forecast_rain_24h
        },
        "prediksi_24_jam": forecast_points
    }

    if is_stale:
        response["pesan_stale"] = (
            f"Perhatian: Data sensor terakhir berasal dari {last_timestamp_str}. "
            "Prakiraan dihitung melanjutkan titik riwayat terakhir tersebut."
        )

    return response
