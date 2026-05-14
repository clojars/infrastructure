locals {
  clojars_zone     = "clojars.org"
  clojars_net_zone = "clojars.net"
}

# === Apex ===

resource "dnsimple_zone_record" "apex_alias" {
  zone_name = local.clojars_zone
  name      = ""
  type      = "ALIAS"
  value     = "production-lb-133941966.us-east-2.elb.amazonaws.com"
  ttl       = 60
}

resource "dnsimple_zone_record" "caa_globalsign" {
  zone_name = local.clojars_zone
  name      = ""
  type      = "CAA"
  value     = "0 issue \"globalsign.com\""
  ttl       = 3600
}

resource "dnsimple_zone_record" "caa_amazontrust" {
  zone_name = local.clojars_zone
  name      = ""
  type      = "CAA"
  value     = "0 issue \"amazontrust.com\""
  ttl       = 60
}

resource "dnsimple_zone_record" "mx_primary" {
  zone_name = local.clojars_zone
  name      = ""
  type      = "MX"
  value     = "in1-smtp.messagingengine.com"
  ttl       = 3600
  priority  = 10
}

resource "dnsimple_zone_record" "mx_secondary" {
  zone_name = local.clojars_zone
  name      = ""
  type      = "MX"
  value     = "in2-smtp.messagingengine.com"
  ttl       = 3600
  priority  = 20
}

# === Apex TXT ===

resource "dnsimple_zone_record" "txt_spf" {
  zone_name = local.clojars_zone
  name      = ""
  type      = "TXT"
  value     = "\"v=spf1 include:spf.messagingengine.com ?all\""
  ttl       = 3600
}

resource "dnsimple_zone_record" "txt_dmarc" {
  zone_name = local.clojars_zone
  name      = "_dmarc"
  type      = "TXT"
  value     = "\"v=DMARC1;p=quarantine;pct=100;fo=1\""
  ttl       = 3600
}

resource "dnsimple_zone_record" "txt_amazonses" {
  zone_name = local.clojars_zone
  name      = "_amazonses"
  type      = "TXT"
  value     = "\"KYpdKsjtuTf/2YmS37eoPObZZHl0I3iFQsAwli0fAUU=\""
  ttl       = 3600
}

resource "dnsimple_zone_record" "txt_dkim_2016_12" {
  zone_name = local.clojars_zone
  name      = "2016-12._domainkey"
  type      = "TXT"
  value     = "\"v=DKIM1; k=rsa; t=y; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDNrqUgWt07sEDQ6+xRCgrMuv+p+VJ+esWqLEGpERQwJOkUrusqftFPEi82LAdXwBK3W10+AqH4ciSlcArEyh7/kmDyHbJLclFMzy574JVTp5cD3skx1Xk1afZ77CtvSvHehzkzGwvQ995CZCeu5LRi8w4aYVxgw47TGJIWgR/jCQIDAQAB\""
  ttl       = 3600
}

resource "dnsimple_zone_record" "txt_google_verification_1" {
  zone_name = local.clojars_zone
  name      = ""
  type      = "TXT"
  value     = "\"google-site-verification=MSWyd9aXDSNxqsPw0hYm31PtA1CbyI6no5rFgWp-xU8\""
  ttl       = 3600
}

resource "dnsimple_zone_record" "txt_google_verification_2" {
  zone_name = local.clojars_zone
  name      = ""
  type      = "TXT"
  value     = "\"google-site-verification=06t-8Lwrht4Wqm7jJb_bQAGa3kosiPV5SCA4kaL_Skc\""
  ttl       = 3600
}

resource "dnsimple_zone_record" "txt_globalsign_verification" {
  zone_name = local.clojars_zone
  name      = ""
  type      = "TXT"
  value     = "\"globalsign-domain-verification=S5sT68OBACJ_9CvrzRsz8-5yhYGkz7zbctTR8vnC7B\""
  ttl       = 3600
}

resource "dnsimple_zone_record" "txt_verification_1" {
  zone_name = local.clojars_zone
  name      = ""
  type      = "TXT"
  value     = "\"r7l5p912zc3mng677pmxq93bfhg5h9jf\""
  ttl       = 3600
}

resource "dnsimple_zone_record" "txt_alias_marker" {
  zone_name = local.clojars_zone
  name      = ""
  type      = "TXT"
  value     = "\"ALIAS for production-lb-133941966.us-east-2.elb.amazonaws.com\""
  ttl       = 60
}

# === Subdomains ===

resource "dnsimple_zone_record" "beta" {
  zone_name = local.clojars_zone
  name      = "beta"
  type      = "CNAME"
  value     = "clojars.org"
  ttl       = 3600
}

resource "dnsimple_zone_record" "www" {
  zone_name = local.clojars_zone
  name      = "www"
  type      = "CNAME"
  value     = "clojars.org"
  ttl       = 3600
}

resource "dnsimple_zone_record" "releases" {
  zone_name = local.clojars_zone
  name      = "releases"
  type      = "CNAME"
  value     = "clojars.org"
  ttl       = 3600
}

resource "dnsimple_zone_record" "repo" {
  zone_name = local.clojars_zone
  name      = "repo"
  type      = "CNAME"
  # https://www.fastly.com/documentation/guides/full-site-delivery/domains-and-origins/enabling-dualstack-connections/
  value = "dualstack.v.ssl.global.fastly.net"
  # TODO: set this back to 3600 after 2026-05-21
  ttl   = 60
}

