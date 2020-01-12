provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "stats_bucket" {
  bucket = "clojars-stats-production"
  acl = "public-read"
}
