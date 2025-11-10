variable "aws_region" {
  description = "AWS region where the EKS cluster runs"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "namespace" {
  description = "Namespace to deploy Argo CD into"
  type        = string
  default     = "argocd"
}
