terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.45.0"
    }
    dnsimple = {
      source  = "dnsimple/dnsimple"
      version = "~> 1.7"
    }
  }
  required_version = ">= 1.12.0"
}
