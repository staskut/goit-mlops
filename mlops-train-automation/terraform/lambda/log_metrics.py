import json
import time

def handler(event, context):
    print("Logging metrics…")
    payload = event if isinstance(event, dict) else {}
    # stubbed metrics for demo
    metrics = {"accuracy": 0.9, "loss": 0.33, "ts": int(time.time())}
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "metrics logged",
            "metrics": metrics,
            "input": payload,
        })
    }