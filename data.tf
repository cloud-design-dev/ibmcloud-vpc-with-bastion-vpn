# Description: Data sources for the module

# # Pull resource group
# data "ibm_resource_group" "resource_group" {
#   name = (var.resource_group != "" ? var.resource_group : "default")
# }

# Pull in the zones in the region
data "ibm_is_zones" "regional" {
  region = local.region
}

data "ibm_resource_instance" "cos" {
  count = var.existing_cos_instance != "" ? 1 : 0
  name  = var.existing_cos_instance
}