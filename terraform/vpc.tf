locals {
  vpc_id = "vpc-d93bfcb2"

  subnet_ids = [
    "subnet-bd40afd6", # us-east-2a
    "subnet-d27c58a8", # us-east-2b
    "subnet-5cbf3310"  # us-east-2c
  ]
}

resource "aws_vpc" "default" {
  assign_generated_ipv6_cidr_block = true
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.default.default_network_acl_id

  subnet_ids = local.subnet_ids

  // We see lots of connection attempts from this IP, and the TLS negotiation
  // almost always fails. This is expensive (it quadrupled our LB expenditure),
  // so we block it at the VPC so it never makes it to the LB.
  // The requests started around 2025-03-21 14:15 UTC, and we enabled this deny
  // around 2025-04-11 11:45 UTC
  ingress {
    action     = "deny"
    cidr_block = "109.169.15.54/32"
    from_port  = 0
    icmp_code  = 0
    icmp_type  = 0
    protocol   = "-1"
    rule_no    = 1
    to_port    = 0
  }

  ingress {
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    icmp_code  = 0
    icmp_type  = 0
    protocol   = "-1"
    rule_no    = 100
    to_port    = 0
  }

  ingress {
    action          = "allow"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = "::/0"
    protocol        = "-1"
    rule_no         = 101
    to_port         = 0
  }

  egress {
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    icmp_code  = 0
    icmp_type  = 0
    protocol   = "-1"
    rule_no    = 100
    to_port    = 0
  }

  egress {
    action          = "allow"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = "::/0"
    protocol        = "-1"
    rule_no         = 101
    to_port         = 0
  }
}
