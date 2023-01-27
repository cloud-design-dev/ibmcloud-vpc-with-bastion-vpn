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
  resource_group_id           = data.ibm_resource_group.resource_group.id
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
  resource_group_id     = data.ibm_resource_group.resource_group.id
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

resource "ibm_resource_instance" "cos" {
  depends_on        = [module.vpc]
  name              = "${local.prefix}-cos-instance"
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
  resource_group_id = data.ibm_resource_group.resource_group.id
  tags              = local.tags
}

resource "ibm_iam_authorization_policy" "cos_flowlogs" {
  depends_on                  = [ibm_resource_instance.cos]
  source_service_name         = "is"
  source_resource_type        = "flow-log-collector"
  target_service_name         = "cloud-object-storage"
  target_resource_instance_id = ibm_resource_instance.cos.guid
  roles                       = ["Writer", "Reader"]
}

resource "ibm_cos_bucket" "frontend_flowlogs" {
  depends_on           = [ibm_iam_authorization_policy.cos_flowlogs]
  count                = length(module.vpc.subnet_ids)
  bucket_name          = "${local.prefix}-${substr(module.vpc.subnet_ids[count.index], 1, 6)}-bucket"
  resource_instance_id = ibm_resource_instance.cos.id
  region_location      = local.region
  storage_class        = "smart"
}

resource "ibm_is_flow_log" "frontend" {
  count          = length(module.vpc.subnet_ids)
  depends_on     = [ibm_cos_bucket.frontend_flowlogs]
  name           = "${local.prefix}-${substr(module.vpc.subnet_ids[count.index], 1, 6)}-collector"
  target         = module.vpc.subnet_ids[count.index]
  active         = true
  storage_bucket = ibm_cos_bucket.frontend_flowlogs[count.index].bucket_name
}