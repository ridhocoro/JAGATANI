import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict, Any

from app.api.prediksi import router as prediksi_router
from app.api.irigasi import router as irigasi_router
from app.api.pemupukan import router as pemupukan_router
from app.api.aktuator import router as aktuator_router
from app.db.model_aktuator import init_aktuator_db

app = FastAPI(
    title="JagaTani AI & Decision Backend",
    description="Backend Machine Learning & Expert System untuk Smart Agriculture JagaTani (F-01, F-02, F-03)",
    version="1.0.0"
)

# Aktifkan CORS untuk Flutter App
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Hubungkan modul endpoint
app.include_router(prediksi_router, tags=["F-01: Prediksi Kelembaban 24 Jam"])
app.include_router(irigasi_router, tags=["F-02: Klasifikasi Keputusan Irigasi"])
app.include_router(pemupukan_router, tags=["F-03: Rekomendasi Pemupukan & A-02 Catatan"])
app.include_router(aktuator_router, tags=["A-01: Pengairan & Aktuator"])


@app.on_event("startup")
def on_startup():
    # Inisialisasi tabel database SQLite
    init_aktuator_db()


@app.get("/")
def get_root() -> Dict[str, Any]:
    return {
        "aplikasi": "JagaTani AI & Decision Backend",
        "versi": "1.0.0",
        "status": "online",
        "fitur_terpasang": {
            "F-01": "Prediksi kelembaban tanah 24 jam ke depan (ML Regresi)",
            "F-02": "Klasifikasi keputusan irigasi (ML Klasifikasi Biner)",
            "F-03": "Rekomendasi pemupukan (Sistem Pakar Berbasis Aturan)"
        },
        "endpoints": {
            "prediksi_kelembaban": "GET /prediksi/kelembaban?zona={zona_id}",
            "keputusan_irigasi": "POST /keputusan/irigasi",
            "rekomendasi_pemupukan": "GET /rekomendasi/pemupukan?zona={zona_id}",
            "dokumentasi_api": "/docs"
        }
    }


@app.get("/health")
def get_health() -> Dict[str, str]:
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
