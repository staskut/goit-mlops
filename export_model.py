import torch
import torchvision.models as models

# Завантажуємо модель з предтренованими вагами
model = models.mobilenet_v2(weights=models.MobileNet_V2_Weights.IMAGENET1K_V1)
model.eval()

# TorchScript
example = torch.randn(1, 3, 224, 224)
traced_script_module = torch.jit.trace(model, example)

# Збереження у файл
traced_script_module.save("model/mobilenet_v2.pt")

print("✅ TorchScript модель збережена у mobilenet_v2.pt")