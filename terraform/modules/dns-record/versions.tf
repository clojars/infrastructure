terraform {
  required_version = ">= 1.12.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    dnsimple = {
      source  = "dnsimple/dnsimple"
      version = "~> 1.7"
    }
  }
}
