# terraform {
#   backend "s3" {
#     bucket         = "mlops-tfstate-stankutnyk"
#     key            = "eks/terraform.tfstate"
#     region         = "eu-west-2"
#     encrypt        = true
#     profile        = "personal" ## ваша  назва профілю
#   }
# }

# data "terraform_remote_state" "vpc" {
#   backend = "s3"
#   config = {
#     bucket  = "mlops-tfstate-stankutnyk"
#     key     = "vpc/terraform.tfstate"
#     region  = "eu-west-2"
#     profile = "personal" ## ваша назва профілю
#   }
# }

