module "resource_group" {
  source                       = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.1.1"
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

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "ibm_is_ssh_key" "generated_key" {
  count          = var.existing_ssh_key != "" ? 0 : 1
  name           = "${local.prefix}-${local.region}-key"
  public_key     = tls_private_key.ssh.public_key_openssh
  resource_group = module.resource_group.resource_group_id
  tags           = local.tags
}

resource "null_resource" "create_private_key" {
  count = var.existing_ssh_key != "" ? 0 : 1
  provisioner "local-exec" {
    command = <<-EOT
      echo '${tls_private_key.ssh.private_key_pem}' > ./'${local.prefix}'.pem
      chmod 400 ./'${local.prefix}'.pem
    EOT
  }
}

module "vpc" {
  source                      = "terraform-ibm-modules/vpc/ibm//modules/vpc"
  version                     = "1.1.1"
  create_vpc                  = true
  vpc_name                    = "${local.prefix}-vpc"
  resource_group_id           = module.resource_group.resource_group_id
  classic_access              = var.classic_access
  default_address_prefix      = var.default_address_prefix
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

module "logging" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-instances?ref=main"
  providers = {
    logdna.at = logdna.at
    logdna.ld = logdna.ld
  }
  enable_platform_logs       = false
  sysdig_provision           = false
  activity_tracker_provision = false
  region                     = local.region
  resource_group_id          = module.resource_group.resource_group_id
  logdna_instance_name       = "${local.prefix}-logging-instance"
  logdna_tags                = local.tags
  logdna_plan                = "7-day"
}

module "cos" {
  count                    = var.existing_cos_instance != "" ? 0 : 1
  depends_on               = [module.vpc]
  source                   = "git::https://github.com/terraform-ibm-modules/terraform-ibm-cos?ref=v6.5.1"
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
  source                   = "git::https://github.com/terraform-ibm-modules/terraform-ibm-cos?ref=v7.0.4"
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

resource "ibm_is_instance" "bastion" {
  name                     = "${local.prefix}-bastion"
  vpc                      = module.vpc.vpc_id[0]
  image                    = data.ibm_is_image.base.id
  profile                  = var.instance_profile
  resource_group           = module.resource_group.resource_group_id
  metadata_service_enabled = var.metadata_service_enabled

  boot_volume {
    name = "${local.prefix}-boot-volume"
  }

  primary_network_interface {
    subnet            = module.vpc.subnet_ids[0]
    allow_ip_spoofing = var.allow_ip_spoofing
    security_groups   = [module.security_group.security_group_id[0]]
  }

  user_data = templatefile("${path.module}/init.tftpl", { logdna_ingestion_key = module.logging.logdna_ingestion_key, region = local.region, vpc_tag = "vpc:${local.prefix}-vpc" })
  zone      = local.vpc_zones[0].zone
  keys      = local.ssh_key_ids
  tags      = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}

resource "ibm_is_floating_ip" "bastion" {
  name           = "${local.prefix}-bastion-public-ip"
  resource_group = module.resource_group.resource_group_id
  target         = ibm_is_instance.bastion.primary_network_interface[0].id
  tags           = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}