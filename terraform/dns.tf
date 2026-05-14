locals {
  clojars_zone     = "clojars.org"
  clojars_net_zone = "clojars.net"
}

# === Route 53 hosted zones ===
#
# These are authoritative copies that run in parallel with DNSimple.

resource "aws_route53_zone" "clojars_org" {
  name = local.clojars_zone
}

resource "aws_route53_zone" "clojars_net" {
  name = local.clojars_net_zone
}

output "route53_clojars_org_nameservers" {
  value       = aws_route53_zone.clojars_org.name_servers
  description = "Add these to the clojars.org NS records at the registrar (alongside DNSimple's)."
}

output "route53_clojars_net_nameservers" {
  value       = aws_route53_zone.clojars_net.name_servers
  description = "Add these to the clojars.net NS records at the registrar (alongside DNSimple's)."
}

# === Apex NS records ===
#
# Multi-provider DNS: the in-zone NS RRset on each authoritative server should
# match the registrar's delegation, otherwise resolvers that cache the in-zone
# answer (per RFC 2181 §5.4.1) only learn one provider's servers and the
# redundancy is defeated. Registrar delegation is 4 DNSimple + 4 Route 53.
#
# We can only set the Route 53 side from Terraform today. DNSimple has an API
# and UI for editing the zone-side NS RRset
# (PUT /v2/{account}/zones/{zone}/ns_records), but the Terraform provider
# doesn't expose it yet — tracking in
# https://github.com/dnsimple/terraform-provider-dnsimple/issues/356. Once
# that ships, mirror the same RRset on the DNSimple side.

locals {
  dnsimple_apex_ns = [
    "ns1.dnsimple.com",
    "ns2.dnsimple.com",
    "ns3.dnsimple.com",
    "ns4.dnsimple.com",
  ]

  clojars_net_apex_ns = concat(
    local.dnsimple_apex_ns,
    aws_route53_zone.clojars_net.name_servers,
  )
}

resource "aws_route53_record" "net_apex_ns" {
  zone_id         = aws_route53_zone.clojars_net.zone_id
  name            = local.clojars_net_zone
  type            = "NS"
  ttl             = 3600
  records         = local.clojars_net_apex_ns
  allow_overwrite = true
}

# clojars.org — ready but not applied yet. Uncomment after clojars.net is
# verified healthy.
#
# locals {
#   clojars_org_apex_ns = concat(
#     local.dnsimple_apex_ns,
#     aws_route53_zone.clojars_org.name_servers,
#   )
# }
#
# resource "aws_route53_record" "org_apex_ns" {
#   zone_id         = aws_route53_zone.clojars_org.zone_id
#   name            = local.clojars_zone
#   type            = "NS"
#   ttl             = 3600
#   records         = local.clojars_org_apex_ns
#   allow_overwrite = true
# }

# === Registrar (Route 53 Domains) ===
#
# Planned migration: transfer the domain registrations from the current
# registrar to Route 53 Domains. After the transfer, `aws_route53domains_registered_domain`
# adopts the existing registration so we can manage the delegation NS list and
# contact info from Terraform.
#
# Commented out until the transfer completes. After transfer:
#   1. `terraform import aws_route53domains_registered_domain.clojars_net clojars.net`
#   2. uncomment, run `terraform plan` to inspect contact / privacy / lock drift
#      (the resource adopts whatever's currently set; null fields here mean
#      "leave as-is" but explicit contact blocks may be needed to avoid diffs)
#   3. apply.
#
# resource "aws_route53domains_registered_domain" "clojars_net" {
#   domain_name = local.clojars_net_zone
#
#   dynamic "name_server" {
#     for_each = concat(local.dnsimple_apex_ns, aws_route53_zone.clojars_net.name_servers)
#     content {
#       name = name_server.value
#     }
#   }
# }
#
# resource "aws_route53domains_registered_domain" "clojars_org" {
#   domain_name = local.clojars_zone
#
#   dynamic "name_server" {
#     for_each = concat(local.dnsimple_apex_ns, aws_route53_zone.clojars_org.name_servers)
#     content {
#       name = name_server.value
#     }
#   }
# }

locals {
  zones = {
    org = {
      zone_name       = local.clojars_zone
      route53_zone_id = aws_route53_zone.clojars_org.zone_id
    }
    net = {
      zone_name       = local.clojars_net_zone
      route53_zone_id = aws_route53_zone.clojars_net.zone_id
    }
  }
}

# === clojars.org apex ===

