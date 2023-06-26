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

resource "aws_iam_role_policy_attachment" "prod_server_role_sqs_access" {
  role       = aws_iam_role.prod_server_role.name
  policy_arn = aws_iam_policy.sqs_read_write.arn
}
