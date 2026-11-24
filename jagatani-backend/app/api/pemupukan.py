import os
import re
import json
import sqlite3
import pandas as pd
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Dict, Any, List, Optional, Tuple

from app.data.cuaca import fetch_forecast_24h
from app.api.prediksi import get_latest_zone_sensors
from app.db.model_aktuator import catat_aksi_diminta, update_status_aksi

router = APIRouter()

BASE_DIR = os.path.dirname(os.path.dirname(__file__))
ATURAN_PATH = os.path.join(BASE_DIR, "aturan", "pemupukan.json")


def validasi_catatan_pemupukan(jenis_pupuk: str, dosis: str) -> Tuple[bool, str]:
    """
    Validasi masukan catatan pemupukan dari petani.
    jenis_pupuk dan dosis wajib diisi, serta dosis harus memuat angka positif dengan satuan.
    """
    if not jenis_pupuk or not str(jenis_pupuk).strip():
        return False, "Jenis pupuk wajib diisi."
    if not dosis or not str(dosis).strip():
        return False, "Dosis pupuk wajib diisi (misal: 150 kg/ha)."

    match = re.search(r"[-+]?\d*\.?\d+", str(dosis))
    if not match:
        return False, "Dosis harus memuat angka yang valid dan satuan (misal: 150 kg/ha atau 2 ton/ha)."

    try:
        val = float(match.group())
        if val <= 0:
            return False, "Dosis pupuk harus berupa angka positif lebih dari nol."
    except ValueError:
        return False, "Format angka pada dosis tidak valid."

    return True, "Valid"


class CatatPemupukanRequest(BaseModel):
    zona_id: str = Field(..., description="ID zona pertanian (zone_a, zone_b, zone_c)")
    jenis_pupuk: str = Field(..., description="Nama/jenis pupuk, misal NPK 15-15-15")
    dosis: str = Field(..., description="Dosis pupuk beserta satuan, misal 150 kg/ha")
    id_rekomendasi_f03: Optional[str] = Field(None, description="ID aturan F-03 yang dikonfirmasi")
    petani_setuju: bool = Field(True, description="Konfirmasi persetujuan dari petani")


