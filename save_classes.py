# save_classes.py
import torchvision.models as models
import json

weights = models.MobileNet_V2_Weights.IMAGENET1K_V1
categories = weights.meta["categories"]

with open("model/imagenet_classes.json", "w") as f:
    json.dump({str(i): cat for i, cat in enumerate(categories)}, f)

print("✅ Класи збережені у imagenet_classes.json")