data "aws_ssm_parameter" "ami_id" {
  name = "/clojars/production/ami_id"
}

locals {
  subnet_ids = [
    "subnet-bd40afd6", # us-east-2a
    "subnet-d27c58a8", # us-east-2b
    "subnet-5cbf3310"  # us-east-2c
  ]
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
