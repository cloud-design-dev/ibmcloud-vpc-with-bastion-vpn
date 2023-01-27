module "resource_group" {
  source                       = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  resource_group_name          = var.existing_resource_group == null ? "${local.prefix}-resource-group" : null
  existing_resource_group_name = var.existing_resource_group
}

resource "random_shuffle" "region" {
  input        = ["ca-tor", "jp-osa", "au-syd", "jp-tok"]
  result_count = 1
}

resource "random_string" "prefix" {
  count   = var.project_prefix != "" ? 0 : 1
  length  = 4
  special = false
  upper   = false
}

module "vpc" {
  source                      = "terraform-ibm-modules/vpc/ibm//modules/vpc"
  version                     = "1.1.1"
  create_vpc                  = true
  vpc_name                    = "${local.prefix}-vpc"
  resource_group_id           = module.resource_group.resource_group_id
  classic_access              = false
  default_address_prefix      = "auto"
  default_network_acl_name    = "${local.prefix}-default-network-acl"
  default_security_group_name = "${local.prefix}-default-security-group"
  default_routing_table_name  = "${local.prefix}-default-routing-table"
  vpc_tags                    = local.tags
  locations                   = [local.vpc_zones[0].zone, local.vpc_zones[1].zone, local.vpc_zones[2].zone]
  number_of_addresses         = "128"
  create_gateway              = true
  subnet_name                 = "${local.prefix}-frontend-subnet"
  public_gateway_name         = "${local.prefix}-pub-gw"
  gateway_tags                = local.tags
}


module "security_group" {
  source                = "terraform-ibm-modules/vpc/ibm//modules/security-group"
  version               = "1.1.1"
  create_security_group = true
  name                  = "${local.prefix}-frontend-sg"
  vpc_id                = module.vpc.vpc_id[0]
  resource_group_id     = module.resource_group.resource_group_id
  security_group_rules  = local.frontend_rules
}

# module "logging" {
#   source                     = "git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-instances?ref=main"
#   enable_platform_logs       = false
#   sysdig_provision           = false
#   activity_tracker_provision = false
#   region                     = local.region
#   resource_group_id          = data.ibm_resource_group.resource_group.id
#   logdna_instance_name = "${local.prefix}-logging-instance"
#   logdna_tags          = local.tags
#   logdna_plan          = "7-day"
# }

module "cos" {
  count                    = var.existing_cos_instance != "" ? 0 : 1
  depends_on               = [module.vpc]
  source                   = "git::https://github.com/terraform-ibm-modules/terraform-ibm-cos?ref=v5.3.1"
  resource_group_id        = module.resource_group.resource_group_id
  region                   = local.region
  create_hmac_key          = (var.existing_cos_instance != "" ? false : true)
  create_cos_bucket        = false
  encryption_enabled       = false
  hmac_key_name            = (var.existing_cos_instance != "" ? null : "${local.prefix}-hmac-key")
  cos_instance_name        = (var.existing_cos_instance != "" ? null : "${local.prefix}-cos-instance")
  cos_tags                 = local.tags
  existing_cos_instance_id = (var.existing_cos_instance != "" ? local.cos_instance : null)
}

resource "ibm_iam_authorization_policy" "cos_flowlogs" {
  count                       = var.existing_cos_instance != "" ? 0 : 1
  depends_on                  = [module.cos]
  source_service_name         = "is"
  source_resource_type        = "flow-log-collector"
  target_service_name         = "cloud-object-storage"
  target_resource_instance_id = local.cos_guid
  roles                       = ["Writer", "Reader"]
}

module "fowlogs_cos_bucket" {
  depends_on               = [ibm_iam_authorization_policy.cos_flowlogs]
  count                    = length(module.vpc.subnet_ids)
  source                   = "git::https://github.com/terraform-ibm-modules/terraform-ibm-cos?ref=v5.3.1"
  bucket_name              = "${local.prefix}-${substr(module.vpc.subnet_ids[count.index], 1, 6)}-bucket"
  create_cos_instance      = false
  resource_group_id        = module.resource_group.resource_group_id
  region                   = local.region
  encryption_enabled       = false
  existing_cos_instance_id = (var.existing_cos_instance != "" ? data.ibm_resource_instance.cos.0.id : module.cos.0.cos_instance_id)
}

resource "ibm_is_flow_log" "frontend" {
  count          = length(module.vpc.subnet_ids)
  depends_on     = [module.fowlogs_cos_bucket]
  name           = "${local.prefix}-${substr(module.vpc.subnet_ids[count.index], 1, 6)}-collector"
  target         = module.vpc.subnet_ids[count.index]
  active         = true
  storage_bucket = module.fowlogs_cos_bucket[count.index].bucket_name[0]
}