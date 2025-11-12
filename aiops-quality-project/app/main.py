import os
import json
import time
import mlflow.pyfunc
import pandas as pd
from fastapi import FastAPI, Request, HTTPException
from pydantic import BaseModel
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from prometheus_client import CollectorRegistry
from starlette.responses import Response

# --------- ENV ---------
MLFLOW_TRACKING_URI = os.getenv("MLFLOW_TRACKING_URI", "http://mlflow.application.svc.cluster.local:5000")
MODEL_NAME = os.getenv("MODEL_NAME", "iris_rf_model")
MODEL_STAGE = os.getenv("MODEL_STAGE", "Production")
DRIFT_ENABLED = os.getenv("DRIFT_ENABLED", "false").lower() == "true"

# --------- MLflow Model Load ---------
os.environ["MLFLOW_TRACKING_URI"] = MLFLOW_TRACKING_URI
MODEL_URI = f"models:/{MODEL_NAME}/{MODEL_STAGE}"
model = mlflow.pyfunc.load_model(model_uri=MODEL_URI)

# --------- Metrics ---------
registry = CollectorRegistry()
REQUESTS = Counter("inference_requests_total", "Total inference requests", ["endpoint"], registry=registry)
ERRORS = Counter("inference_errors_total", "Total inference errors", ["endpoint", "type"], registry=registry)
LATENCY = Histogram("inference_latency_seconds", "Inference latency seconds", ["endpoint"], registry=registry)
MODEL_INFO = Gauge("inference_model_info", "Model info as labels", ["name", "stage"], registry=registry)
MODEL_INFO.labels(name=MODEL_NAME, stage=MODEL_STAGE).set(1)

# --------- Drift (stub) ---------
def detect_drift(df: pd.DataFrame) -> bool:
    """
    Проста заглушка: перевірка діапазонів/NaN як приклад.
    Замінити на реальний GE/Alibi Detect при потребі.
    """
    if not DRIFT_ENABLED:
        return False
    if df.isna().any().any():
        return True
    # легкий sanity-check: велике відхилення значень
    desc = df.describe().to_dict()
    for _, stats in desc.items():
        if stats.get("std", 0) == 0:
            continue
        # якщо std >> mean — сигнал
        mean = abs(stats.get("mean", 0)) or 1e-9
        if stats.get("std", 0) / mean > 50:
            return True
    return False

# --------- FastAPI ---------
app = FastAPI(title="Inference API", version="1.0.0")

class PredictRequest(BaseModel):
    # очікуємо {"instances": [[...], [...]]} або {"instances": {...}} для табличних фіч
    instances: list

@app.get("/health")
def health():
    return {"status": "ok", "model": MODEL_NAME, "stage": MODEL_STAGE}

@app.get("/metrics")
def metrics():
    data = generate_latest(registry)
    return Response(content=data, media_type=CONTENT_TYPE_LATEST)

@app.post("/predict")
async def predict(req: PredictRequest):
    REQUESTS.labels(endpoint="/predict").inc()
    start = time.time()
    try:
        # нормалізація входу до DataFrame
        X = req.instances
        if isinstance(X, dict):
            df = pd.DataFrame([X])
        else:
            # якщо масив масивів — зробимо DataFrame без колонок
            df = pd.DataFrame(X)
        drift = detect_drift(df)

        preds = model.predict(df)
        payload = {"predictions": _to_serializable(preds), "drift_detected": drift}
        return payload
    except HTTPException:
        ERRORS.labels(endpoint="/predict", type="http").inc()
        raise
    except Exception as e:
        ERRORS.labels(endpoint="/predict", type="exception").inc()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        LATENCY.labels(endpoint="/predict").observe(time.time() - start)

def _to_serializable(x):
    try:
        if hasattr(x, "tolist"):
            return x.tolist()
        json.dumps(x)  # перевірка серіалізації
        return x
    except Exception:
        return str(x)