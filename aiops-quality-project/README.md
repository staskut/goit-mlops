# MLOps Final Project: AIOps Quality Monitoring

Цей проєкт демонструє повний цикл MLOps для "quality-aware" сервісу, який включає моніторинг, детекцію дрейфу даних та автоматичне перенавчання моделі.

Система задеплоєна в Kubernetes (EKS) з використанням GitOps (ArgoCD) та CI/CD (GitHub Actions).

## Архітектура

1.  **Inference Service**: `FastAPI` сервіс (`app/main.py`), який приймає запити, повертає передбачення моделі (`model.pkl`) та перевіряє вхідні дані на дрейф (`drift_detector.pkl`).
2.  **CI/CD**: `GitHub Actions` (`.github/workflows/cicd.yml`) відповідає за:
    * Перенавчання моделі (`model/train.py`).
    * Збірку нового Docker-образу.
    * Публікацію образу в `AWS ECR`.
    * Оновлення `helm/values.yaml` новим тегом образу.
    * Коміт `values.yaml` назад у репозиторій.
3.  **GitOps (CD)**: `ArgoCD` (`argocd/application.yaml`) відстежує `helm/` директорію. Коли GitHub Actions оновлює `values.yaml`, ArgoCD автоматично помічає зміну (auto-sync) та викочує нову версію сервісу в Kubernetes.
4.  **Моніторинг**:
    * `Prometheus`: Збирає метрики (QPS, Latency) з FastAPI ендпоінта `/metrics` (налаштовується через `prometheus/additionalScrapeConfigs.yaml`).
    * `Loki` + `Promtail`: Збирає `stdout` логи з подів (в JSON-форматі для легкого парсингу).
    * `Grafana`: Візуалізує метрики з Prometheus та Loki (`grafana/dashboards.json`).
5.  **Drift & Retrain**:
    * При кожному запиті FastAPI перевіряє дані на дрейф.
    * Якщо дрейф виявлено (`is_drift: 1`), сервіс надсилає `repository_dispatch` (webhook) до GitHub.
    * Цей webhook тригерить CI/CD пайплайн `retrain-build-and-deploy`.

## Налаштування та Запуск

### Передумови

1.  Працюючий EKS-кластер.
2.  Встановлені `kubectl` та `helm`.
3.  Встановлені ArgoCD, Prometheus, Grafana та Loki у вашому кластері.
4.  Створений репозиторій `AWS ECR` з назвою, вказаною в `cicd.yml` (`ECR_REPOSITORY`).
5.  Ваш Git-репозиторій (напр. `github.com/YOUR_USERNAME/YOUR_REPO`).

### Налаштування GitHub Secrets

У вашому GitHub репозиторії перейдіть до `Settings > Secrets and variables > Actions` та створіть такі секрети:

1.  `AWS_ACCESS_KEY_ID`: Ваш AWS ключ.
2.  `AWS_SECRET_ACCESS_KEY`: Ваш AWS секретний ключ. (Ці ключі потрібні для пушу в ECR).
3.  `GH_PAT`: GitHub Personal Access Token з правами `repo`. (Потрібен для автентифікації виклику webhook з FastAPI).
4.  `REPO_WEBHOOK_URL`: Повний URL для виклику `repository_dispatch`.
    * Формат: `https://api.github.com/repos/YOUR_USERNAME/YOUR_REPO/dispatches`

### Деплоймент

1.  **Налаштуйте `helm/values.yaml`**:
    * Встановіть `env.GITHUB_WEBHOOK_URL` (значення `REPO_WEBHOOK_URL` з секретів).
    * Встановіть `env.GITHUB_TOKEN` (значення `GH_PAT` з секретів).
    * *Примітка: Зберігати токен у `values.yaml` не ідеально. Краще використовувати Kubernetes Secrets та посилатися на них через `valueFrom`. Але для простоти проєкту це спрацює.*

2.  **Налаштуйте `argocd/application.yaml`**:
    * Оновіть `spec.source.repoURL` на URL вашого репозиторію.

3.  **Застосуйте ArgoCD Application**:
    ```sh
    kubectl apply -f argocd/application.yaml
    ```
    ArgoCD тепер почне стежити за вашим репозиторієм та задеплоїть сервіс у неймспейс `mlops-app`.

4.  **Перший запуск пайплайну**:
    * Щоб отримати перший образ, запустіть пайплайн `MLOps CI/CD` вручну в GitHub Actions (вкладка `Actions` > `MLOps CI/CD` > `Run workflow`).
    * Це створить `model.pkl`, збере образ, запушить в ECR та оновить `values.yaml`.
    * ArgoCD автоматично підхопить зміни та задеплоїть першу версію.

## Як перевірити проєкт

### 1. Перевірка API
Використовуйте `port-forward`, щоб отримати доступ до сервісу:

```sh
kubectl port-forward svc/aiops-quality-project -n mlops-app 8080:80
```
Відправте запит (це "нормальні" дані для Iris):

Bash

curl -X POST "http://localhost:8080/predict" \
-H "Content-Type: application/json" \
-d '{
  "features": [
    [5.1, 3.5, 1.4, 0.2],
    [4.9, 3.0, 1.4, 0.2]
  ]
}'

# Очікувана відповідь (без дрейфу):
# {"prediction":[0,0],"is_drift":0}
2. Перевірка логування (Loki)
Перевірте логи поду, щоб побачити JSON-повідомлення:

Bash

kubectl logs -n mlops-app -l app.kubernetes.io/name=aiops-quality-project -f
Ви маєте побачити {"asctime": "...", "levelname": "INFO", "name": "aiops-logger", "message": "Received prediction request", ...}

3. Перевірка детектора дрейфу
Відправте дані, які сильно відрізняються від тренувальних (Iris):

Bash

curl -X POST "http://localhost:8080/predict" \
-H "Content-Type: application/json" \
-d '{
  "features": [
    [150.0, 10.0, 50.0, 20.0],
    [100.0, 20.0, 60.0, 10.0]
  ]
}'

# Очікувана відповідь (дрейф виявлено):
# {"prediction":[2,2],"is_drift":1}
4. Перевірка спрацювання retrain-пайплайну
Після відправки "аномального" запиту (крок 3), перевірте логи поду (kubectl logs ...). Ви маєте побачити:

"message": "Drift detected!"

"message": "Successfully triggered retrain webhook."

Перейдіть на вкладку Actions у вашому GitHub репозиторії. Ви побачите, що воркфлоу MLOps CI/CD був автоматично запущений з тригером repository_dispatch.

5. Перевірка оновлення моделі (ArgoCD)
Дочекайтеся, поки GitHub Actions воркфлоу завершиться.

Перевірте коміти у вашому репозиторії. Ви побачите новий коміт від github-actions[bot] з повідомленням ci: update image tag to ....

Відкрийте UI ArgoCD. Ви побачите, що Application aiops-quality-project перейшов у стан Syncing (або вже Synced), оскільки він виявив зміни в helm/values.yaml.

ArgoCD виконає rolling update вашого деплойменту з новим Docker-образом.

6. Перевірка моніторингу (Grafana)
Відкрийте ваш Grafana дашборд.

Згенеруйте трохи трафіку (наприклад, за допомогою hey або простого while циклу).

Ви побачите, як оновлюються панелі QPS та p95 Latency.

Якщо ви відправите аномальні дані, панель Drift Alerts (з Loki) покаже сплеск.