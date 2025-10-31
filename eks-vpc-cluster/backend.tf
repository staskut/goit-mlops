terraform {
 backend "s3" {
  bucket = "mlops-tfstate-stankutnyk"
  key  = "global/s3/terraform.tfstate"
  region = "eu-west-2"
  profile = "personal"
 }
}