def load_aturan() -> Dict[str, Any]:
    if not os.path.exists(ATURAN_PATH):
        raise HTTPException(status_code=500, detail="File aturan pemupukan tidak ditemukan.")
    with open(ATURAN_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


@router.get("/rekomendasi/pemupukan")
def get_rekomendasi_pemupukan(
    zona: str = Query("zone_a", description="ID zona lahan pertanian (zone_a, zone_b, zone_c)"),
    ph_manual: Optional[float] = Query(None, description="Nilai pH tanah jika ingin simulasi manual"),
    kelembaban_manual: Optional[float] = Query(None, description="Nilai kelembaban tanah jika ingin simulasi manual"),
    hujan_24h_manual: Optional[float] = Query(None, description="Prakiraan curah hujan 24 jam jika ingin simulasi manual"),
    lat: float = Query(-6.5971, description="Latitude lokasi lahan"),
    lng: float = Query(106.8060, description="Longitude lokasi lahan")
) -> Dict[str, Any]:
    """
    F-03: Rekomendasi Pemupukan berbasis Sistem Pakar Agronomi (Rule-Based Expert System).
    Aturan terspesialisasi per komoditas: Zona A (Padi Sawah), Zona B (Jagung), Zona C (Cabai).
    """
    aturan_data = load_aturan()
    daftar_aturan = aturan_data.get("aturan", [])

    # 1. Ambil data kondisi sensor dan cuaca Open-Meteo
    if ph_manual is not None and kelembaban_manual is not None:
        ph_current = float(ph_manual)
        soil_humidity = float(kelembaban_manual)
        rain_24h = float(hujan_24h_manual) if hujan_24h_manual is not None else 0.0
        rain_6h = rain_24h * 0.3
    else:
        df_hist = get_latest_zone_sensors(zona, limit_hours=1)
        if df_hist.empty:
            return {
                "status": "data_belum_cukup",
                "zona_id": zona,
                "pesan": "Belum ada data sensor pH dan kelembaban untuk zona ini.",
                "rekomendasi": []
            }
        latest = df_hist.iloc[-1]
        ph_current = float(latest["ph_tanah"])
        soil_humidity = float(latest["kelembaban_tanah"])
        
        # Menggunakan sumber prakiraan cuaca yang sama persis dengan F-01
        weather = fetch_forecast_24h(lat=lat, lng=lng)
        rain_24h = weather.get("total_hujan_24jam", 0.0)
        rain_6h = weather.get("total_hujan_6jam", 0.0)

    # 2. Evaluasi Aturan Sistem Pakar Berdasarkan Prioritas
    rekomendasi_terpilih = []
    aturan_sorted = sorted(daftar_aturan, key=lambda x: x.get("prioritas", 99))

    for rule in aturan_sorted:
        kondisi = rule.get("kondisi", {})
        terpenuhi = True

        if "ph_max" in kondisi and ph_current > kondisi["ph_max"]:
            terpenuhi = False
        if "ph_min" in kondisi and ph_current < kondisi["ph_min"]:
            terpenuhi = False
        if "curah_hujan_24jam_min" in kondisi and rain_24h < kondisi["curah_hujan_24jam_min"]:
            terpenuhi = False
        if "curah_hujan_24jam_max" in kondisi and rain_24h > kondisi["curah_hujan_24jam_max"]:
            terpenuhi = False
        if "kelembaban_tanah_max" in kondisi and soil_humidity > kondisi["kelembaban_tanah_max"]:
            terpenuhi = False
        if "kelembaban_tanah_min" in kondisi and soil_humidity < kondisi["kelembaban_tanah_min"]:
            terpenuhi = False
        if "curah_hujan_6jam_max" in kondisi and rain_6h > kondisi["curah_hujan_6jam_max"]:
            terpenuhi = False

        if terpenuhi:
            # Periksa apakah ada rekomendasi spesifik komoditas (misal pada R-05)
            saran_tindakan = rule["tindakan"]
            sumber_aturan = rule["sumber"]
            
            if "dosis_per_komoditas" in rule and zona in rule["dosis_per_komoditas"]:
                komoditas_info = rule["dosis_per_komoditas"][zona]
                saran_tindakan = f"[{komoditas_info['komoditas']}] {komoditas_info['rekomendasi']}"
                sumber_aturan = komoditas_info["sumber"]

            rekomendasi_terpilih.append({
                "id_aturan": rule["id"],
                "nama_aturan": rule["nama"],
                "prioritas": rule["prioritas"],
                "status": rule["status"],
                "judul": rule["judul"],
                "penjelasan_kondisi": rule["deskripsi"],
                "saran_tindakan": saran_tindakan,
                "rekomendasi_pupuk_diizinkan": rule["rekomendasi_pupuk"],
                "sumber_aturan": sumber_aturan
            })

    boleh_memupuk = all(r["rekomendasi_pupuk_diizinkan"] for r in rekomendasi_terpilih) if rekomendasi_terpilih else False

    return {
        "status": "success",
        "fitur_id": "F-03",
        "zona_id": zona,
        "kondisi_aktual": {
            "ph_tanah": round(ph_current, 2),
            "kelembaban_tanah": round(soil_humidity, 2),
            "prakiraan_curah_hujan_24jam_mm": round(rain_24h, 2)
        },
        "kesimpulan_pemupukan": {
            "boleh_memupuk_sekarang": boleh_memupuk,
            "status_label": "DAPAT DILAKUKAN" if boleh_memupuk else "TUNDA / KOREKSI DAHULU",
            "perlu_konfirmasi_petani": True,
            "catatan": "Setiap rekomendasi bersifat saran agronomi dan wajib diverifikasi/dikonfirmasi petani sebelum eksekusi."
        },
        "daftar_rekomendasi": rekomendasi_terpilih
    }


@router.post("/pemupukan/catat")
def catat_pemupukan(req: CatatPemupukanRequest) -> Dict[str, Any]:
    """
    A-02: Mencatat pemupukan yang telah dikonfirmasi oleh petani.
    Di MVP, tidak ada pengiriman perintah dosing ke perangkat, murni pencatatan ke database aksi_aktuator.
    """
    # 1. Validasi konfirmasi petani
    if not req.petani_setuju:
        raise HTTPException(
            status_code=400,
            detail="Pencatatan pemupukan memerlukan konfirmasi persetujuan dari petani."
        )

    # 2. Validasi format jenis pupuk dan dosis
    is_valid, pesan_validasi = validasi_catatan_pemupukan(req.jenis_pupuk, req.dosis)
    if not is_valid:
        raise HTTPException(status_code=400, detail=pesan_validasi)

    # 3. Simpan entri awal ke aksi_aktuator dengan status 'diminta'
    alasan_catat = f"Pemupukan dikonfirmasi petani (Rekomendasi: {req.id_rekomendasi_f03 or 'Mandiri'})"
    id_aksi = catat_aksi_diminta(
        zona_id=req.zona_id,
        jenis="pupuk",
        sumber="manual",
        alasan=alasan_catat,
        jenis_pupuk=req.jenis_pupuk,
        dosis=req.dosis
    )

    # 4. Perbarui status menjadi 'berhasil'
    update_status_aksi(id_aksi, status="berhasil", alasan_tolak=None)

    return {
        "status": "success",
        "pesan": "Aktivitas pemupukan berhasil dicatat ke riwayat log.",
        "data": {
            "id_aksi": id_aksi,
            "zona_id": req.zona_id,
            "jenis": "pupuk",
            "jenis_pupuk": req.jenis_pupuk,
            "dosis": req.dosis,
            "status": "berhasil"
        }
    }

