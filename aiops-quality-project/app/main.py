import os
import joblib
import logging
import requests
import numpy as np
from fastapi import FastAPI, Request, BackgroundTasks
from pydantic import BaseModel
from typing import List
from pythonjsonlogger import jsonlogger
from prometheus_fastapi_instrumentator import Instrumentator

# --- Конфігурація логування ---
# Налаштовуємо JSON логер, щоб Loki міг легко парсити логи
logger = logging.getLogger("aiops-logger")
logger.setLevel(logging.INFO)
logHandler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter(
    fmt='%(asctime)s %(levelname)s %(name)s %(message)s'
)
logHandler.setFormatter(formatter)
logger.addHandler(logHandler)

# --- Завантаження артефактів ---
# Завантажуємо модель та детектор дрейфу при старті
try:
    MODEL_PATH = os.getenv("MODEL_PATH", "app/model.pkl")
    DRIFT_DETECTOR_PATH = os.getenv("DRIFT_DETECTOR_PATH", "app/drift_detector.pkl")

    model = joblib.load(MODEL_PATH)
    drift_detector = joblib.load(DRIFT_DETECTOR_PATH)

    logger.info("Model and drift detector loaded successfully.")
except FileNotFoundError:
    logger.error("Model or drift detector file not found. Make sure paths are correct.")
    # У реальному світі тут можна було б завершити роботу, але для демо ми продовжимо
    model, drift_detector = None, None

# --- Отримання URL для Webhook з оточення ---
# Цей URL буде викликатися при виявленні дрейфу
GITHUB_WEBHOOK_URL = os.getenv("GITHUB_WEBHOOK_URL")
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")  # Потрібен для автентифікації dispatch

# --- Ініціалізація FastAPI ---
app = FastAPI()

# Додаємо Prometheus метрики (будуть доступні на /metrics)
Instrumentator().instrument(app).expose(app)


class PredictionRequest(BaseModel):
    # Очікуємо 4 фічі, як в Iris dataset
    features: List[List[float]]


class PredictionResponse(BaseModel):
    prediction: List[int]
    is_drift: int


# --- Функція для виклику Webhook ---
def trigger_retrain_webhook(payload: dict):
    """
    Асинхронно викликає GitHub Actions webhook (repository_dispatch).
    """
    if not GITHUB_WEBHOOK_URL or not GITHUB_TOKEN:
        logger.warning("GITHUB_WEBHOOK_URL or GITHUB_TOKEN is not set. Skipping retrain trigger.")
        return

    headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": f"token {GITHUB_TOKEN}"
    }
    # "event_type" має збігатися з тим, що вказано у workflow_dispatch
    data = {"event_type": "drift_detected"}

    try:
        response = requests.post(GITHUB_WEBHOOK_URL, json=data, headers=headers)
        response.raise_for_status()  # Викличе помилку, якщо статус не 2xx
        logger.info(f"Successfully triggered retrain webhook. Status: {response.status_code}")
    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to trigger retrain webhook: {e}")


# --- Основна логіка ---
def predict_and_detect_drift(data: np.ndarray) -> (np.ndarray, int):
    """
    Робить передбачення та перевіряє на дрейф.
    Повертає (передбачення, прапор_дрейфу).
    """
    if model is None or drift_detector is None:
        logger.error("Model or drift detector not loaded.")
        return [], -1

    # 1. Передбачення
    predictions = model.predict(data)

    # 2. Перевірка на дрейф
    # predict() детектора повертає dict з p-value та is_drift
    drift_result = drift_detector.predict(data, return_p_val=True)
    is_drift = drift_result['data']['is_drift']

    return predictions, is_drift


# --- Ендпоінти API ---

@app.get("/")
def read_root():
    return {"status": "AIOps Quality Project API is running"}


@app.post("/predict", response_model=PredictionResponse)
async def predict(request: PredictionRequest, background_tasks: BackgroundTasks):
    input_data = np.array(request.features)

    # 1. Логуємо вхідні дані (Loki їх підбере)
    logger.info("Received prediction request", extra={"input_features": request.features})

    # 2. Робимо передбачення та детекцію дрейфу
    predictions, is_drift = predict_and_detect_drift(input_data)

    # 3. Якщо дрейф виявлено - логуємо та запускаємо webhook у фоні
    if is_drift == 1:
        logger.warning("Drift detected!", extra={"input_features": request.features})
        # Додаємо виклик webhook у фонове завдання, щоб не блокувати відповідь
        background_tasks.add_task(trigger_retrain_webhook, payload={"features": request.features})

    response_data = {
        "prediction": predictions.tolist(),
        "is_drift": is_drift
    }

    # 4. Логуємо відповідь
    logger.info("Sending prediction response", extra=response_data)

    return response_data