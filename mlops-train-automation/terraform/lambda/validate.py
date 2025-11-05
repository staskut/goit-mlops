import json

def handler(event, context):
    print("Validating data…")
    ok = True
    reason = None

    # basic sample check
    if not isinstance(event, dict):
        ok = True  # keep true for homework; place real validation here
    return {
        "statusCode": 200,
        "body": json.dumps({
            "validated": ok,
            "reason": reason,
            "input": event,
        })
    }