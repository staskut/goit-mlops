output "argocd_helm_release" {
  description = "Argo CD Helm release name"
  value       = helm_release.argocd.name
}

output "argocd_namespace" {
  description = "Namespace where Argo CD is installed"
  value       = helm_release.argocd.namespace
}

data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = helm_release.argocd.namespace
  }
}

output "argocd_server_hostname" {
  description = "External hostname (LoadBalancer) of the Argo CD server"
  value       = data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname
}
