locals {
  is_alias = var.type == "ALIAS"

  fqdn = var.name == "" ? var.zone.zone_name : "${var.name}.${var.zone.zone_name}"

  # MX values are stored on DNSimple with a separate priority field, but Route 53
  # (and the input list here) carries priority inside the value as "<n> <host>".
  parsed_records = local.is_alias ? {
    "0" = { value = var.alias_value, priority = null }
    } : {
    for i, r in var.records : tostring(i) => (
      var.type == "MX"
      ? {
        priority = tonumber(split(" ", r)[0])
        value    = join(" ", slice(split(" ", r), 1, length(split(" ", r))))
      }
      : { priority = null, value = r }
    )
  }

  # DNSimple stores TXT values *with* the surrounding "..." as part of the
  # value; the AWS provider expects them *without* outer quotes and adds the
  # wire-format quoting itself. Strip exactly one outer quote pair for Route
  # 53. (Only handles single-chunk TXT — multi-chunk "p1" "p2" would need a
  # different strategy, but we don't have any such records.)
  route53_records = var.type == "TXT" ? [
    for r in var.records : trimsuffix(trimprefix(r, "\""), "\"")
  ] : var.records
}

# === DNSimple ===

resource "dnsimple_zone_record" "this" {
  for_each = local.parsed_records

  zone_name = var.zone.zone_name
  name      = var.name
  type      = var.type
  value     = each.value.value
  ttl       = var.ttl
  priority  = each.value.priority

  lifecycle {
    precondition {
      condition     = var.type != "ALIAS" || (var.alias_value != null && var.route53_alias != null)
      error_message = "When type=ALIAS, both alias_value and route53_alias must be set."
    }

    precondition {
      condition     = var.type == "ALIAS" || length(var.records) > 0
      error_message = "When type is not ALIAS, records must be a non-empty list."
    }
  }
}

# === Route 53 ===

resource "aws_route53_record" "this" {
  count = local.is_alias ? 0 : 1

  zone_id = var.zone.route53_zone_id
  name    = local.fqdn
  type    = var.type
  ttl     = var.ttl
  records = local.route53_records
}

resource "aws_route53_record" "alias" {
  for_each = local.is_alias ? toset(["A", "AAAA"]) : toset([])

  zone_id = var.zone.route53_zone_id
  name    = local.fqdn
  type    = each.value

  alias {
    name                   = var.route53_alias.name
    zone_id                = var.route53_alias.zone_id
    evaluate_target_health = false
  }
}
