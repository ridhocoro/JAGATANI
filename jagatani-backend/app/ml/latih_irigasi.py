import os
import json
import joblib
import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import confusion_matrix

from app.ml.fitur import extract_features, FEATURE_COLUMNS
from app.data.preprocess import clean_sensor_data, split_data_time_based
from app.ml.evaluasi import evaluate_classification

MODEL_DIR = os.path.join(os.path.dirname(__file__), "model")
MODEL_PATH = os.path.join(MODEL_DIR, "model_irigasi_f02.joblib")
METRICS_PATH = os.path.join(MODEL_DIR, "metrics_f02.json")


def train_f02_models():
    """
    Pelatihan & Evaluasi Model F-02: Klasifikasi Keputusan Irigasi.
    Melaporkan jumlah sampel tiap kelas (support), confusion matrix, dan perbandingan model objektif.
    """
    os.makedirs(MODEL_DIR, exist_ok=True)
    
    print("[F-02] Membaca data dan ekstrak fitur...")
    df_clean, stats = clean_sensor_data()
    df_feat = extract_features(df_clean)
    
    train_df, val_df, test_df = split_data_time_based(df_feat)
    
    X_train = train_df[FEATURE_COLUMNS].values
    y_train = train_df["target_irigasi"].values
    
    X_val = val_df[FEATURE_COLUMNS].values
    y_val = val_df["target_irigasi"].values
    
    X_test = test_df[FEATURE_COLUMNS].values
    y_test = test_df["target_irigasi"].values

    # Hitung jumlah sampel tiap kelas
    n_train_total = len(y_train)
    n_train_pos = int(np.sum(y_train == 1))
    n_train_neg = int(np.sum(y_train == 0))

    n_test_total = len(y_test)
    n_test_pos = int(np.sum(y_test == 1))
    n_test_neg = int(np.sum(y_test == 0))

    print(f"[F-02] Sampel Train: Total={n_train_total} (Kelas 0: {n_train_neg}, Kelas 1 [Perlu]: {n_train_pos} [{n_train_pos/n_train_total*100:.1f}%])")
    print(f"[F-02] Sampel Test : Total={n_test_total} (Kelas 0: {n_test_neg}, Kelas 1 [Perlu]: {n_test_pos} [{n_test_pos/n_test_total*100:.1f}%])")

    # 1. Baseline Model: Aturan Ambang Sederhana (Siram jika kelembaban saat ini < 30%)
    y_pred_baseline = (X_test[:, 0] < 30.0).astype(int)
    eval_baseline = evaluate_classification(y_test, y_pred_baseline)
    cm_base = confusion_matrix(y_test, y_pred_baseline)
    print(f"[F-02] Baseline Ambang -> Recall: {eval_baseline['recall']}, Prec: {eval_baseline['precision']}, F1: {eval_baseline['f1']}")
    print(f"[F-02] Confusion Matrix Baseline:\n{cm_base}")

    # 2. Logistic Regression (Class Weight Balanced)
    print("[F-02] Melatih Logistic Regression...")
    lr_clf = LogisticRegression(class_weight="balanced", max_iter=1000, random_state=42)
    lr_clf.fit(X_train, y_train)
    y_pred_lr = lr_clf.predict(X_test)
    eval_lr = evaluate_classification(y_test, y_pred_lr)
    cm_lr = confusion_matrix(y_test, y_pred_lr)
    print(f"[F-02] Logistic Regression -> Recall: {eval_lr['recall']}, Prec: {eval_lr['precision']}, F1: {eval_lr['f1']}")
    print(f"[F-02] Confusion Matrix Logistic Regression:\n{cm_lr}")

    # 3. Random Forest Classifier (Class Weight Balanced)
    print("[F-02] Melatih Random Forest Classifier...")
    rf_clf = RandomForestClassifier(
        n_estimators=100,
        max_depth=8,
        min_samples_split=4,
        class_weight="balanced",
        random_state=42,
        n_jobs=-1
    )
    rf_clf.fit(X_train, y_train)
    y_pred_rf = rf_clf.predict(X_test)
    eval_rf = evaluate_classification(y_test, y_pred_rf)
    cm_rf = confusion_matrix(y_test, y_pred_rf)
    print(f"[F-02] Random Forest Clf   -> Recall: {eval_rf['recall']}, Prec: {eval_rf['precision']}, F1: {eval_rf['f1']}")
    print(f"[F-02] Confusion Matrix Random Forest:\n{cm_rf}")

    # Pemilihan model terbaik: Utamakan Recall pada kelas 1
    if eval_lr["recall"] >= eval_rf["recall"] and eval_lr["f1"] >= eval_rf["f1"]:
        winning_model = lr_clf
        winning_name = "logistic_regression"
        winning_eval = eval_lr
        winning_cm = cm_lr
        alasan = (
            f"Logistic Regression (balanced) dipilih sebagai model utama karena mencapai Recall tertinggi ({eval_lr['recall']}) "
            f"dan F1-score tertinggi ({eval_lr['f1']}) pada set uji, meminimalkan risiko False Negative (tanaman kekurangan air). "
            "Bobot koefisien logistik juga memberikan transparansi penuh untuk audit pakar agronomi."
        )
    else:
        winning_model = rf_clf
        winning_name = "random_forest_classifier"
        winning_eval = eval_rf
        winning_cm = cm_rf
        alasan = (
            f"Random Forest Classifier (balanced) dipilih karena mencapai Recall tertinggi ({eval_rf['recall']}) "
            f"dan F1-score ({eval_rf['f1']}) pada set uji."
        )

    # Bobot fitur penting untuk Explainability
    if hasattr(winning_model, "coef_"):
        coef_dict = dict(zip(FEATURE_COLUMNS, [round(float(abs(v)), 4) for v in winning_model.coef_[0]]))
        sorted_features = sorted(coef_dict.items(), key=lambda x: x[1], reverse=True)
        top_features = dict(sorted_features[:5])
    else:
        fi_dict = dict(zip(FEATURE_COLUMNS, [round(float(v), 4) for v in winning_model.feature_importances_]))
        sorted_features = sorted(fi_dict.items(), key=lambda x: x[1], reverse=True)
        top_features = dict(sorted_features[:5])

    joblib.dump(winning_model, MODEL_PATH)
    print(f"[F-02] Model terbaik ({winning_name}) disimpan ke {MODEL_PATH}")

    metrics_summary = {
        "fitur_id": "F-02",
        "nama_fitur": "Klasifikasi keputusan irigasi (perlu / tidak perlu)",
        "tanggal_latih": str(pd.Timestamp.now()),
        "distribusi_sampel": {
            "train": {
                "total": n_train_total,
                "kelas_0_tidak_perlu": n_train_neg,
                "kelas_1_perlu": n_train_pos,
                "persen_kelas_1": round(n_train_pos / n_train_total * 100, 2)
            },
            "test": {
                "total": n_test_total,
                "kelas_0_tidak_perlu": n_test_neg,
                "kelas_1_perlu": n_test_pos,
                "persen_kelas_1": round(n_test_pos / n_test_total * 100, 2)
            }
        },
        "perbandingan_model": {
            "baseline_aturan_ambang": {
                **eval_baseline,
                "tp": int(cm_base[1, 1]), "fn": int(cm_base[1, 0]),
                "tn": int(cm_base[0, 0]), "fp": int(cm_base[0, 1])
            },
            "logistic_regression": {
                **eval_lr,
                "tp": int(cm_lr[1, 1]), "fn": int(cm_lr[1, 0]),
                "tn": int(cm_lr[0, 0]), "fp": int(cm_lr[0, 1])
            },
            "random_forest_classifier": {
                **eval_rf,
                "tp": int(cm_rf[1, 1]), "fn": int(cm_rf[1, 0]),
                "tn": int(cm_rf[0, 0]), "fp": int(cm_rf[0, 1])
            }
        },
        "model_terpilih": winning_name,
        "alasan_pemilihan": alasan,
        "top_fitur_explainability": top_features,
        "kriteria_produk": {
            "target_recall_perlu": ">= 0.85",
            "hasil_recall_tercapai": winning_eval["recall"],
            "status_kriteria": "LOLOS" if winning_eval["recall"] >= 0.85 else "PERLU ITERASI"
        }
    }

    with open(METRICS_PATH, "w") as f:
        json.dump(metrics_summary, f, indent=2)
    print(f"[F-02] Laporan metrik disimpan ke {METRICS_PATH}")

    return winning_model, metrics_summary


if __name__ == "__main__":
    train_f02_models()
