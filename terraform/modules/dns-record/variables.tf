variable "zone" {
  description = "Zone the record belongs to. zone_name is used as both the DNSimple zone_name and the suffix for the Route 53 FQDN; route53_zone_id is the matching Route 53 hosted zone."
  type = object({
    zone_name       = string
    route53_zone_id = string
  })
}

variable "name" {
  description = "Record name (subdomain). Use \"\" for the apex."
  type        = string
  default     = ""
}

variable "type" {
  description = "DNS record type. Supported: A, AAAA, CNAME, MX, TXT, CAA, ALIAS."
  type        = string

  validation {
    condition     = contains(["A", "AAAA", "CNAME", "MX", "TXT", "CAA", "ALIAS"], var.type)
    error_message = "type must be one of A, AAAA, CNAME, MX, TXT, CAA, ALIAS."
  }
}

variable "ttl" {
  description = "TTL in seconds. Applies to both providers."
  type        = number
}

variable "records" {
  description = "Record values. For MX, each entry is \"<priority> <hostname>\". Unused when type=ALIAS."
  type        = list(string)
  default     = []
}

variable "alias_value" {
  description = "DNSimple ALIAS target hostname. Required when type=ALIAS, ignored otherwise."
  type        = string
  default     = null
}

variable "route53_alias" {
  description = "Route 53 alias target. Required when type=ALIAS, ignored otherwise. The module always creates both A and AAAA aliases; Route 53 no-ops AAAA for IPv4-only targets."
  type = object({
    name    = string
    zone_id = string
  })
  default = null
}
