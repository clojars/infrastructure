locals {
  instance_count = 1
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


  # TODO: remove this once things are working
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "production_instance" {
  count = local.instance_count
  ami = "ami-0e38b48473ea57778"
  associate_public_ip_address = true
  instance_type = "t3a.medium"
  key_name = "server"
  vpc_security_group_ids = [aws_security_group.server_production.id]

  root_block_device {
    volume_size = 80
  }
}


resource "aws_acm_certificate" "lb_tls_cert" {
  domain_name       = "clojars.org"
  validation_method = "DNS"

  subject_alternative_names = ["beta.clojars.org"]
  
  lifecycle {
    create_before_destroy = true
  }
}

output "cert_validation_options" {
  value = aws_acm_certificate.lb_tls_cert.domain_validation_options
}

resource "aws_s3_bucket" "lb_logs_bucket" {
  bucket = "clojars-lb-logs"
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

resource "aws_security_group" "lb_production" {
  name        = "lb_production"
  description = "Allow access to production load balancer"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "production" {
  name               = "production-lb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.lb_production.id]
  
  subnets = [
    "subnet-bd40afd6", # us-east-2a
    "subnet-d27c58a8", # us-east-2b
    "subnet-5cbf3310"  # us-east-2c
  ]
    
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
  target_type = "instance"
  vpc_id = "vpc-d93bfcb2"
}

resource "aws_lb_target_group_attachment" "production_instance" {
  count            = local.instance_count
  target_group_arn = aws_lb_target_group.production.arn
  target_id        = aws_instance.production_instance[count.index].id
  port             = 80
}

resource "aws_lb_listener" "production" {
  load_balancer_arn = aws_lb.production.arn
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.lb_tls_cert.arn

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
