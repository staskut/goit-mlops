data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "mlops-tfstate-stankutnyk"
    key    = "vpc/terraform.tfstate"
    region = "eu-west-2"
  }
}