# Description: Data sources for the module

# Pull resource group
data "ibm_resource_group" "resource_group" {
  name = (var.resource_group != "" ? var.resource_group : "default")
}

# Pull in the zones in the region
data "ibm_is_zones" "regional" {
  region = local.region
}
