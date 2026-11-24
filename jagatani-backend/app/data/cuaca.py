import requests
import datetime
from typing import Dict, Any, List

OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"
DEFAULT_LAT = -6.5971
DEFAULT_LNG = 106.8060


def fetch_forecast_24h(lat: float = DEFAULT_LAT, lng: float = DEFAULT_LNG) -> Dict[str, Any]:
    """
    Mengambil prakiraan cuaca per jam (hourly) 24 jam ke depan dari Open-Meteo API.
    """
    params = {
        "latitude": lat,
        "longitude": lng,
        "hourly": "temperature_2m,relative_humidity_2m,precipitation,weather_code",
        "timezone": "Asia/Jakarta",
        "forecast_days": 2
    }

    try:
        response = requests.get(OPEN_METEO_URL, params=params, timeout=6)
        if response.status_code == 200:
            data = response.json()
            hourly = data.get("hourly", {})
            times: List[str] = hourly.get("time", [])
            temps: List[float] = hourly.get("temperature_2m", [])
            hums: List[int] = hourly.get("relative_humidity_2m", [])
            precips: List[float] = hourly.get("precipitation", [])
            codes: List[int] = hourly.get("weather_code", [])

            now_str = datetime.datetime.now().strftime("%Y-%m-%dT%H:00")
            start_idx = 0
            for idx, t in enumerate(times):
                if t >= now_str:
                    start_idx = idx
                    break

            end_idx = min(start_idx + 24, len(times))
            
            prakiraan_24h = []
            for i in range(start_idx, end_idx):
                prakiraan_24h.append({
                    "jam_ke": i - start_idx + 1,
                    "waktu": times[i],
                    "suhu": float(temps[i]),
                    "kelembaban_udara": float(hums[i]),
                    "curah_hujan": float(precips[i]),
                    "weather_code": int(codes[i])
                })

            precip_list = [p["curah_hujan"] for p in prakiraan_24h]
            precip_6h = sum(precip_list[:6])
            precip_24h = sum(precip_list[:24])

            return {
                "status": "online",
                "total_hujan_6jam": round(precip_6h, 2),
                "total_hujan_24jam": round(precip_24h, 2),
                "akan_hujan_6jam": precip_6h >= 1.0,
                "hujan_lebat_24jam": precip_24h >= 20.0,
                "prakiraan_per_jam": prakiraan_24h
            }
    except Exception as e:
        pass

    # Fallback realistis cuaca tropis Indonesia jika offline
    return get_fallback_forecast()


def get_fallback_forecast() -> Dict[str, Any]:
    now = datetime.datetime.now().replace(minute=0, second=0, microsecond=0)
    prakiraan_24h = []
    for i in range(1, 25):
        t = now + datetime.timedelta(hours=i)
        hour = t.hour
        # Diurnal pattern
        if 6 <= hour <= 12:
            suhu = 27.0 + (hour - 6) * 0.8
            hum = 80 - (hour - 6) * 2.0
            precip = 0.0
            code = 1
        elif 13 <= hour <= 17:
            suhu = 32.0 - (hour - 13) * 0.5
            hum = 72 + (hour - 13) * 2.5
            precip = 0.5 if hour == 15 else 0.0
            code = 2
        else:
            suhu = 26.0
            hum = 85.0
            precip = 0.0
            code = 0

        prakiraan_24h.append({
            "jam_ke": i,
            "waktu": t.strftime("%Y-%m-%dT%H:00"),
            "suhu": round(suhu, 1),
            "kelembaban_udara": round(hum, 1),
            "curah_hujan": precip,
            "weather_code": code
        })

    precip_list = [p["curah_hujan"] for p in prakiraan_24h]
    precip_6h = sum(precip_list[:6])
    precip_24h = sum(precip_list[:24])

    return {
        "status": "fallback",
        "total_hujan_6jam": round(precip_6h, 2),
        "total_hujan_24jam": round(precip_24h, 2),
        "akan_hujan_6jam": precip_6h >= 1.0,
        "hujan_lebat_24jam": precip_24h >= 20.0,
        "prakiraan_per_jam": prakiraan_24h
    }
