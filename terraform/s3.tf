# fastly logs bucket

resource "aws_s3_bucket" "fastly_logs_bucket" {
  bucket = "clojars-fastly-logs"
}

resource "aws_s3_bucket_acl" "fastly_logs_bucket" {
  bucket = aws_s3_bucket.fastly_logs_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "fastly_logs_bucket" {
  bucket = aws_s3_bucket.fastly_logs_bucket.id

  rule {
    id = "delete-old-logs"

    expiration {
      days = "14"
    }

    noncurrent_version_expiration {
      noncurrent_days = "14"
    }
    status = "Enabled"

    filter {
      prefix = ""
    }
  }
}


# repo buckets

resource "aws_s3_bucket" "dev_repo_bucket" {
  bucket = "clojars-repo-development"
}

resource "aws_s3_bucket_acl" "dev_repo_bucket" {
  bucket = aws_s3_bucket.dev_repo_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_cors_configuration" "dev_repo_bucket" {
  bucket = aws_s3_bucket.dev_repo_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket" "production_repo_bucket" {
  bucket = "clojars-repo-production"
}

resource "aws_s3_bucket_acl" "production_repo_bucket" {
  bucket = aws_s3_bucket.production_repo_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_cors_configuration" "production_repo_bucket" {
  bucket = aws_s3_bucket.production_repo_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

# stats bucket

resource "aws_s3_bucket" "stats_bucket" {
  bucket = "clojars-stats-production"
}

resource "aws_s3_bucket_acl" "stats_bucket" {
  bucket = aws_s3_bucket.stats_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_cors_configuration" "stats_bucket" {
  bucket = aws_s3_bucket.stats_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

# bucket for storing artifact index

resource "aws_s3_bucket" "artifact_index_bucket" {
  bucket = "clojars-artifact-index"
}

resource "aws_s3_bucket_acl" "artifact_index_bucket" {
  bucket = aws_s3_bucket.artifact_index_bucket.id
  acl    = "private"
}

# load balancer logs

resource "aws_s3_bucket" "lb_logs_bucket" {
  bucket = "clojars-lb-logs"
}

resource "aws_s3_bucket_acl" "lb_logs_bucket" {
  bucket = aws_s3_bucket.lb_logs_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "lb_logs_bucket" {
  bucket = aws_s3_bucket.lb_logs_bucket.id

  rule {
    id = "delete-old-logs"

    expiration {
      days = "14"
    }

    noncurrent_version_expiration {
      noncurrent_days = "14"
    }
    status = "Enabled"

    filter {
      prefix = ""
    }
  }
}

resource "aws_s3_bucket_policy" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs_bucket.id
  policy = data.aws_iam_policy_document.lb_logs.json
}

data "aws_iam_policy_document" "lb_logs" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.lb.arn]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.lb_logs_bucket.arn}/*"]
  }
}

data "aws_elb_service_account" "lb" {}

# s3 bucket for deployments

resource "aws_s3_bucket" "deployments_bucket" {
  bucket = "clojars-deployment-artifacts"
}

resource "aws_s3_bucket_acl" "deployments_bucket" {
  bucket = aws_s3_bucket.deployments_bucket.id
  acl    = "private"
}
