locals {
  prefix       = var.project_prefix != "" ? var.project_prefix : "${random_string.prefix.0.result}-lab"
  region       = var.region != "" ? var.region : random_shuffle.region.result[0]
  cos_instance = var.existing_cos_instance != "" ? data.ibm_resource_instance.cos.0.id : null
  cos_guid     = var.existing_cos_instance != "" ? data.ibm_resource_instance.cos.0.guid : substr(trim(trimprefix(module.cos.0.cos_instance_id, "crn:v1:bluemix:public:cloud-object-storage:global:a/"), "::"), 33, -1)
  # substr(trim(trimprefix(data.ibm_resource_instance.cos[0].id, "crn:v1:bluemix:public:cloud-object-storage:global:a/"), "::"), 32, -1)

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