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

# maven index bucket

resource "aws_s3_bucket" "production_maven_index_bucket" {
  bucket = "clojars-maven-index-production"
}

resource "aws_s3_bucket_acl" "production_maven_index_bucket" {
  bucket = aws_s3_bucket.production_maven_index_bucket.id
  acl    = "public-read"
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

resource "aws_s3_bucket_versioning" "production_repo_bucket" {
  bucket = aws_s3_bucket.production_repo_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
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

resource "aws_iam_role" "repo_backup" {
  name = "repo-backup-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "backup.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.repo_backup.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
}

resource "aws_backup_vault" "repo_backup_vault" {
  name = "repo-backup-vault"
}

resource "aws_backup_plan" "repo_backup_plan" {
  name = "repo-backup-plan"

  rule {
    rule_name                = "continuous-backup"
    target_vault_name        = aws_backup_vault.repo_backup_vault.name
    enable_continuous_backup = true
    schedule                 = "cron(0 5 ? * * *)"
    start_window             = 60
    completion_window        = 180

    lifecycle {
      delete_after = 35
    }
  }
}

resource "aws_backup_selection" "repo_bucket" {
  name         = "repo-bucket-selection"
  plan_id      = aws_backup_plan.repo_backup_plan.id
  iam_role_arn = aws_iam_role.repo_backup.arn
  resources    = [aws_s3_bucket.production_repo_bucket.arn]
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