module "apex_alias" {
  source      = "./modules/dns-record"
  zone        = local.zones.org
  name        = ""
  type        = "ALIAS"
  ttl         = 60
  alias_value = aws_lb.production.dns_name
  route53_alias = {
    name    = aws_lb.production.dns_name
    zone_id = aws_lb.production.zone_id
  }
}

module "apex_caa" {
  source = "./modules/dns-record"
  zone   = local.zones.org
  name   = ""
  type   = "CAA"
  ttl    = 3600
  records = [
    "0 issue \"globalsign.com\"",
    "0 issue \"amazontrust.com\"",
  ]
}

module "apex_mx" {
  source = "./modules/dns-record"
  zone   = local.zones.org
  name   = ""
  type   = "MX"
  ttl    = 3600
  records = [
    "10 in1-smtp.messagingengine.com",
    "20 in2-smtp.messagingengine.com",
  ]
}

module "apex_txt" {
  source = "./modules/dns-record"
  zone   = local.zones.org
  name   = ""
  type   = "TXT"
  ttl    = 3600
  records = [
    "\"v=spf1 include:spf.messagingengine.com ?all\"",
    "\"google-site-verification=MSWyd9aXDSNxqsPw0hYm31PtA1CbyI6no5rFgWp-xU8\"",
    "\"google-site-verification=06t-8Lwrht4Wqm7jJb_bQAGa3kosiPV5SCA4kaL_Skc\"",
    "\"globalsign-domain-verification=S5sT68OBACJ_9CvrzRsz8-5yhYGkz7zbctTR8vnC7B\"",
    "\"r7l5p912zc3mng677pmxq93bfhg5h9jf\"",
  ]
}

# DNSimple auto-exposes the ALIAS target via a TXT record at the apex. Route 53
# has no equivalent need, so this stays DNSimple-only.
resource "dnsimple_zone_record" "txt_alias_marker" {
  zone_name = local.clojars_zone
  name      = ""
  type      = "TXT"
  value     = "\"ALIAS for ${aws_lb.production.dns_name}\""
  ttl       = 60
}

# === clojars.org TXT subdomain records ===

module "dmarc" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "_dmarc"
  type    = "TXT"
  ttl     = 3600
  records = ["\"v=DMARC1;p=quarantine;pct=100;fo=1\""]
}

module "amazonses" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "_amazonses"
  type    = "TXT"
  ttl     = 3600
  records = ["\"KYpdKsjtuTf/2YmS37eoPObZZHl0I3iFQsAwli0fAUU=\""]
}

module "dkim_2016_12" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "2016-12._domainkey"
  type    = "TXT"
  ttl     = 3600
  records = ["\"v=DKIM1; k=rsa; t=y; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDNrqUgWt07sEDQ6+xRCgrMuv+p+VJ+esWqLEGpERQwJOkUrusqftFPEi82LAdXwBK3W10+AqH4ciSlcArEyh7/kmDyHbJLclFMzy574JVTp5cD3skx1Xk1afZ77CtvSvHehzkzGwvQ995CZCeu5LRi8w4aYVxgw47TGJIWgR/jCQIDAQAB\""]
}

# === clojars.org CNAME subdomains ===

module "beta" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "beta"
  type    = "CNAME"
  ttl     = 3600
  records = ["clojars.org"]
}

module "www" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "www"
  type    = "CNAME"
  ttl     = 3600
  records = ["clojars.org"]
}

module "releases" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "releases"
  type    = "CNAME"
  ttl     = 3600
  records = ["clojars.org"]
}

module "repo" {
  source = "./modules/dns-record"
  zone   = local.zones.org
  name   = "repo"
  type   = "CNAME"
  # TODO: set this back to 3600 after 2026-05-21
  ttl = 60
  # https://www.fastly.com/documentation/guides/full-site-delivery/domains-and-origins/enabling-dualstack-connections/
  records = ["dualstack.v.ssl.global.fastly.net"]
}

module "status" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "status"
  type    = "CNAME"
  ttl     = 3600
  records = ["plmhhdckmdbg.stspg-customer.com"]
}

module "autodiscover" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "autodiscover"
  type    = "CNAME"
  ttl     = 3600
  records = ["autodiscover.mail.us-east-1.awsapps.com"]
}

# === DKIM CNAMEs ===

module "ses_dkim_1" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "62jozinbglmo43m6d7ocujpqn4eyj35h._domainkey"
  type    = "CNAME"
  ttl     = 3600
  records = ["62jozinbglmo43m6d7ocujpqn4eyj35h.dkim.amazonses.com"]
}

