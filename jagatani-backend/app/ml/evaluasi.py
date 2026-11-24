import numpy as np
import pandas as pd
from typing import Dict, Any
from sklearn.metrics import mean_absolute_error, mean_squared_error, precision_score, recall_score, f1_score, accuracy_score


def evaluate_regression(y_true: np.ndarray, y_pred: np.ndarray) -> Dict[str, float]:
    """
    Menghitung MAE dan RMSE untuk evaluasi regresi kelembaban tanah 24 jam (F-01).
    """
    mae = float(mean_absolute_error(y_true, y_pred))
    rmse = float(np.sqrt(mean_squared_error(y_true, y_pred)))
    return {
        "mae": round(mae, 3),
        "rmse": round(rmse, 3)
    }


def evaluate_classification(y_true: np.ndarray, y_pred: np.ndarray) -> Dict[str, float]:
    """
    Menghitung Precision, Recall, F1, dan Akurasi untuk klasifikasi irigasi (F-02).
    Fokus utama: Recall kelas 'perlu irigasi' (kelas 1).
    """
    prec = float(precision_score(y_true, y_pred, pos_label=1, zero_division=0))
    rec = float(recall_score(y_true, y_pred, pos_label=1, zero_division=0))
    f1 = float(f1_score(y_true, y_pred, pos_label=1, zero_division=0))
    acc = float(accuracy_score(y_true, y_pred))
    return {
        "precision": round(prec, 3),
        "recall": round(rec, 3),
        "f1": round(f1, 3),
        "accuracy": round(acc, 3)
    }
