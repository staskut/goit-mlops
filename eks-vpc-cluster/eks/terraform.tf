terraform {
  required_version = ">= 1.5.0"


  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}


provider "aws" {
  region = var.aws_region
  profile = "personal"


  default_tags {
    tags = {
      Project   = "mlops-course"
      ManagedBy = "terraform"
    }
  }
}