resource "dnsimple_zone_record" "status" {
  zone_name = local.clojars_zone
  name      = "status"
  type      = "CNAME"
  value     = "plmhhdckmdbg.stspg-customer.com"
  ttl       = 3600
}

resource "dnsimple_zone_record" "autodiscover" {
  zone_name = local.clojars_zone
  name      = "autodiscover"
  type      = "CNAME"
  value     = "autodiscover.mail.us-east-1.awsapps.com"
  ttl       = 3600
}

# === DKIM CNAMEs ===

resource "dnsimple_zone_record" "ses_dkim_1" {
  zone_name = local.clojars_zone
  name      = "62jozinbglmo43m6d7ocujpqn4eyj35h._domainkey"
  type      = "CNAME"
  value     = "62jozinbglmo43m6d7ocujpqn4eyj35h.dkim.amazonses.com"
  ttl       = 3600
}

resource "dnsimple_zone_record" "ses_dkim_2" {
  zone_name = local.clojars_zone
  name      = "ili6d4enpump7gnt5rj6vp4ux4z4gbs5._domainkey"
  type      = "CNAME"
  value     = "ili6d4enpump7gnt5rj6vp4ux4z4gbs5.dkim.amazonses.com"
  ttl       = 3600
}

resource "dnsimple_zone_record" "ses_dkim_3" {
  zone_name = local.clojars_zone
  name      = "vth5ke2g6owrcjdzgmwdbkmuuvvz7xy7._domainkey"
  type      = "CNAME"
  value     = "vth5ke2g6owrcjdzgmwdbkmuuvvz7xy7.dkim.amazonses.com"
  ttl       = 3600
}

resource "dnsimple_zone_record" "fastmail_dkim_1" {
  zone_name = local.clojars_zone
  name      = "fm1._domainkey"
  type      = "CNAME"
  value     = "fm1.clojars.org.dkim.fmhosted.com"
  ttl       = 3600
}

resource "dnsimple_zone_record" "fastmail_dkim_2" {
  zone_name = local.clojars_zone
  name      = "fm2._domainkey"
  type      = "CNAME"
  value     = "fm2.clojars.org.dkim.fmhosted.com"
  ttl       = 3600
}

resource "dnsimple_zone_record" "fastmail_dkim_3" {
  zone_name = local.clojars_zone
  name      = "fm3._domainkey"
  type      = "CNAME"
  value     = "fm3.clojars.org.dkim.fmhosted.com"
  ttl       = 3600
}

# === ACM / ACME validation ===

resource "dnsimple_zone_record" "acm_validation_apex" {
  zone_name = local.clojars_zone
  name      = "_8591ab357e5b4ff17f1576374fb73b44"
  type      = "CNAME"
  value     = "_da96d03de38f8758b5814a0b355a6e60.vhzmpjdqfx.acm-validations.aws"
  ttl       = 3600
}

resource "dnsimple_zone_record" "acm_validation_beta" {
  zone_name = local.clojars_zone
  name      = "_003cf66ffcf811853457cf49f2a288af.beta"
  type      = "CNAME"
  value     = "_ee133730df2b7654fd7334c723addd45.vhzmpjdqfx.acm-validations.aws"
  ttl       = 3600
}

resource "dnsimple_zone_record" "acm_validation_www" {
  zone_name = local.clojars_zone
  name      = "_c742dda811367a720a800ee6a9a8c63d.www"
  type      = "CNAME"
  value     = "_91a83539bc008cddcf55e3893d178bbc.nhqijqilxf.acm-validations.aws"
  ttl       = 3600
}

resource "dnsimple_zone_record" "acm_validation_releases" {
  zone_name = local.clojars_zone
  name      = "_ebbf677705e732757ea321a5c3c61161.releases"
  type      = "CNAME"
  value     = "_1497b68f163aef2168988a93d94b17cf.nhqijqilxf.acm-validations.aws"
  ttl       = 3600
}

resource "dnsimple_zone_record" "acm_validation_ipv6" {
  zone_name = local.clojars_zone
  name      = "_32e673b4a5acfe493ca980106433e6c7.ipv6"
  type      = "CNAME"
  value     = "_26a651b47ef242ec022b6a6faedcfaa7.nhqijqilxf.acm-validations.aws"
  ttl       = 3600
}

resource "dnsimple_zone_record" "acme_challenge_repo" {
  zone_name = local.clojars_zone
  name      = "_acme-challenge.repo"
  type      = "CNAME"
  value     = "i9g00r84wza2uk6m89.fastly-validations.com"
  ttl       = 3600
}

# === clojars.net (redirect domain) ===

resource "dnsimple_zone_record" "net_apex_alias" {
  zone_name = local.clojars_net_zone
  name      = ""
  type      = "ALIAS"
  value     = "clojars.org"
  ttl       = 3600
}

resource "dnsimple_zone_record" "net_caa_amazontrust" {
  zone_name = local.clojars_net_zone
  name      = ""
  type      = "CAA"
  value     = "0 issue \"amazontrust.com\""
  ttl       = 60
}

resource "dnsimple_zone_record" "net_txt_alias_marker" {
  zone_name = local.clojars_net_zone
  name      = ""
  type      = "TXT"
  value     = "\"ALIAS for clojars.org\""
  ttl       = 3600
}

resource "dnsimple_zone_record" "net_acm_validation_apex" {
  zone_name = local.clojars_net_zone
  name      = "_b5fd724715ee01971b191589c45cfced"
  type      = "CNAME"
  value     = "_6d0cfe59bc20b6bb38891a4d691c4792.qvwhjqbvbg.acm-validations.aws"
  ttl       = 60
}

