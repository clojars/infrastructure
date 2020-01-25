provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "stats_bucket" {
  bucket = "clojars-stats-production"
  acl = "public-read"
}

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
