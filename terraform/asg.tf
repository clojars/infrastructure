locals {
  subnet_ids = [
    "subnet-bd40afd6", # us-east-2a
    "subnet-d27c58a8", # us-east-2b
    "subnet-5cbf3310"  # us-east-2c
  ]

  disk_usage_alarm_threshold = 80
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

resource "aws_iam_instance_profile" "prod_server_profile" {
  role = aws_iam_role.prod_server_role.name
}

resource "aws_launch_template" "prod_launch_template" {
  name_prefix     = "prod-asg-"
  # The AMI build process writes the AMI id to a SSM parameter. The next
  # instance created will use the new AMI based on this resolve directive. You
  # can trigger this with ../scripts/cycle-instance.sh
  image_id        = "resolve:ssm:/clojars/production/ami_id"
  # 8.0 GiB / 2 vCPUs / Up to 12.5 Gigabit / $0.0898 hourly
  instance_type   = "m6g.large"
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

  metadata_options {
    # cognitect's aws.api only supports IMDSv1 for getting instance credentials,
    # but IMDSv1 is disabled by default on AL2023 in favor for IMDSv2. This allows
    # IMDSv1 to be used.
    http_tokens = "optional"

    # A TF bug requires us to set this as well for the above option to be
    # applied. See
    # https://github.com/hashicorp/terraform-provider-aws/issues/25909#issuecomment-1218625304
    http_endpoint = "enabled"
  }

  lifecycle {
    create_before_destroy = true
  }

  monitoring {
    enabled = true
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

resource "aws_cloudwatch_metric_alarm" "disk_usage_alarm" {
  alarm_name        = "${aws_autoscaling_group.prod_asg.name} root disk usage too high"
  alarm_description = "The root volume of ${aws_autoscaling_group.prod_asg.name} is > ${local.disk_usage_alarm_threshold}%"

  metric_name = "disk_used_percent"
  namespace   = "CWAgent"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.prod_asg.name
    path                 = "/"
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Maximum"
  threshold           = local.disk_usage_alarm_threshold

  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  period              = "60"
  treat_missing_data  = "ignore"

  actions_enabled = "true"
  alarm_actions   = [aws_sns_topic.alarm_topic.arn]
  ok_actions      = [aws_sns_topic.alarm_topic.arn]
}
