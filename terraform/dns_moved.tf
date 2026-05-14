# State migration: existing dnsimple_zone_record.* resources were refactored
# into module instances of ./modules/dns-record. These moved blocks keep the
# existing DNSimple records in place rather than destroying and recreating
# them on the next apply.

# Apex
moved {
  from = dnsimple_zone_record.apex_alias
  to   = module.apex_alias.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.caa_globalsign
  to   = module.apex_caa.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.caa_amazontrust
  to   = module.apex_caa.dnsimple_zone_record.this["1"]
}

moved {
  from = dnsimple_zone_record.mx_primary
  to   = module.apex_mx.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.mx_secondary
  to   = module.apex_mx.dnsimple_zone_record.this["1"]
}

moved {
  from = dnsimple_zone_record.txt_spf
  to   = module.apex_txt.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.txt_google_verification_1
  to   = module.apex_txt.dnsimple_zone_record.this["1"]
}

moved {
  from = dnsimple_zone_record.txt_google_verification_2
  to   = module.apex_txt.dnsimple_zone_record.this["2"]
}

moved {
  from = dnsimple_zone_record.txt_globalsign_verification
  to   = module.apex_txt.dnsimple_zone_record.this["3"]
}

moved {
  from = dnsimple_zone_record.txt_verification_1
  to   = module.apex_txt.dnsimple_zone_record.this["4"]
}

# TXT subdomains
moved {
  from = dnsimple_zone_record.txt_dmarc
  to   = module.dmarc.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.txt_amazonses
  to   = module.amazonses.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.txt_dkim_2016_12
  to   = module.dkim_2016_12.dnsimple_zone_record.this["0"]
}

# CNAME subdomains
moved {
  from = dnsimple_zone_record.beta
  to   = module.beta.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.www
  to   = module.www.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.releases
  to   = module.releases.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.repo
  to   = module.repo.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.status
  to   = module.status.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.autodiscover
  to   = module.autodiscover.dnsimple_zone_record.this["0"]
}

# DKIM CNAMEs
moved {
  from = dnsimple_zone_record.ses_dkim_1
  to   = module.ses_dkim_1.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.ses_dkim_2
  to   = module.ses_dkim_2.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.ses_dkim_3
  to   = module.ses_dkim_3.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.fastmail_dkim_1
  to   = module.fastmail_dkim_1.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.fastmail_dkim_2
  to   = module.fastmail_dkim_2.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.fastmail_dkim_3
  to   = module.fastmail_dkim_3.dnsimple_zone_record.this["0"]
}

# ACM / ACME validation
moved {
  from = dnsimple_zone_record.acm_validation_apex
  to   = module.acm_validation_apex.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.acm_validation_beta
  to   = module.acm_validation_beta.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.acm_validation_www
  to   = module.acm_validation_www.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.acm_validation_releases
  to   = module.acm_validation_releases.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.acm_validation_ipv6
  to   = module.acm_validation_ipv6.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.acme_challenge_repo
  to   = module.acme_challenge_repo.dnsimple_zone_record.this["0"]
}

# clojars.net
moved {
  from = dnsimple_zone_record.net_apex_alias
  to   = module.net_apex_alias.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.net_caa_amazontrust
  to   = module.net_caa.dnsimple_zone_record.this["0"]
}

moved {
  from = dnsimple_zone_record.net_acm_validation_apex
  to   = module.net_acm_validation_apex.dnsimple_zone_record.this["0"]
}
