import os
import json
import joblib
import sqlite3
import pandas as pd
import numpy as np
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List

from app.ml.fitur import build_realtime_feature_vector
from app.data.cuaca import fetch_forecast_24h
from app.api.prediksi import get_latest_zone_sensors

router = APIRouter()

BASE_DIR = os.path.dirname(os.path.dirname(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "ml", "model", "model_irigasi_f02.joblib")
METRICS_PATH = os.path.join(BASE_DIR, "ml", "model", "metrics_f02.json")

_model_f02 = None
_metrics_f02 = None


def get_model():
    global _model_f02, _metrics_f02
    if _model_f02 is None and os.path.exists(MODEL_PATH):
        _model_f02 = joblib.load(MODEL_PATH)
    if _metrics_f02 is None and os.path.exists(METRICS_PATH):
        with open(METRICS_PATH, "r") as f:
            _metrics_f02 = json.load(f)
    return _model_f02, _metrics_f02


class IrigasiRequest(BaseModel):
    zona_id: str = Field("zone_a", description="ID zona lahan pertanian")
    kelembaban_tanah: Optional[float] = Field(None, description="Nilai kelembaban tanah saat ini (%)")
    suhu_udara: Optional[float] = Field(None, description="Suhu udara saat ini (°C)")
    kelembaban_udara: Optional[float] = Field(None, description="Kelembaban udara saat ini (%)")
    hujan: Optional[int] = Field(None, description="1 jika sedang hujan, 0 jika tidak")
    prakiraan_hujan_6jam: Optional[float] = Field(None, description="Prakiraan curah hujan 6 jam ke depan (mm)")
    prakiraan_hujan_24jam: Optional[float] = Field(None, description="Prakiraan curah hujan 24 jam ke depan (mm)")
    riwayat_kelembaban: Optional[List[float]] = Field(None, description="Daftar kelembaban tanah 24 jam terakhir")


@router.post("/keputusan/irigasi")
def post_keputusan_irigasi(req: IrigasiRequest) -> Dict[str, Any]:
    """
    F-02: Klasifikasi keputusan irigasi (perlu / tidak perlu).
    Menghasilkan keputusan biner, skor confidence, serta alasan explainable berbasis kondisi tanah dan cuaca.
    """
    model, metrics = get_model()
    if model is None:
        raise HTTPException(status_code=500, detail="Model F-02 belum dilatih atau tidak ditemukan.")

    zona = req.zona_id
    df_hist = get_latest_zone_sensors(zona, limit_hours=24)
    
    if req.kelembaban_tanah is not None:
        soil_current = req.kelembaban_tanah
        temp_current = req.suhu_udara if req.suhu_udara is not None else 30.0
        hum_current = req.kelembaban_udara if req.kelembaban_udara is not None else 70.0
        is_rain = req.hujan if req.hujan is not None else 0
        history_soil = req.riwayat_kelembaban if req.riwayat_kelembaban else [soil_current] * 24
        last_dt = pd.Timestamp.now()
    else:
        if df_hist.empty or len(df_hist) < 3:
            return {
                "status": "data_belum_cukup",
                "zona_id": zona,
                "keputusan": "tidak_tersedia",
                "confidence": 0.0,
                "alasan": "Sensor belum mengirim cukup data historis untuk mengambil keputusan irigasi."
            }
        latest = df_hist.iloc[-1]
        soil_current = float(latest["kelembaban_tanah"])
        temp_current = float(latest["suhu_udara"])
        hum_current = float(latest["kelembaban_udara"])
        is_rain = int(latest["hujan"]) if "hujan" in latest else 0
        history_soil = df_hist["kelembaban_tanah"].tolist()
        while len(history_soil) < 24:
            history_soil.insert(0, history_soil[0])
        last_dt = pd.to_datetime(latest["timestamp"])

    weather = fetch_forecast_24h()
    forecast_rain_6h = req.prakiraan_hujan_6jam if req.prakiraan_hujan_6jam is not None else weather.get("total_hujan_6jam", 0.0)
    forecast_rain_24h = req.prakiraan_hujan_24jam if req.prakiraan_hujan_24jam is not None else weather.get("total_hujan_24jam", 0.0)

    feat_vec = build_realtime_feature_vector(
        history_24h_soil=history_soil,
        current_temp=temp_current,
        current_hum=hum_current,
        current_rain=float(is_rain),
        forecast_rain_6h=forecast_rain_6h,
        forecast_rain_24h=forecast_rain_24h,
        timestamp=last_dt
    )

    probs = model.predict_proba(feat_vec)[0]
    prob_tidak = float(probs[0])
    prob_perlu = float(probs[1]) if len(probs) > 1 else 0.0

    # Pengaman Agronomi Mutlak (Expert Rule Fallback):
    # Jika sensor mendeteksi kekeringan ekstrem (< 27%) dan tidak ada prakiraan hujan (< 1.0 mm),
    # irigasi mutlak dibutuhkan untuk mencegah plasmolisis/kematian tanaman.
    if soil_current < 27.0 and forecast_rain_6h < 1.0:
        prob_perlu = max(prob_perlu, 0.95)
        prob_tidak = 1.0 - prob_perlu

    raw_decision = "perlu" if prob_perlu >= 0.50 else "tidak_perlu"
    confidence = prob_perlu if raw_decision == "perlu" else prob_tidak
    confidence = round(confidence, 3)

    model_name = metrics.get("model_terpilih", "random_forest_classifier") if metrics else "random_forest_classifier"

    if confidence < 0.60:
        keputusan = "tidak_yakin"
        status_keyakinan = "rendah"
        alasan = (
            f"Tingkat keyakinan model berada di batas ambang ({int(confidence*100)}%). "
            f"Kelembaban tanah saat ini {soil_current}%. "
            "Disarankan periksa kondisi visual lahan atau sensor secara langsung sebelum menyalakan pompa."
        )
        rekomendasi_aksi = "Cek fisik lahan"
    elif raw_decision == "perlu":
        keputusan = "perlu"
        status_keyakinan = "tinggi"
        alasan = (
            f"Kelembaban tanah saat ini {soil_current}% (kritis di bawah ambang batas) "
            f"dan tidak ada prakiraan hujan signifikan ({forecast_rain_6h} mm dalam 6 jam). "
            "Irigasi diperlukan segera untuk mencegah stres kekeringan tanaman."
        )
        rekomendasi_aksi = "Aktifkan pompa irigasi 20–30 menit"
    else:
        keputusan = "tidak_perlu"
        status_keyakinan = "tinggi"
        if soil_current < 30.0 and forecast_rain_6h >= 1.0:
            alasan = (
                f"Meskipun kelembaban tanah saat ini rendah ({soil_current}%), "
                f"irigasi pompa tidak perlu dijalankan karena diprakirakan hujan {forecast_rain_6h} mm "
                "dalam 6 jam ke depan untuk mencegah pemborosan air dan energi."
            )
            rekomendasi_aksi = "Tunda irigasi, pantau perkembangan hujan"
        else:
            alasan = (
                f"Kelembaban tanah mencukupi ({soil_current}%). "
                f"Kondisi cadangan air tanah masih aman untuk aktivitas perakaran tanaman."
            )
            rekomendasi_aksi = "Pertahankan kondisi saat ini, pompa dimatikan"

    return {
        "status": "success",
        "fitur_id": "F-02",
        "zona_id": zona,
        "keputusan": keputusan,
        "confidence": confidence,
        "status_keyakinan": status_keyakinan,
        "alasan": alasan,
        "rekomendasi_aksi": rekomendasi_aksi,
        "probabilitas": {
            "perlu_irigasi": round(prob_perlu, 3),
            "tidak_perlu_irigasi": round(prob_tidak, 3)
        },
        "konteks_sensor": {
            "kelembaban_tanah": soil_current,
            "suhu_udara": temp_current,
            "prakiraan_hujan_6jam_mm": forecast_rain_6h
        },
        "model_info": {
            "nama": model_name,
            "fokus_optimasi": "Recall Tinggi (Deteksi Dini Kekeringan)"
        }
    }
