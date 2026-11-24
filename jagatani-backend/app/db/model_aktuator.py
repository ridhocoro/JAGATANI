import os
import sqlite3
import uuid
import datetime
from typing import Dict, Any, List, Optional

DB_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "jagatani.db")


def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_aktuator_db():
    """
    Inisialisasi tabel aksi_aktuator dan mode_zona di database SQLite.
    Default mode untuk zona baru adalah 'semi_otomatis'.
    """
    conn = get_db_connection()
    cursor = conn.cursor()

    # 1. Tabel aksi_aktuator
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS aksi_aktuator (
            id TEXT PRIMARY KEY,
            waktu TEXT NOT NULL,
            zona_id TEXT NOT NULL,
            jenis TEXT NOT NULL,
            sumber TEXT NOT NULL,
            keputusan_f02 TEXT,
            confidence_f02 REAL,
            alasan TEXT,
            durasi_menit INTEGER,
            jenis_pupuk TEXT,
            dosis TEXT,
            status TEXT NOT NULL,
            alasan_tolak TEXT
        )
    """)

    # 2. Tabel mode_zona
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS mode_zona (
            zona_id TEXT PRIMARY KEY,
            mode TEXT NOT NULL DEFAULT 'semi_otomatis',
            diubah_oleh TEXT,
            diubah_pada TEXT NOT NULL
        )
    """)

    # Pastikan index untuk query performa
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_aksi_zona_waktu ON aksi_aktuator (zona_id, waktu)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_aksi_status ON aksi_aktuator (status)")

    # Seed zona default (zone_a, zone_b, zone_c) jika belum ada
    now_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    for z in ["zone_a", "zone_b", "zone_c"]:
        cursor.execute("SELECT zona_id FROM mode_zona WHERE zona_id = ?", (z,))
        if not cursor.fetchone():
            cursor.execute("""
                INSERT INTO mode_zona (zona_id, mode, diubah_oleh, diubah_pada)
                VALUES (?, 'semi_otomatis', 'sistem_default', ?)
            """, (z, now_str))

    conn.commit()
    conn.close()


def get_mode_zona(zona_id: str) -> Dict[str, Any]:
    """Membaca mode zona (manual, semi_otomatis, otomatis). Default: semi_otomatis."""
    init_aktuator_db()
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT zona_id, mode, diubah_oleh, diubah_pada FROM mode_zona WHERE zona_id = ?", (zona_id,))
    row = cursor.fetchone()
    conn.close()

    if row:
        return dict(row)
    else:
        # Jika zona baru, buat otomatis semi_otomatis
        set_mode_zona(zona_id, "semi_otomatis", diubah_oleh="sistem_auto")
        return {
            "zona_id": zona_id,
            "mode": "semi_otomatis",
            "diubah_oleh": "sistem_auto",
            "diubah_pada": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }


def set_mode_zona(zona_id: str, mode: str, diubah_oleh: str = "petani") -> Dict[str, Any]:
    """Mengubah mode kontrol zona."""
    init_aktuator_db()
    mode_bersih = mode.lower()
    if mode_bersih not in ["manual", "semi_otomatis", "otomatis"]:
        raise ValueError("Mode harus salah satu dari: manual, semi_otomatis, otomatis")

    now_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO mode_zona (zona_id, mode, diubah_oleh, diubah_pada)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(zona_id) DO UPDATE SET
            mode = excluded.mode,
            diubah_oleh = excluded.diubah_oleh,
            diubah_pada = excluded.diubah_pada
    """, (zona_id, mode_bersih, diubah_oleh, now_str))
    conn.commit()
    conn.close()

    return {
        "zona_id": zona_id,
        "mode": mode_bersih,
        "diubah_oleh": diubah_oleh,
        "diubah_pada": now_str
    }


def catat_aksi_diminta(
    zona_id: str,
    jenis: str,
    sumber: str,
    alasan: str,
    durasi_menit: Optional[int] = None,
    jenis_pupuk: Optional[str] = None,
    dosis: Optional[str] = None,
    keputusan_f02: Optional[str] = None,
    confidence_f02: Optional[float] = None,
    custom_id: Optional[str] = None
) -> str:
    """
    Mencatat entri aksi_aktuator dengan status awal 'diminta'.
    Mengembalikan id aksi (UUID).
    """
    init_aktuator_db()
    aksi_id = custom_id or str(uuid.uuid4())
    now_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO aksi_aktuator (
            id, waktu, zona_id, jenis, sumber, keputusan_f02,
            confidence_f02, alasan, durasi_menit, jenis_pupuk, dosis,
            status, alasan_tolak
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'diminta', NULL)
    """, (
        aksi_id, now_str, zona_id, jenis, sumber, keputusan_f02,
        confidence_f02, alasan, durasi_menit, jenis_pupuk, dosis
    ))
    conn.commit()
    conn.close()
    return aksi_id


def update_status_aksi(id_aksi: str, status: str, alasan_tolak: Optional[str] = None):
    """Memperbarui status aksi (diminta, ditolak_pengaman, dikirim, berhasil, gagal)."""
    init_aktuator_db()
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE aksi_aktuator
        SET status = ?, alasan_tolak = ?
        WHERE id = ?
    """, (status, alasan_tolak, id_aksi))
    conn.commit()
    conn.close()


def get_siraman_terakhir_berhasil(zona_id: str) -> Optional[Dict[str, Any]]:
    """Mendapatkan data aksi penyiraman terakhir yang berstatus 'berhasil' atau 'dikirim'."""
    init_aktuator_db()
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT * FROM aksi_aktuator
        WHERE zona_id = ? AND jenis = 'pompa_irigasi' AND status IN ('berhasil', 'dikirim')
        ORDER BY waktu DESC LIMIT 1
    """, (zona_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None


def cek_pompa_sedang_berjalan(zona_id: str) -> bool:
    """Mengecek apakah ada perintah pompa di zona tersebut yang statusnya 'dikirim' dan belum selesai."""
    init_aktuator_db()
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT * FROM aksi_aktuator
        WHERE zona_id = ? AND jenis = 'pompa_irigasi' AND status = 'dikirim'
        ORDER BY waktu DESC LIMIT 1
    """, (zona_id,))
    row = cursor.fetchone()
    conn.close()
    if not row:
        return False

    # Cek apakah durasi waktu siram masih berlangsung
    try:
        waktu_str = row["waktu"]
        waktu_kirim = datetime.datetime.strptime(waktu_str, "%Y-%m-%d %H:%M:%S")
        durasi_menit = row["durasi_menit"] or 15
        waktu_selesai = waktu_kirim + datetime.timedelta(minutes=durasi_menit)
        if datetime.datetime.now() < waktu_selesai:
            return True
    except Exception:
        pass
    return False


def get_riwayat_aksi(zona_id: Optional[str] = None, limit: int = 50, offset: int = 0) -> List[Dict[str, Any]]:
    """Mengambil riwayat aksi aktuator terurut waktu terbaru."""
    init_aktuator_db()
    conn = get_db_connection()
    cursor = conn.cursor()
    if zona_id:
        cursor.execute("""
            SELECT * FROM aksi_aktuator
            WHERE zona_id = ?
            ORDER BY waktu DESC LIMIT ? OFFSET ?
        """, (zona_id, limit, offset))
    else:
        cursor.execute("""
            SELECT * FROM aksi_aktuator
            ORDER BY waktu DESC LIMIT ? OFFSET ?
        """, (limit, offset))
    rows = cursor.fetchall()
    conn.close()
    return [dict(r) for r in rows]
