# inference.py
import torch
from torchvision import transforms
from PIL import Image
import json
import sys

# Завантажуємо TorchScript модель
model = torch.jit.load("../model/mobilenet_v2.pt")
model.eval()

# Трансформації як у ImageNet
preprocess = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    )
])

# Класи ImageNet (1000)
with open("../model/imagenet_classes.json") as f:
    idx_to_labels = json.load(f)

def predict(image_path):
    image = Image.open(image_path).convert("RGB")
    input_tensor = preprocess(image).unsqueeze(0)

    with torch.no_grad():
        outputs = model(input_tensor)
        probs = torch.nn.functional.softmax(outputs[0], dim=0)

    # Топ-3
    top3_prob, top3_catid = torch.topk(probs, 3)
    for i in range(top3_prob.size(0)):
        print(f"{idx_to_labels[str(top3_catid[i].item())]}: {top3_prob[i].item():.4f}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Використання: python3 inference.py path_to_image.jpg")
        sys.exit(1)
    predict(sys.argv[1])