# Використовуємо офіційний Python образ
FROM python:3.10-slim

# Встановлюємо робочу директорію
WORKDIR /app

# Копіюємо файл залежностей
COPY ./app/requirements.txt /app/requirements.txt

# Встановлюємо залежності
# --no-cache-dir зменшує розмір образу
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо весь код нашого 'app'
# Це включає main.py, model.pkl, та drift_detector.pkl (які згенерував train.py)
COPY ./app/ /app/

# Відкриваємо порт, на якому буде працювати FastAPI
EXPOSE 8000

# Запускаємо сервіс
# --host 0.0.0.0 робить його доступним ззовні контейнера
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]