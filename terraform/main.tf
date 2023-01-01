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

# user for server acccess to s3

# TODO: remove this once we switch to using instance attached policies
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

# RDS

data "aws_ssm_parameter" "db_password" {
  name = "/clojars/production/db_password"
}

data "aws_ssm_parameter" "db_username" {
  name = "/clojars/production/db_user"
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
  allocated_storage            = 20
  backup_retention_period      = 7
  engine                       = "postgres"
  identifier                   = "clojars-production"
  instance_class               = "db.t3.small"
  db_name                      = "clojars"
  password                     = data.aws_ssm_parameter.db_password.value
  publicly_accessible          = true
  performance_insights_enabled = true
  storage_type                 = "gp2"
  username                     = data.aws_ssm_parameter.db_username.value
  vpc_security_group_ids       = [aws_security_group.allow_postgres.id]
}

# bucket for storing artifact index

resource "aws_s3_bucket" "artifact_index_bucket" {
  bucket = "clojars-artifact-index"
}

resource "aws_s3_bucket_acl" "artifact_index_bucket" {
  bucket = aws_s3_bucket.artifact_index_bucket.id
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
    "releases.clojars.org",
    "clojars.net"
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

resource "aws_lb_listener_rule" "net_to_org" {
  listener_arn = aws_lb_listener.production.arn

  action {
    type = "redirect"

    redirect {
      host        = "clojars.org"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = ["clojars.net"]
    }
  }
}

# s3 bucket for deployments

resource "aws_s3_bucket" "deployments_bucket" {
  bucket = "clojars-deployment-artifacts"
}

resource "aws_s3_bucket_acl" "deployments_bucket" {
  bucket = aws_s3_bucket.deployments_bucket.id
  acl    = "private"
}

# asg

data "aws_ssm_parameter" "ami_id" {
  name = "/clojars/production/ami_id"
}

resource "aws_iam_policy" "s3_read_write" {
  name = "S3ReadWrite"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "ssm_parameter_read" {
  name = "SSMParameterRead"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "prod_server_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "prod_server_role_s3_access" {
  role       = aws_iam_role.prod_server_role.name
  policy_arn = aws_iam_policy.s3_read_write.arn
}

resource "aws_iam_role_policy_attachment" "prod_server_role_ssm_paramater_access" {
  role       = aws_iam_role.prod_server_role.name
  policy_arn = aws_iam_policy.ssm_parameter_read.arn
}

resource "aws_iam_instance_profile" "prod_server_profile" {
  role = aws_iam_role.prod_server_role.name
}

resource "aws_launch_template" "prod_launch_template" {
  name_prefix     = "prod-asg-"
  # Release a new AMI with ../scripts/cycle-instance.sh after applying
  image_id        = nonsensitive(data.aws_ssm_parameter.ami_id.value)
  instance_type   = "t4g.medium"
  key_name        = "server-2022"

  iam_instance_profile {
    arn = aws_iam_instance_profile.prod_server_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.server_production.id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 30
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "prod_asg" {
  name = "prod-asg"

  min_size = 1

  max_size         = 1
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.prod_launch_template.id
    version = "$Latest"
  }

  health_check_grace_period = "60"
  health_check_type         = "EC2"
  vpc_zone_identifier       = local.subnet_ids
  target_group_arns         = [aws_lb_target_group.production.arn]
  termination_policies = [
    "OldestInstance",
    "Default",
  ]
}
