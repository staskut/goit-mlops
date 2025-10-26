# Інструкція з розгортання інфраструктури AWS EKS + VPC

## Опис

Цей проєкт автоматизує створення інфраструктури AWS за допомогою Terraform.
Він створює:

* **VPC** із публічними та приватними підмережами (через офіційний модуль `terraform-aws-modules/vpc/aws`)
* **EKS кластер** із двома керованими групами вузлів (CPU та GPU)
* **CloudWatch логування** та базові теги для моніторингу та управління

---

## Структура проєкту

```
eks-vpc-cluster/
├── backend.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tf
├── vpc/
│   ├── backend.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tf
└── eks/
    ├── backend.tf
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── terraform.tf
```

---

## ⚙️ Передумови

1. Встановити Terraform

2. Встановити AWS CLI

3. Налаштувати AWS облікові дані:

   ```bash
   aws configure
   ```

   або використати профіль з `~/.aws/credentials`

4. Переконатися, що існує S3-бакет для зберігання `terraform.tfstate`, наприклад:

   ```bash
   aws s3api create-bucket \
     --bucket mlops-tfstate-stankutnyk \
     --region eu-west-2 \
     --create-bucket-configuration LocationConstraint=eu-west-2

   aws s3api put-bucket-versioning \
     --bucket mlops-tfstate-stankutnyk \
     --versioning-configuration Status=Enabled
   ```

---

## Команди для запуску інфраструктури

### Ініціалізація Terraform

```bash
terraform init -reconfigure
```

> Виконує ініціалізацію бекенду, завантажує модулі та провайдери.

---


---

### Попередній перегляд плану змін

```bash
terraform plan
```

> Показує, які ресурси будуть створені, змінені або видалені.

---

### Створення інфраструктури

```bash
terraform apply
```

> Підтвердіть виконання командою `yes`. Після завершення буде створено VPC і EKS кластер із двома групами вузлів.

---

### Підключення до кластера Kubernetes

```bash
aws eks --region eu-west-2 update-kubeconfig --name goit-cluster
```

Перевірка стану вузлів:

```bash
kubectl get nodes
```

> Ви повинні побачити дві групи вузлів: `cpu-nodes` і `gpu-nodes`.

---

### Видалення інфраструктури

```bash
terraform destroy
```

> Знищує усі створені ресурси AWS (крім S3-бакету для стану).

---

## Перевірка після розгортання

1. Переконайтеся, що кластер доступний:

   ```bash
   kubectl cluster-info
   ```
2. Перевірте CloudWatch Logs:

   ```bash
   aws logs describe-log-groups --region eu-west-2
   ```
3. Переконайтеся, що дві групи вузлів працюють:

   ```bash
   kubectl get nodes -o wide
   ```

---