module "ses_dkim_2" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "ili6d4enpump7gnt5rj6vp4ux4z4gbs5._domainkey"
  type    = "CNAME"
  ttl     = 3600
  records = ["ili6d4enpump7gnt5rj6vp4ux4z4gbs5.dkim.amazonses.com"]
}

module "ses_dkim_3" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "vth5ke2g6owrcjdzgmwdbkmuuvvz7xy7._domainkey"
  type    = "CNAME"
  ttl     = 3600
  records = ["vth5ke2g6owrcjdzgmwdbkmuuvvz7xy7.dkim.amazonses.com"]
}

module "fastmail_dkim_1" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "fm1._domainkey"
  type    = "CNAME"
  ttl     = 3600
  records = ["fm1.clojars.org.dkim.fmhosted.com"]
}

module "fastmail_dkim_2" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "fm2._domainkey"
  type    = "CNAME"
  ttl     = 3600
  records = ["fm2.clojars.org.dkim.fmhosted.com"]
}

module "fastmail_dkim_3" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "fm3._domainkey"
  type    = "CNAME"
  ttl     = 3600
  records = ["fm3.clojars.org.dkim.fmhosted.com"]
}

# === ACM / ACME validation CNAMEs ===

module "acm_validation_apex" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "_8591ab357e5b4ff17f1576374fb73b44"
  type    = "CNAME"
  ttl     = 3600
  records = ["_da96d03de38f8758b5814a0b355a6e60.vhzmpjdqfx.acm-validations.aws"]
}

module "acm_validation_beta" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "_003cf66ffcf811853457cf49f2a288af.beta"
  type    = "CNAME"
  ttl     = 3600
  records = ["_ee133730df2b7654fd7334c723addd45.vhzmpjdqfx.acm-validations.aws"]
}

module "acm_validation_www" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "_c742dda811367a720a800ee6a9a8c63d.www"
  type    = "CNAME"
  ttl     = 3600
  records = ["_91a83539bc008cddcf55e3893d178bbc.nhqijqilxf.acm-validations.aws"]
}

module "acm_validation_releases" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "_ebbf677705e732757ea321a5c3c61161.releases"
  type    = "CNAME"
  ttl     = 3600
  records = ["_1497b68f163aef2168988a93d94b17cf.nhqijqilxf.acm-validations.aws"]
}

module "acm_validation_ipv6" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "_32e673b4a5acfe493ca980106433e6c7.ipv6"
  type    = "CNAME"
  ttl     = 3600
  records = ["_26a651b47ef242ec022b6a6faedcfaa7.nhqijqilxf.acm-validations.aws"]
}

module "acme_challenge_repo" {
  source  = "./modules/dns-record"
  zone    = local.zones.org
  name    = "_acme-challenge.repo"
  type    = "CNAME"
  ttl     = 3600
  records = ["i9g00r84wza2uk6m89.fastly-validations.com"]
}

# === clojars.net (redirect domain) ===

# DNSimple aliases the apex to "clojars.org" (chained ALIAS). Route 53 can't
# ALIAS to an arbitrary external hostname, so it aliases straight to the ELB —
# functionally the same: the request hits the LB, which 301s to clojars.org.
module "net_apex_alias" {
  source      = "./modules/dns-record"
  zone        = local.zones.net
  name        = ""
  type        = "ALIAS"
  ttl         = 3600
  alias_value = local.clojars_zone
  route53_alias = {
    name    = aws_lb.production.dns_name
    zone_id = aws_lb.production.zone_id
  }
}

module "net_caa" {
  source  = "./modules/dns-record"
  zone    = local.zones.net
  name    = ""
  type    = "CAA"
  ttl     = 60
  records = ["0 issue \"amazontrust.com\""]
}

# DNSimple-only marker, see notes on txt_alias_marker above.
resource "dnsimple_zone_record" "net_txt_alias_marker" {
  zone_name = local.clojars_net_zone
  name      = ""
  type      = "TXT"
  value     = "\"ALIAS for ${local.clojars_zone}\""
  ttl       = 3600
}

module "net_acm_validation_apex" {
  source  = "./modules/dns-record"
  zone    = local.zones.net
  name    = "_b5fd724715ee01971b191589c45cfced"
  type    = "CNAME"
  ttl     = 60
  records = ["_6d0cfe59bc20b6bb38891a4d691c4792.qvwhjqbvbg.acm-validations.aws"]
}
