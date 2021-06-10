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

locals {
  subnet_ids = [
    "subnet-bd40afd6", # us-east-2a
    "subnet-d27c58a8", # us-east-2b
    "subnet-5cbf3310"  # us-east-2c
  ]
}


# backend state setup

resource "aws_s3_bucket" "tf_state" {
  bucket = "clojars-tf-state"
  acl    = "private"

  versioning {
    enabled = true
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

# user for server acccess to s3

resource "aws_iam_user" "server_user" {
  name = "server-user"
}

resource "aws_iam_policy" "server_user_policy" {
  name        = "server-user-policy"
  description = "A policy for access from the EC2 server"

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

resource "aws_iam_user_policy_attachment" "server_user_policy_attach" {
  user       = aws_iam_user.server_user.name
  policy_arn = aws_iam_policy.server_user_policy.arn
}

# fastly logs bucket

resource "aws_s3_bucket" "fastly_logs_bucket" {
  bucket = "clojars-fastly-logs"
  acl    = "private"

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
  user       = aws_iam_user.fastly_logs.name
  policy_arn = aws_iam_policy.fastly_logs_policy.arn
}

# repo buckets

resource "aws_s3_bucket" "dev_repo_bucket" {
  bucket = "clojars-repo-development"
  acl    = "public-read"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket" "production_repo_bucket" {
  bucket = "clojars-repo-production"
  acl    = "public-read"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

# stats bucket

resource "aws_s3_bucket" "stats_bucket" {
  bucket = "clojars-stats-production"
  acl    = "public-read"

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
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.server_production.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.server_production.id]
  }
}

resource "aws_db_instance" "default" {
  allocated_storage       = 20
  backup_retention_period = 7
  engine                  = "postgres"
  identifier              = "clojars-production"
  instance_class          = "db.t3.micro"
  name                    = "clojars"
  password                = var.db_password
  publicly_accessible     = true
  storage_type            = "gp2"
  username                = var.db_username
  vpc_security_group_ids  = [aws_security_group.allow_postgres.id]
}

# bucket for storing artifact index

resource "aws_s3_bucket" "artifact_index_bucket" {
  bucket = "clojars-artifact-index"
  acl    = "private"
}

resource "aws_security_group" "server_production" {
  name        = "server_production"
  description = "Allow access to production server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO: make more restrictive
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_acm_certificate" "lb_tls_cert" {
  domain_name       = "clojars.org"
  validation_method = "DNS"

  subject_alternative_names = [
    "beta.clojars.org",
    "ipv6.clojars.org",
    "www.clojars.org",
    "releases.clojars.org"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

output "cert_validation_options" {
  value = aws_acm_certificate.lb_tls_cert.domain_validation_options
}

resource "aws_s3_bucket" "lb_logs_bucket" {
  bucket = "clojars-lb-logs"
  acl    = "private"

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

resource "aws_security_group" "lb_production" {
  name        = "lb_production"
  description = "Allow access to production load balancer"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb" "production" {
  name               = "production-lb"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "dualstack"

  security_groups = [aws_security_group.lb_production.id]

  subnets = local.subnet_ids

  enable_deletion_protection = true

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs_bucket.bucket
  #   prefix  = "production-lb"
  #   enabled = true
  # }
}

resource "aws_lb_target_group" "production" {
  name     = "production-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-d93bfcb2"
}

resource "aws_lb_listener" "production" {
  load_balancer_arn = aws_lb.production.arn
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.lb_tls_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.production.arn
  }
}

resource "aws_lb_listener" "production_redir_to_ssl" {
  load_balancer_arn = aws_lb.production.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# s3 bucket for deployments

resource "aws_s3_bucket" "deployments_bucket" {
  bucket = "clojars-deployment-artifacts"
  acl    = "private"
}

# asg

resource "aws_launch_configuration" "prod_launch_config" {
  name_prefix     = "prod-asg-"
  image_id        = "ami-04c1b1b8407fd4518"
  instance_type   = "t4g.medium"
  key_name        = "server"
  security_groups = [aws_security_group.server_production.id]

  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "prod_asg" {
  name = "prod-asg"

  min_size = 1

  # adjust these to 2 release a new AMI
  max_size         = 1
  desired_capacity = 1

  health_check_grace_period = "60"
  health_check_type         = "EC2"
  launch_configuration      = aws_launch_configuration.prod_launch_config.name
  vpc_zone_identifier       = local.subnet_ids
  target_group_arns         = [aws_lb_target_group.production.arn]
  termination_policies = [
    "OldestInstance",
    "Default",
  ]
}
