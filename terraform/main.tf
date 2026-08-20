provider "aws" {
  region = "us-east-2"
}

# Auth via env vars: DNSIMPLE_TOKEN (API v2 user token) and DNSIMPLE_ACCOUNT.
provider "dnsimple" {
}

terraform {
  backend "s3" {
    bucket       = "clojars-tf-state"
    region       = "us-east-2"
    key          = "clojars-prod/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
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

