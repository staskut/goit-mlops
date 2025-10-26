variable "aws_region" {
  default     = "eu-west-2"
  description = "London Region"
}

variable "bucket_name" {
  description = "Name of the S3 bucket to store Terraform state"
  type        = string
  default     = "mlops-tfstate-stankutnyk"
}