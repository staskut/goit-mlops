output "cluster_arn" {
  value       = module.eks.cluster_arn
  description = "The Amazon Resource Name (ARN) of the cluster"
}


output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "The endpoint for your EKS Kubernetes API."
}


output "cluster_name" {
  value       = module.eks.cluster_name
  description = "The name of the EKS cluster"
}
