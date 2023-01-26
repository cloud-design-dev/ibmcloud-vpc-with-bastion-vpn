locals {
  prefix = var.project_prefix != "" ? var.project_prefix : "${random_string.prefix.0.result}-lab"
  region = var.region != "" ? var.region : random_shuffle.region.result[0]

  tags = [
    "owner:${var.owner}",
    "provider:ibm",
    "region:${local.region}"
  ]

  zones = length(data.ibm_is_zones.regional.zones)
  vpc_zones = {
    for zone in range(local.zones) : zone => {
      zone = "${local.region}-${zone + 1}"
    }
  }

  frontend_rules = [
    for r in var.frontend_rules : {
      name       = r.name
      direction  = r.direction
      remote     = lookup(r, "remote", null)
      ip_version = lookup(r, "ip_version", null)
      icmp       = lookup(r, "icmp", null)
      tcp        = lookup(r, "tcp", null)
      udp        = lookup(r, "udp", null)
    }
  ]
}