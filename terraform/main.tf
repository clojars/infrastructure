provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket         = "clojars-tf-state"
    region         = "us-east-2"
    key            = "clojars-prod/terraform.tfstate"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

# backend state setup

resource "aws_s3_bucket" "tf_state" {
  bucket = "clojars-tf-state"
}

resource "aws_s3_bucket_acl" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "tf_state_lock" {
  name           = "terraform-state-lock"
  hash_key       = "LockID"
  read_capacity  = 2
  write_capacity = 2

  attribute {
    name = "LockID"
    type = "S"
  }
}
