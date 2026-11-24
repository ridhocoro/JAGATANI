"""
Router API Aktuator & Mode Kontrol Lahan
Endpoint:
- GET  /zona/{zona_id}/mode
- PUT  /zona/{zona_id}/mode
- POST /aktuator/pompa
- POST /aktuator/pompa/matikan
- GET  /aktuator/status/{zona_id}
- GET  /aktuator/riwayat
"""
from fastapi import APIRouter, HTTPException, Query, Body
from pydantic import BaseModel, Field
from typing import Dict, Any, List, Optional

from app.db.model_aktuator import (
    get_mode_zona,
    set_mode_zona,
    get_riwayat_aksi
)
from app.aktuator.perintah import evaluasi_dan_kirim_pompa, matikan_pompa_segera
from app.aktuator.status import get_status_pompa

router = APIRouter()


class UpdateModeRequest(BaseModel):
    mode: str = Field(..., description="Pilihan mode: manual, semi_otomatis, otomatis")
    diubah_oleh: str = Field("petani", description="Identitas pengguna pengubah mode")


class PompaRequest(BaseModel):
    zona_id: str = Field(..., description="ID Zona lahan: zone_a, zone_b, zone_c")
    durasi_menit: int = Field(15, description="Durasi siram dalam menit (akan diklem 1-15)")
    sumber: str = Field("manual", description="Sumber perintah: manual, semi_otomatis, otomatis")


class MatikanPompaRequest(BaseModel):
    zona_id: str = Field(..., description="ID Zona lahan: zone_a, zone_b, zone_c")
    sumber: str = Field("manual", description="Sumber pemadaman: manual, sistem")


@router.get("/zona/{zona_id}/mode")
def baca_mode_zona(zona_id: str) -> Dict[str, Any]:
    """Membaca mode kontrol saat ini untuk suatu zona (manual, semi_otomatis, otomatis)."""
    return get_mode_zona(zona_id)


@router.put("/zona/{zona_id}/mode")
def ubah_mode_zona(zona_id: str, req: UpdateModeRequest) -> Dict[str, Any]:
    """Mengubah mode kontrol zona. Opsi: manual, semi_otomatis, otomatis."""
    try:
        hasil = set_mode_zona(zona_id, req.mode, req.diubah_oleh)
        return {
            "status": "success",
            "pesan": f"Mode zona {zona_id} berhasil diubah ke '{req.mode}'",
            "data": hasil
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/aktuator/pompa")
def trigger_pompa(req: PompaRequest) -> Dict[str, Any]:
    """
    Meminta eksekusi pompa irigasi.
    Permintaan akan melewati seluruh syarat pengaman (pengaman.py) sebelum dikirim ke ESP32.
    """
    hasil = evaluasi_dan_kirim_pompa(
        zona_id=req.zona_id,
        durasi_menit=req.durasi_menit,
        sumber=req.sumber
    )
    return hasil


@router.post("/aktuator/pompa/matikan")
def hentikan_pompa(req: MatikanPompaRequest) -> Dict[str, Any]:
    """Menghentikan pompa irigasi seketika (Emergency Stop)."""
    hasil = matikan_pompa_segera(zona_id=req.zona_id, sumber=req.sumber)
    return hasil


@router.get("/aktuator/status/{zona_id}")
def baca_status_pompa(zona_id: str) -> Dict[str, Any]:
    """Membaca status real-time pompa dari ESP32 (on/off, sisa detik, id perintah)."""
    return {
        "status": "success",
        "zona_id": zona_id,
        "data": get_status_pompa(zona_id)
    }


@router.get("/aktuator/riwayat")
def baca_riwayat_aktuator(
    zona: Optional[str] = Query(None, description="Filter zona tertentu (opsional)"),
    limit: int = Query(20, ge=1, le=100, description="Jumlah data per halaman"),
    offset: int = Query(0, ge=0, description="Offset data")
) -> Dict[str, Any]:
    """Membaca riwayat aksi aktuator (pompa irigasi dan pemupukan) dari tabel aksi_aktuator."""
    riwayat = get_riwayat_aksi(zona_id=zona, limit=limit, offset=offset)
    return {
        "status": "success",
        "zona_filter": zona,
        "total_data": len(riwayat),
        "data": riwayat
    }
