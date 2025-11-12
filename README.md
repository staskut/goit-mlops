# MLOps Final Project

## Архітектура та складові елементи

| Компонент                             | Основна роль                                                                      |
| ------------------------------------- | --------------------------------------------------------------------------------- |
| **GitLab CI/CD**                      | Автоматизація повного циклу ML: тренування, створення образу та деплой моделі     |
| **FastAPI**                           | REST‑інтерфейс для виконання інференсу, перевірки стану та збору метрик           |
| **Helm**                              | Керування деплоєм FastAPI‑додатку у Kubernetes середовищі                         |
| **ArgoCD**                            | Реалізація GitOps — автоматичне оновлення кластера при зміні в Git‑репозиторії    |
| **Prometheus + Grafana**              | Система збору, зберігання та візуалізації метрик: запити, latency, помилки, дрейф |
| **Loki + Promtail**                   | Агрегація логів stdout із контейнерів для централізованого моніторингу            |
| **Great Expectations / Alibi Detect** | Валідація якості даних і детекція дрейфу у реальному часі                         |

---

## Розгортання середовища

### 1. Необхідні сервіси

* Kubernetes кластер (наприклад, Amazon EKS)
* ArgoCD із доступом до Git‑репозиторію
* MLflow Tracking Server із PostgreSQL та MinIO
* Docker Registry (AWS ECR)
* Prometheus і Grafana для метрик

### 2. Локальний запуск FastAPI

```bash
cd app
export MLFLOW_TRACKING_URI=http://localhost:5000
export MODEL_NAME=iris_rf_model
export MODEL_STAGE=Production
uvicorn main:app --reload --port 8080
```

Перевірка запиту:

```bash
curl -X POST localhost:8080/predict \
  -H 'Content-Type: application/json' \
  -d '{"instances": [[5.1, 3.5, 1.4, 0.2]]}'
```

### 3. Створення Docker‑образу

```bash
docker build -t application .
docker tag application:latest <account_id>.dkr.ecr.us-east-1.amazonaws.com/goit-mlops:v0.1.0
docker push <account_id>.dkr.ecr.us-east-1.amazonaws.com/application:v0.1.0
```

### 4. Деплой через Helm і ArgoCD

При оновленні Helm‑чарту ArgoCD автоматично застосовує нову конфігурацію у продакшн‑кластері.

---

## Система моніторингу

### Метрики Prometheus (`/metrics`)

* `inference_requests_total` — загальна кількість запитів
* `inference_latency_seconds` — час відповіді на запит
* `inference_errors_total` — кількість помилкових запитів
* `inference_model_info` — відомості про поточну модель

### Grafana

Після імпорту файлу `grafana/dashboards.json` доступні візуалізації:

* кількість запитів у часі;
* 95‑й перцентиль latency;
* статистика помилок;
* сповіщення про дрейф.

---

## Виявлення дрейфу даних

```python
def detect_drift(df):
    if df.isna().any().any():
        return True
    if df.std().mean() > df.mean().mean() * 10:
        return True
    return False
```

**Корисні бібліотеки:**

* **Great Expectations** — перевірка консистентності даних перед інференсом;
* **Alibi Detect** — онлайн‑детекція дрейфу під час роботи моделі.

---

## CI/CD конвеєр

| Етап       | Job           | Призначення                                           |
| ---------- | ------------- | ----------------------------------------------------- |
| **train**  | `train_model` | Навчання моделі та її реєстрація у MLflow Registry    |
| **build**  | `build_image` | Збірка Docker‑образу й завантаження до реєстру        |
| **deploy** | `deploy_helm` | Оновлення Helm‑чарту, що синхронізується через ArgoCD |

---

## Автоматичне перенавчання моделі

1. Drift‑детектор фіксує зміну у статистиці вхідних даних.
2. Відправляє webhook у GitLab для запуску `train_model`.
3. Створюється нова версія у **MLflow Registry**.
4. CI/CD генерує новий Docker‑образ і оновлює Helm‑чарт.
5. **ArgoCD** оновлює сервіс у кластері без простою.

---
