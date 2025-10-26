resource "aws_s3_bucket" "tf_state" {
  bucket = var.bucket_name
  tags = {
    Name = "tfstate-bucket"
    Environment = "dev"
  }
}
resource "aws_s3_bucket_public_access_block" "tf_state_block" {
  bucket = aws_s3_bucket.tf_state.id


  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id


  versioning_configuration {
    status = "Suspended"
  }
}

provider "aws" {
  region = "eu-west-2"
  profile = "personal"
}