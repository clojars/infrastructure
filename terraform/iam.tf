# user for server access to s3

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

resource "aws_iam_policy" "s3_read_write" {
  name = "S3ReadWrite"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
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
        Action = [
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "sqs_read_write" {
  name = "SQSReadWrite"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "cw_agent" {
  name = "CWAgent"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeTags",
          "logs:PutLogEvents"
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

resource "aws_iam_role_policy_attachment" "prod_server_role_ssm_parameter_access" {
  role       = aws_iam_role.prod_server_role.name
  policy_arn = aws_iam_policy.ssm_parameter_read.arn
}

resource "aws_iam_role_policy_attachment" "prod_server_role_sqs_access" {
  role       = aws_iam_role.prod_server_role.name
  policy_arn = aws_iam_policy.sqs_read_write.arn
}

resource "aws_iam_role_policy_attachment" "prod_server_role_cw_agent_access" {
  role       = aws_iam_role.prod_server_role.name
  policy_arn = aws_iam_policy.cw_agent.arn
}

# Group for Clojars maintainers (humans). Members are managed outside Terraform.

data "aws_caller_identity" "current" {}

resource "aws_iam_group" "clojars_devs" {
  name = "ClojarsDevs"
}

resource "aws_iam_policy" "clojars_devs" {
  name        = "ClojarsDevs"
  description = "Day-to-day permissions for Clojars maintainers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CoreServices"
        Effect = "Allow"
        Action = [
          "acm:*",
          "autoscaling:*",
          "backup:*",
          "cloudwatch:*",
          "dynamodb:*",
          "ec2:*",
          "elasticloadbalancing:*",
          "iam:*",
          "logs:*",
          "rds:*",
          "route53:*",
          "s3:*",
          "ses:*",
          "sns:*",
          "sqs:*",
        ]
        Resource = "*"
      },
      {
        Sid    = "SsmParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:PutParameter",
        ]
        Resource = "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/*"
      },
      {
        Sid      = "SsmDescribe"
        Effect   = "Allow"
        Action   = "ssm:DescribeParameters"
        Resource = "*"
      },
      {
        Sid    = "Billing"
        Effect = "Allow"
        Action = [
          "account:*",
          "aws-portal:*",
          "bcm-data-exports:*",
          "bcm-pricing-calculator:*",
          "bcm-recommended-actions:*",
          "billing:*",
          "budgets:*",
          "ce:*",
          "consolidatedbilling:*",
          "cost-optimization-hub:*",
          "cur:*",
          "freetier:*",
          "invoicing:*",
          "notifications:*",
          "payments:*",
          "purchase-orders:*",
          "tax:*",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_group_policy_attachment" "clojars_devs" {
  group      = aws_iam_group.clojars_devs.name
  policy_arn = aws_iam_policy.clojars_devs.arn
}

resource "aws_iam_group_policy_attachments_exclusive" "clojars_devs" {
  group_name  = aws_iam_group.clojars_devs.name
  policy_arns = [aws_iam_policy.clojars_devs.arn]
}

resource "aws_iam_group_policies_exclusive" "clojars_devs" {
  group_name   = aws_iam_group.clojars_devs.name
  policy_names = []
}
