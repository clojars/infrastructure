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

  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
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
