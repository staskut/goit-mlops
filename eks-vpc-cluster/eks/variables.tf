variable "cluster_name" {
  type        = string
  default     = "goit-cluster"
  description = "EKS cluster name"
}

variable "cluster_version" {
  type        = string
  default     = "1.31"
  description = "EKS cluster version"
}

variable "aws_region" {
  type        = string
  default     = "eu-west-2"
  description = "AWS region"
}