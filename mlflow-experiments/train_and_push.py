import os
import joblib
import mlflow.sklearn
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.linear_model import SGDClassifier
from sklearn.metrics import accuracy_score, log_loss

# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------
mlflow.set_tracking_uri(os.environ["MLFLOW_TRACKING_URI"])
mlflow.set_experiment("Iris_Training")

# -------------------------------------------------------------------
# Data
# -------------------------------------------------------------------
X, y = load_iris(return_X_y=True)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# -------------------------------------------------------------------
# Training loop
# -------------------------------------------------------------------
learning_rates = [0.001, 0.01, 0.1]
epochs_list = [100, 300, 500]
results = []

for lr in learning_rates:
    for epochs in epochs_list:
        with mlflow.start_run() as run:
            model = SGDClassifier(
                loss="log_loss",
                learning_rate="constant",
                eta0=lr,
                max_iter=epochs,
                random_state=42
            )
            model.fit(X_train, y_train)

            y_pred = model.predict(X_test)
            y_prob = model.predict_proba(X_test)

            acc = accuracy_score(y_test, y_pred)
            loss = log_loss(y_test, y_prob)

            # Log to MLflow
            mlflow.log_param("learning_rate", lr)
            mlflow.log_param("epochs", epochs)
            mlflow.log_metric("accuracy", acc)
            mlflow.log_metric("loss", loss)

            # Save and log model
            os.makedirs("models", exist_ok=True)
            model_path = f"models/model_lr{lr}_ep{epochs}.joblib"
            joblib.dump(model, model_path)
            mlflow.log_artifact(model_path)

            # Push metrics to Prometheus Pushgateway
            registry = CollectorRegistry()
            acc_gauge = Gauge("mlflow_accuracy", "Model accuracy", ["run_id"], registry=registry)
            loss_gauge = Gauge("mlflow_loss", "Model loss", ["run_id"], registry=registry)

            acc_gauge.labels(run.info.run_id).set(acc)
            loss_gauge.labels(run.info.run_id).set(loss)

            push_to_gateway(os.environ["PUSHGATEWAY_URL"], job="prometheus-pushgateway", registry=registry)
            print(f"[Pushed] Run {run.info.run_id} -> acc={acc:.4f}, loss={loss:.4f}")

            results.append((acc, run.info.run_id, model_path))

# -------------------------------------------------------------------
# Best model
# -------------------------------------------------------------------
best_acc, best_run, best_model_path = max(results, key=lambda x: x[0])
print(f"\nBest run: {best_run} | accuracy={best_acc:.4f}")

os.makedirs("best_model", exist_ok=True)
joblib.dump(joblib.load(best_model_path), "best_model/model.joblib")
print("Best model saved to ./best_model/model.joblib")