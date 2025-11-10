import numpy as np
import pandas as pd
from sklearn.datasets import load_iris
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from alibi_detect.cd import TabularDrift
import joblib
import os

print("Starting model and drift detector training...")

# 1. Завантаження та підготовка даних
iris = load_iris()
X, y = iris.data, iris.target
feature_names = iris.feature_names
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.5, random_state=42)

# 2. Тренування моделі
model = LogisticRegression(max_iter=200)
model.fit(X_train, y_train)
print("Model trained.")

# 3. Тренування детектора дрейфу (використовуємо X_train як референтні дані)
# p_val (поріг) = 0.05. Якщо p-value < 0.05, ми вважаємо, що відбувся дрейф.
drift_detector = TabularDrift(X_train, p_val=.05)
print("Drift detector trained.")

# 4. Збереження артефактів у папку 'app/'
# Це важливо, оскільки app/Dockerfile буде копіювати вміст папки 'app/'
output_dir = "app"
os.makedirs(output_dir, exist_ok=True)

joblib.dump(model, os.path.join(output_dir, "model.pkl"))
joblib.dump(drift_detector, os.path.join(output_dir, "drift_detector.pkl"))

print(f"Artifacts saved to '{output_dir}' directory.")
print("Training script finished.")