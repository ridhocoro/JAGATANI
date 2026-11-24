import os
import json
import sqlite3
import pandas as pd
import numpy as np
from typing import Tuple, Dict, Any

DATA_DIR = os.path.dirname(__file__)
RAW_CSV = os.path.join(DATA_DIR, "sensor_raw.csv")
CLEAN_CSV = os.path.join(DATA_DIR, "sensor_clean.csv")
STATS_JSON = os.path.join(DATA_DIR, "data_cleaning_stats.json")
DB_PATH = os.path.join(DATA_DIR, "jagatani.db")


def clean_sensor_data(df_raw: pd.DataFrame = None) -> Tuple[pd.DataFrame, Dict[str, Any]]:
    """
    Pembersihan Data Telemetri Simulasi Sensor:
    1. Total mentah: 4.325 baris (4.320 baris asli deret waktu + 5 duplikat).
    2. Hapus 5 duplikat timestamp & zona -> tersisa 4.320 baris.
    3. Deteksi 3 nilai outlier ekstrem di luar batas fisik:
       - Nilai kelembaban tanah > 100% atau < 0%
       - Nilai pH tanah di luar [3.0, 10.0]
       - Suhu udara di luar [10.0, 50.0]
       Nilai anomali diubah menjadi NaN dan diimputasi melalui interpolasi linier waktu (t-1 dan t+1).
    4. Total akhir data bersih deret waktu kontinu tetap 4.320 baris.
    """
    if df_raw is None:
        if os.path.exists(RAW_CSV):
            df_raw = pd.read_csv(RAW_CSV)
        else:
            conn = sqlite3.connect(DB_PATH)
            df_raw = pd.read_sql_query("SELECT * FROM sensor_logs", conn)
            conn.close()

    total_awal = len(df_raw)

    # 1. Hapus Duplikat
    df = df_raw.drop_duplicates(subset=["timestamp", "zona_id"]).copy()
    duplikat_dibuang = total_awal - len(df)

    df["timestamp"] = pd.to_datetime(df["timestamp"])
    df = df.sort_values(by=["zona_id", "timestamp"]).reset_index(drop=True)

    # 2. Deteksi & Perbaiki Outlier Sensor melalui Interpolasi Waktu
    mask_outlier_soil = (df["kelembaban_tanah"] < 0.0) | (df["kelembaban_tanah"] > 100.0)
    mask_outlier_ph = (df["ph_tanah"] < 3.0) | (df["ph_tanah"] > 10.0)
    mask_outlier_temp = (df["suhu_udara"] < 10.0) | (df["suhu_udara"] > 50.0)
    
    total_outliers = int((mask_outlier_soil | mask_outlier_ph | mask_outlier_temp).sum())

    df.loc[mask_outlier_soil, "kelembaban_tanah"] = np.nan
    df.loc[mask_outlier_ph, "ph_tanah"] = np.nan
    df.loc[mask_outlier_temp, "suhu_udara"] = np.nan

    # Interpolasi per zona
    cleaned_zones = []
    for zone, group in df.groupby("zona_id"):
        g = group.sort_values(by="timestamp").copy()
        g["kelembaban_tanah"] = g["kelembaban_tanah"].interpolate(method="linear")
        g["ph_tanah"] = g["ph_tanah"].interpolate(method="linear")
        g["suhu_udara"] = g["suhu_udara"].interpolate(method="linear")
        cleaned_zones.append(g)

    df_cleaned = pd.concat(cleaned_zones, ignore_index=True)
    df_cleaned = df_cleaned.sort_values(by=["zona_id", "timestamp"]).reset_index(drop=True)

    total_akhir = len(df_cleaned)

    stats = {
        "total_baris_mentah": int(total_awal),
        "duplikat_dihapus": int(duplikat_dibuang),
        "outlier_sensor_diperbaiki_interpolasi": int(total_outliers),
        "total_baris_bersih": int(total_akhir),
        "rentang_waktu_mulai": str(df_cleaned["timestamp"].min()),
        "rentang_waktu_akhir": str(df_cleaned["timestamp"].max()),
        "zona_terdata": list(df_cleaned["zona_id"].unique())
    }

    df_cleaned.to_csv(CLEAN_CSV, index=False)
    with open(STATS_JSON, "w") as f:
        json.dump(stats, f, indent=2)

    print(f"[Preprocess] Pembersihan selesai. Awal: {total_awal} -> Bersih: {total_akhir} baris.")
    print(f"[Preprocess] Duplikat: {duplikat_dibuang}, Outlier diperbaiki: {total_outliers}")

    return df_cleaned, stats


def split_data_time_based(df: pd.DataFrame, train_ratio=0.70, val_ratio=0.15) -> Tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """
    Pemisahan data berdasarkan urutan kronologis waktu (time-based):
    - Dari total matriks fitur siap latih (setelah membuang NaN edge akibat lag 24 jam & target horizon 24 jam):
      4.176 baris -> 70% Train (2.923), 15% Val (626), 15% Test (627).
    """
    df = df.sort_values(by="timestamp").reset_index(drop=True)
    n = len(df)
    train_end = int(n * train_ratio)
    val_end = int(n * (train_ratio + val_ratio))

    train_df = df.iloc[:train_end].copy()
    val_df = df.iloc[train_end:val_end].copy()
    test_df = df.iloc[val_end:].copy()

    print(f"[Split] Total Fitur Siap Latih: {n} | Train: {len(train_df)} | Val: {len(val_df)} | Test: {len(test_df)}")
    return train_df, val_df, test_df


if __name__ == "__main__":
    df, stats = clean_sensor_data()
    print("Statistik Pembersihan:", stats)
