terraform {
 backend "s3" {
   bucket  = "mlops-tfstate-stankutnyk"
   key     = "vpc/terraform.tfstate"
   region  = "eu-west-2"
   profile = "personal"
 }
}