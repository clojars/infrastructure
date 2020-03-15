provider "aws" {
  region = "us-east-2"
}

# user for rackspace server

resource "aws_iam_user" "rackspace_server" {
  name = "rackspace-server"
}

resource "aws_iam_policy" "rackspace_policy" {
  name        = "rackspace-policy"
  description = "A policy for access from the Rackspace server"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "rackspace_policy_attach" {
  user = aws_iam_user.rackspace_server.name
  policy_arn = aws_iam_policy.rackspace_policy.arn
}

# fastly logs bucket

resource "aws_s3_bucket" "fastly_logs_bucket" {
  bucket = "clojars-fastly-logs"
  acl = "private"

  lifecycle_rule {
    id      = "delete-old-logs"
    enabled = true

    expiration {
      days = "14"
    }

    noncurrent_version_expiration {
      days = "14"
    }
  }
}

# fastly logs user

resource "aws_iam_user" "fastly_logs" {
  name = "fastly-logs"
}

resource "aws_iam_policy" "fastly_logs_policy" {
  name        = "fastly-logs-policy"
  description = "A policy for Fastly to write access logs"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "${aws_s3_bucket.fastly_logs_bucket.arn}",
                "${aws_s3_bucket.fastly_logs_bucket.arn}/*"
            ]
        },
        {
            "Effect": "Deny",
            "NotAction": "s3:*",
            "NotResource": [
                "${aws_s3_bucket.fastly_logs_bucket.arn}",
                "${aws_s3_bucket.fastly_logs_bucket.arn}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "fastly_logging_policy_attach" {
  user = aws_iam_user.fastly_logs.name
  policy_arn = aws_iam_policy.fastly_logs_policy.arn
}

# repo buckets

resource "aws_s3_bucket" "dev_repo_bucket" {
  bucket = "clojars-repo-development"
  acl = "public-read"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket" "production_repo_bucket" {
  bucket = "clojars-repo-production"
  acl = "public-read"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

# stats bucket

resource "aws_s3_bucket" "stats_bucket" {
  bucket = "clojars-stats-production"
  acl = "public-read"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

# RDS

variable "db_password" {
  type = string
}

variable "db_username" {
  type = string
}

resource "aws_security_group" "allow_postgres" {
  name        = "allow_postgres"
  description = "Allow access tp postgres server" # typo, but can't be changed w/o recreating RDS resource!

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [
      "23.253.149.7/32", # clojars.org on rackspace
      "172.31.41.209/32", # server.clojars.org on ec2, private IP. Need to use the value from beta.tf!
      "24.178.169.9/32"
    ] 
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "default" {
  allocated_storage = 20
  backup_retention_period = 7
  engine = "postgres"
  engine_version = "11.6"
  identifier = "clojars-production"
  instance_class = "db.t3.micro"
  name = "clojars"
  password = var.db_password
  publicly_accessible = true
  storage_type = "gp2"
  username = var.db_username
  vpc_security_group_ids = [aws_security_group.allow_postgres.id]
}

# bucket for storing artifact index

resource "aws_s3_bucket" "artifact_index_bucket" {
  bucket = "clojars-artifact-index"
  acl = "private"
}
