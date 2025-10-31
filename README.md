# ArgoCD Deployment on EKS

## 1. Deploy ArgoCD via Terraform

### Steps

```bash
cd terraform/argocd
terraform init
terraform apply
```

After the apply completes, verify the pods:

```bash
kubectl get pods -n infra-tools
```

Expected output:

```
NAME                                         READY   STATUS    RESTARTS   AGE
argocd-application-controller-xxxxxx         1/1     Running   0          2m
argocd-repo-server-xxxxxx                   1/1     Running   0          2m
argocd-server-xxxxxx                        1/1     Running   0          2m
```
![img.png](img.png)
---

## 2. Access ArgoCD UI

### Port-forward to the UI:

```bash
kubectl port-forward svc/argocd-server -n infra-tools 8080:443
```

Open in your browser: [https://localhost:8080](https://localhost:8080)

![img_1.png](img_1.png)

### Retrieve admin password:

```bash
kubectl -n infra-tools get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode
```

Login with:

* **Username:** `admin`
* **Password:** (from above command)

---

## 3. Connect Git Repository to ArgoCD

### Add repository from CLI (optional)

```bash
argocd login localhost:8080 --username admin --password <password> --insecure
argocd repo add https://github.com/<your-username>/goit-argo.git --name goit-argo
```

Or, add it through the **ArgoCD UI** under *Settings → Repositories*.


---

## 4. Deploy NGINX Application

### Application manifest (`goit-argo/applications/nginx-app.yaml`):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx
  namespace: infra-tools
spec:
  project: default
  source:
    repoURL: https://charts.bitnami.com/bitnami
    chart: nginx
    targetRevision: 15.10.0
    helm:
      values: |
        image:
          tag: latest
          pullPolicy: Always
        service:
          type: ClusterIP
        replicaCount: 1
  destination:
    server: https://kubernetes.default.svc
    namespace: nginx
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Commit and push to the Git repository:

```bash
git add applications/nginx-app.yaml
git commit -m "Add NGINX Application"
git push
```

Apply in the cluster:

```bash
kubectl apply -f https://raw.githubusercontent.com/<your-username>/goit-argo/main/applications/nginx-app.yaml -n infra-tools
```

ArgoCD will detect the Application and start syncing automatically.

Check status:

```bash
kubectl get applications -n infra-tools
```

Expected:

```
NAME      SYNC STATUS   HEALTH STATUS
nginx     Synced        Healthy
```
![img_2.png](img_2.png)
---

## 5. Verify NGINX Deployment

Check the deployed resources:

```bash
kubectl get pods -n nginx
kubectl get svc -n nginx
```

Expected output:

```
NAME                     READY   STATUS    RESTARTS   AGE
nginx-xxxxxxx-xxxxx      1/1     Running   0          1m

NAME       TYPE        CLUSTER-IP       PORT(S)
nginx      ClusterIP   10.xxx.xxx.xxx   80/TCP
```
![img_3.png](img_3.png)
---

## 6. Access NGINX via Port-Forward

```bash
kubectl port-forward svc/nginx -n nginx 8081:80
```

Then open [http://localhost:8081](http://localhost:8081)

Expected result: **Default NGINX Welcome Page** 🟢
![img_4.png](img_4.png)
---
