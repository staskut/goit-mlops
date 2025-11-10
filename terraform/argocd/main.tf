resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.1.2"
  namespace        = var.namespace
  create_namespace = true

  values = [yamlencode({
    server = {
      extraArgs = ["--insecure"]            # disables TLS on argocd-server
      service   = {
        type              = "LoadBalancer"  # or ClusterIP if you'll use Ingress
        servicePortHttp   = 80
        servicePortHttps  = 443
      }
    }
  })]
}

locals {
  repo_url    = "https://github.com/staskut/goit-argo.git"
  target_rev  = "HEAD"
  apps = {
    minio    = "applications/minio-app.yaml"
    mlflow   = "applications/mlflow-app.yaml"
    postgres = "applications/postgres-app.yaml"
  }
}

# Ensure the Argo CD AppProject exists (allows Argo CD to deploy these apps)
# resource "kubernetes_manifest" "argo_project_default" {
#   manifest = {
#     apiVersion = "argoproj.io/v1alpha1"
#     kind       = "AppProject"
#     metadata = {
#       name      = "default"
#       namespace = var.namespace
#     }
#     spec = {
#       description = "Default project for goit-argo apps"
#       sourceRepos = ["https://github.com/staskut/goit-argo.git"]
#       destinations = [
#         {
#           namespace = "*"
#           server    = "https://kubernetes.default.svc"
#         }
#       ]
#       clusterResourceWhitelist = [{ group = "*", kind = "*" }]
#     }
#   }
#   lifecycle {
#     ignore_changes = all     # Don't fight Helm over spec differences
#     prevent_destroy = true   # Never delete this default project
#   }
# }

# Create the Argo CD Applications
# resource "kubernetes_manifest" "argocd_apps" {
#   for_each = local.apps
#
#   manifest = {
#     apiVersion = "argoproj.io/v1alpha1"
#     kind       = "Application"
#     metadata = {
#       name      = each.key
#       namespace = var.namespace
#     }
#     spec = {
#       project = "default"
#       source = {
#         repoURL        = local.repo_url
#         targetRevision = local.target_rev
#         path           = dirname(each.value)
#         directory = {
#           recurse = false
#         }
#       }
#       destination = {
#         server    = "https://kubernetes.default.svc"
#         namespace = "application" # adjust if your manifests use another namespace
#       }
#       syncPolicy = {
#         automated = {
#           prune    = true
#           selfHeal = true
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_namespace" "infra_tools" {
#   metadata {
#     name = "infra-tools"
#   }
#   lifecycle {
#     ignore_changes = all     # Don't fight Helm over spec differences
#     prevent_destroy = true   # Never delete this default project
#   }
# }