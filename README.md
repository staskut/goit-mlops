# ML Inference Service — Dockerized

Цей проєкт демонструє контейнеризацію ML-моделі (TorchScript MobileNetV2) у двох варіантах Docker-образів:

* **Fat (python:3.11)** — важкий базовий образ із повним середовищем.
* **Optimized (python:3.13-slim)** — полегшений multi-stage образ.

---

## 1. Підготовка середовища

Переконайтесь, що Docker встановлено:

```bash
docker --version
docker compose version
```

Якщо Docker відсутній — запустіть:

```bash
chmod +x install_dev_tools.sh
./install_dev_tools.sh
```

---

## 2. Збірка образів

### Fat образ:

```bash
docker build -t pytorch-infer-fat -f Dockerfile.fat .
```

### Optimized образ:

```bash
docker build -t pytorch-infer-optimized -f Dockerfile.slim .
```

Перевірка створених образів:

```bash
docker images
```

Очікувано:

```
REPOSITORY               TAG       IMAGE ID       CREATED         SIZE
pytorch-infer-fat        latest    a1b2c3d4e5f6   3 minutes ago   1.81GB
pytorch-infer-optimized  latest    9f8e7d6c5b4a   2 minutes ago   840MB
```

---

## 3. Запуск контейнера для inference

Приклад запуску з локальним зображенням `data/dog.jpeg`:

```bash
docker run --rm -v $(pwd)/data:/data pytorch-infer-optimized /data/dog.jpeg
```

або для fat-образу:

```bash
docker run --rm -v $(pwd)/data:/data pytorch-infer-fat /data/dog.jpeg
```

Очікуваний результат (топ-3 класи):

```
Labrador retriever: 0.82
golden retriever: 0.10
flat-coated retriever: 0.05
```

---

## 4. Перевірка кількості шарів

Переглянути історію шарів:

```bash
docker history pytorch-infer-optimized
```

Порахувати кількість шарів:

```bash
docker history --no-trunc --format "{{.ID}}" pytorch-infer-optimized | wc -l
docker history --no-trunc --format "{{.ID}}" pytorch-infer-fat | wc -l
```

Альтернативно, використати `inspect`:

```bash
docker inspect pytorch-infer-optimized --format='{{json .RootFS.Layers}}' | jq length
```

---

## 5. Перевірка Torch та Python у контейнері

Запустити інтерактивну консоль:

```bash
docker run -it pytorch-infer-optimized bash
```

Перевірити:

```bash
python -c "import torch; print(torch.__version__)"
```

Вийти з контейнера:

```bash
exit
```

---

## 6. Очистка непотрібних ресурсів

Після тестів можна видалити образи:

```bash
docker image rm pytorch-infer-fat pytorch-infer-optimized
```

---

**Підсумок:**

* Fat образ (~1.81GB, 21 шар) — для тестів.
* Optimized образ (~840MB, 16 шарів) — для продакшн середовища.
