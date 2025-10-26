terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

module "vpc" {
  source = "./vpc"

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidr   = "10.0.1.0/24"
  private_subnet_cidr  = "10.0.2.0/24"
  public_subnet_cidr_2 = "10.0.3.0/24"
  private_subnet_cidr_2= "10.0.4.0/24"

  availability_zone    = "eu-west-2a"
  availability_zone_2  = "eu-west-2b"
}

module "eks" {
  source = "./eks"

  cluster_name    = "goit-cluster"
  cluster_version = "1.31"
}